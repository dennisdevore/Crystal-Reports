create or replace package body ws_orders
as

  /* -----------------------------------------------------------------------------------------------
  GET_ORDERS
  -------------------------------------------------------------------------------------------------*/
  function get_orders(p_nameid in varchar2, p_custid in varchar2, p_order_type in varchar2, 
	p_order_age in varchar2, p_hdrpassthru in varchar2,
    p_qualifier_list in ws_qualifier_list) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_qualifier_row varchar2(255);
    v_facility varchar2(10);
    v_sql varchar2(5000);
    v_out_message varchar2(255);
  begin

    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;

    rollback;
    if (p_qualifier_list is not null) then
      for elem in 1 .. p_qualifier_list.count loop
        v_qualifier_row := p_qualifier_list(elem);
        insert into ws_order_qualifiers (qualifier_type, qualifier_field, qualifier_comparison, qualifier_source, qualifier_value)
        values (ws_utility.get_token(v_qualifier_row,'|',1), ws_utility.get_token(v_qualifier_row,'|',2), ws_utility.get_token(v_qualifier_row,'|',3),
          ws_utility.get_token(v_qualifier_row,'|',4), ws_utility.get_token(v_qualifier_row,'|',5));
      end loop;
    end if;

    v_sql := 'with user_filter as (select /*+ materialize */ * from ws_useraccess where nameid = ' || ws_utility.qs(p_nameid) || ' and custid = ' || ws_utility.qs(p_custid) || ')
              select a.custid, a.orderid, a.shipid, a.orderid || ''-'' || a.shipid as ordershipid, a.carrier, a.po, a.priority, b.abbrev as priorityabbrev, a.shiptype, c.abbrev as shiptypeabbrev, a.reference, 
                a.fromfacility, a.tofacility, a.qtyship, a.qtyrcvd, to_char(a.statusupdate,''mm/dd/yyyy hh24:mi:ss'') as statusudpate,
                substr(zci.hazardous_item_on_order(a.orderid,a.shipid),1,1) as hazardous, a.orderstatus, d.abbrev as orderstatusabbrev,
                a.ordertype, e.abbrev as ordertypeabbrev, to_char(a.arrivaldate,''YYYY-MM-DD'') as arrivaldate, a.billoflading,
				to_char(a.shipdate, ''YYYY-MM-DD'') as shipdate, a.prono, a.qtyorder, a.qtycommit, a.qtypick, a.rma, a.requested_ship, a.cancel_after,
				decode(a.shiptoname, null, nvl(f.name,''''), nvl(a.shiptoname,'''')) as shiptoname,
				decode(a.billtoname, null, nvl(g.name,''''), nvl(a.billtoname,'''')) as billtoname, 
				a.prono, a.rma, to_char(a.statusupdate, ''YYYY-MM-DD'') as statusupdate, a.websynapse_order_status, 
				a.deliveryservice, a.weightship, a.delivery_requested, a.do_not_deliver_after, a.do_not_deliver_before, a.requested_ship,
				a.ship_no_later, a.ship_not_before, a.cancel_after, a.cancel_if_not_delivered_by, 
				decode(a.shiptoname, null, nvl(f.contact,''''), nvl(a.shiptocontact,'''')) as shiptocontact,
				decode(a.shiptoname, null, nvl(f.addr1,''''), nvl(a.shiptoaddr1,'''')) as shiptoaddr1,
				decode(a.shiptoname, null, nvl(f.addr2,''''), nvl(a.shiptoaddr2,'''')) as shiptoaddr2,
				decode(a.shiptoname, null, nvl(f.city,''''), nvl(a.shiptocity,'''')) as shiptocity,
				decode(a.shiptoname, null, nvl(f.state,''''), nvl(a.shiptostate,'''')) as shiptostate,
				decode(a.shiptoname, null, nvl(f.postalcode,''''), nvl(a.shiptopostalcode,'''')) as shiptopostalcode,
				decode(a.shiptoname, null, nvl(f.countrycode,''''), nvl(a.shiptocountrycode,'''')) as shiptocountrycode,
				decode(a.shiptoname, null, nvl(f.phone,''''), nvl(a.shiptophone,'''')) as shiptophone,
				decode(a.shiptoname, null, nvl(f.fax,''''), nvl(a.shiptofax,'''')) as shiptofax,
				decode(a.shiptoname, null, nvl(f.email,''''), nvl(a.shiptoemail,'''')) as shiptoemail,
				a.dateshipped, a.shippingcost, 
				decode(a.billtoname, null, nvl(g.name,''''), nvl(a.billtoname,'''')) as consignee, 
				ws_orders.get_order_attachment(a.orderid) as attachment';
	if p_hdrpassthru = 'Y' then
		v_sql := v_sql || get_hdr_passthru_columns('a.');
	end if;
	v_sql := v_sql || ' from orderhdr a, orderpriority b, shipmenttypes c, orderstatus d, ordertypes e, consignee f, consignee g 
              where custid = ' || ws_utility.qs(p_custid) || '
                and (exists (select 1 from user_filter where nvl(fromfacility,tofacility) = facility) or exists (select 1 from user_filter where nvl(tofacility,fromfacility) = facility))
                and a.priority = b.code(+) and a.shiptype = c.code(+) and a.orderstatus = d.code(+) and a.ordertype = e.code(+) 
				and a.shipto = f.consignee(+) and a.consignee = g.consignee(+)';
                
    if (p_order_type is not null) then
      v_sql := v_sql || ' and a.ordertype = ' || ws_utility.qs(p_order_type);
	--else
    --  v_sql := v_sql || ' and a.ordertype in (' || ws_utility.qs('R') || ',' || ws_utility.qs('O') || ')';
    end if;
    
    if (p_order_age is not null) then
      v_sql := v_sql || ' and a.entrydate >= trunc(sysdate) - ' || p_order_age;
    end if;
                
    for rec in (select * from ws_order_qualifiers where qualifier_type is not null) loop
      v_sql := v_sql || get_qualifier_string(rec);
    end loop;
	
	v_sql := v_sql || ' order by a.orderid desc,a.shipid';
    
--    zms.log_autonomous_msg('WS_ORDERS', '', p_custid, v_sql, 'I', p_nameid, v_out_message);

--    v_sql := 'with qualifiers as (select /*+ materialize */ * from ws_order_qualifiers)
--              select * from qualifiers';

    open v_cursor for v_sql;
    return v_cursor;
  end get_orders;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_ITEM_COUNT
  -------------------------------------------------------------------------------------------------*/
  function get_order_item_count(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return number
  as
    v_qty number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    select nvl(sum(qtyentered),0) into v_qty 
	  from orderdtl
     where orderid = p_orderid and shipid = p_shipid;
                
    return v_qty; 

  end get_order_item_count;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_ITEMS
  -------------------------------------------------------------------------------------------------*/
  function get_order_items(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_sql := 'select a.orderid, a.shipid, b.item, b.lotnumber, nvl(pkg_manage_orders.item_alias(b.custid,b.item),'' '') as alias, a.ordertype, 
                a.custid,  b.uom, e.abbrev as uomabbrev, c.descr as itemdescr, b.linestatus, d.abbrev as linestatusabbrev,
                nvl(b.qtyorder,0) as qtyorder, nvl(b.qtyrcvd,0) as qtyrcvd, nvl(b.qtycommit,0) as qtycommit, nvl(b.qtyship,0) as qtyship,
                nvl(b.qtyship,0) - nvl(b.qtyorder,0) as shipvariance, nvl(b.qtyrcvd,0) - nvl(b.qtyorder,0) as rcvdvariance,
                substr(zci.hazardous_item(b.custid,b.item),1,1) as hazardous, b.consigneesku,
                qtyentered, uomentered, f.abbrev as uomenteredabbrev, nvl(b.qtypick,0) as qtypick
              from orderhdr a, orderdtl b, custitem c, orderitemstatus d, unitsofmeasure e, unitsofmeasure f
              where a.orderid = b.orderid and a.shipid = b.shipid
                and b.custid = c.custid and b.item = c.item 
                and b.linestatus = d.code and b.uom = e.code(+)
                and b.uomentered = f.code(+)
                and a.orderid = ' || p_orderid || ' and a.shipid = ' || p_shipid;
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_order_items;
  
  /* -----------------------------------------------------------------------------------------------
  GET_CUSTITEMS
  -------------------------------------------------------------------------------------------------*/
  function get_custitems(p_nameid in varchar2, p_custid in varchar2, p_ordertype in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    v_sql := 'select item, descr, pkg_manage_orders.item_alias(custid,item) as alias from custitem ';
	v_sql := v_sql || 'where custid = ' || ws_utility.qs(p_custid);
	v_sql := v_sql || ' and status in (' || ws_utility.qs('ACTV') || ',' || ws_utility.qs('PEND');
	if (p_ordertype = 'O') then
		v_sql := v_sql || ',' || ws_utility.qs('INAC');
	end if;
	v_sql := v_sql || ') order by item';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_custitems;

  /* -----------------------------------------------------------------------------------------------
  GET_CUSTOMER_ITEMS
  -------------------------------------------------------------------------------------------------*/
  function get_customer_items (p_custid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
	v_ordertype orderhdr.ordertype%type;
  begin

	BEGIN
		select ordertype into v_ordertype from orderhdr 
		where orderid = p_orderid and shipid = p_shipid;
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		v_ordertype := 'R';
	END;	
    
	if (v_ordertype = 'O') then
		open v_cursor for
		select distinct item, descr, abbrev, lotrequired,
			item || ': ' || abbrev || ', BaseUOM: ' || baseuom as display,
			pkg_manage_orders.item_alias(p_custid, item) as alias, status
		--from custitem
		from custitemview
		where custid = p_custid 
		and status in ('ACTV','PEND','INAC')
		order by item;
	else
		open v_cursor for
		select distinct item, descr, abbrev, lotrequired,
			item || ': ' || abbrev || ', BaseUOM: ' || baseuom as display,
			pkg_manage_orders.item_alias(p_custid, item) as alias, status
		--from custitem
		from custitemview
		where custid = p_custid 
		and status in ('ACTV','PEND')
		order by item;
	end if;
    
    return v_cursor;
  end get_customer_items;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ITEM_LOTS
  -------------------------------------------------------------------------------------------------*/
  function get_item_lots(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    v_sql := 'select distinct lotnumber from custitemtot ';
	v_sql := v_sql || 'where custid = ''' || p_custid || ''' and facility = ''' 
		|| p_facility || ''' and item = ''' || p_item;
	v_sql := v_sql || ''' and invstatus = ''AV'' and qty > 0 and lotnumber is not null order by lotnumber';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_item_lots;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ITEM_UOMS
  -------------------------------------------------------------------------------------------------*/
  function get_item_uoms(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    v_sql := 'select distinct fromuom from custitemuom ';
	v_sql := v_sql || 'where custid = ''' || p_custid || ''' and item = ''' || p_item || '''';
	v_sql := v_sql || ' union ';
    v_sql := v_sql || 'select distinct touom as fromuom from custitemuom ';
	v_sql := v_sql || 'where custid = ''' || p_custid || ''' and item = ''' || p_item || '''';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_item_uoms;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ITEM_BASEUOM
  -------------------------------------------------------------------------------------------------*/
  function get_item_baseuom(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    v_sql := 'select baseuom from custitem ';
	v_sql := v_sql || 'where custid = ''' || p_custid || ''' and item = ''' || p_item || '''';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_item_baseuom;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_SHIP_DETAILS
  -------------------------------------------------------------------------------------------------*/
  function get_order_ship_details(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_sql := 'select item, nvl(pkg_manage_orders.item_alias(custid,item),'' '') as alias, lotnumber, serialnumber,
                useritem1, useritem2, useritem3, unitofmeasure, b.abbrev as uomabbrev, quantity as qty
              from shippingplate a, unitsofmeasure b
              where orderid = ' || p_orderid || ' and shipid = ' || p_shipid || '
                and a.unitofmeasure = b.code(+) and a.type in (''P'',''F'')
              order by item, lotnumber';
              
    open v_cursor for v_sql;
    return v_cursor; 
              
  end get_order_ship_details;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_TYPE
  -------------------------------------------------------------------------------------------------*/
  function get_order_type(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_sql := 'select ordertype from orderhdr
              where orderid = ' || p_orderid || ' and shipid = ' || p_shipid;
              
    open v_cursor for v_sql;
    return v_cursor; 
              
  end get_order_type;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_ATTACHMENTS
  -------------------------------------------------------------------------------------------------*/
  function get_order_attachments(p_nameid in varchar2, p_orderid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    open v_cursor for 
		select filepath,
			substr(filepath, decode(instr(filepath,'/', -1),0,instr(filepath,'\', -1),instr(filepath,'/', -1))+1) as filename
		from orderattach
		where orderid = p_orderid 
		order by lastupdate desc;
    return v_cursor; 

  end get_order_attachments;
  
  /* -----------------------------------------------------------------------------------------------
  CANCEL_ORDERS
  -------------------------------------------------------------------------------------------------*/
  procedure cancel_orders(p_nameid in varchar2, p_order_list in ws_cancelorder_list, p_message out varchar2)
  as 
    v_order_row varchar2(255);
    v_message varchar2(255);
    v_error_count number := 0;
    v_facility varchar2(3);
    v_cancelid number;
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_order_list is not null) then
      for elem in 1 .. p_order_list.count loop
        v_order_row := p_order_list(elem);
        insert into ws_order_list (orderid, shipid)
        values (ws_utility.get_token(v_order_row,'-',1), ws_utility.get_token(v_order_row,'-',2));
      end loop;
    else
      raise_application_error(-20001, REQUIRE_ORDERS);
    end if;
    
    p_message := 'OK';
    for rec in (select * from ws_order_list)
    loop
      v_message := ws_security.validate_order(p_nameid, rec.orderid, rec.shipid);
      if (v_message <> 'OK') then
        v_error_count := v_error_count + 1;
        if (v_error_count = 1) then
          p_message := rec.orderid || '-' || rec.shipid || ': ' || v_message || '<br>';
        else 
          p_message := p_message || rec.orderid || '-' || rec.shipid || ': ' || v_message || '<br>';
        end if;
        goto eol;
      end if;
      
      select case when ws_utility.is_order_inbound(ordertype) = 1 then tofacility else fromfacility end
      into v_facility
      from orderhdr
      where orderid = rec.orderid and shipid = rec.shipid;
      
      zoe.cancel_order(rec.orderid, rec.shipid, v_facility, 'WEB', p_nameid, v_message);
      if (v_message <> 'OKAY') then
        v_error_count := v_error_count + 1;
        if (v_error_count = 1) then
          p_message := rec.orderid || '-' || rec.shipid || ': ' || v_message || '<br>';
        else 
          p_message := p_message || rec.orderid || '-' || rec.shipid || ': ' || v_message || '<br>';
        end if;
        goto eol;
      end if;
      
      <<eol>>
      null;
    end loop;
  end cancel_orders;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_ITEMS
  -------------------------------------------------------------------------------------------------*/
  function get_order_header(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_sql := 'select a.*, b.abbrev as orderstatusabbrev, c.abbrev as ordertypeabbrev,
              to_char(arrivaldate, ''mm/dd/yyyy'') as fmtarrivaldate, to_char(shipdate, ''mm/dd/yyyy'') as fmtshipdate, to_char(apptdate, ''mm/dd/yyyy'') as fmtapptdate,
			  nvl(priority,''A'') as dfltpriority,
			  nvl(shipterms,''PPD'') as dfltshipterms,
			  nvl(d.bolcomment,'''') as bolcomment,
              to_char(hdrpassthrudate01, ''mm/dd/yyyy'') as fmthdrpassthrudate01, to_char(hdrpassthrudate02, ''mm/dd/yyyy'') as fmthdrpassthrudate02,
              to_char(hdrpassthrudate03, ''mm/dd/yyyy'') as fmthdrpassthrudate03, to_char(hdrpassthrudate04, ''mm/dd/yyyy'') as fmthdrpassthrudate04
              from orderhdr a, orderstatus b, ordertypes c, orderhdrbolcomments d
              where a.orderid = ' || p_orderid || ' and a.shipid = ' || p_shipid || '
                and a.orderstatus = b.code(+) and a.ordertype = c.code(+) and a.orderid = d.orderid(+) and a.shipid = d.shipid(+)';
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_order_header;
  
  /* -----------------------------------------------------------------------------------------------
  CREATE_INBOUND_ORDER
  -------------------------------------------------------------------------------------------------*/
  function create_inbound_order(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_savedata in ws_savedata_list) return number
  as
    v_message varchar2(255);
    v_orderid number;
    v_count number;
    v_sql varchar2(10000);
    v_column_list varchar2(4000);
    v_value_list varchar2(4000);
    v_savedata_row varchar2(4000);
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    select count(1)
    into v_count
    from custfacility
    where custid = p_custid and facility = p_facility;
    
    if (v_count = 0) then
      raise_application_error(-20001, INVALID_FACILITY);
    end if;
    
    if (p_savedata is not null) then
      for elem in 1 .. p_savedata.count loop
        v_savedata_row := p_savedata(elem);
        insert into ws_order_updates (order_field, order_type, order_value)
        values (ws_utility.get_token(v_savedata_row,'|',1), ws_utility.get_token(v_savedata_row,'|',2), substr(v_savedata_row,instr(v_savedata_row,'|',1,2)+1));
      end loop;
    end if;
    
    zoe.get_next_orderid(v_orderid, v_message);
    v_column_list := 'orderid, shipid, ordertype, orderstatus, custid, tofacility, entrydate, lastuser, lastupdate, websynapse_order_status, source';
    v_value_list := v_orderid || ',1,''R'',0,' || ws_utility.qs(p_custid) || ',' || ws_utility.qs(p_facility) || ',sysdate,' 
		|| ws_utility.qs(p_nameid) || ',sysdate,' || ws_utility.qs('INPROCESS') || ',' || ws_utility.qs('WEB');
    
    for rec in (select * from ws_order_updates where order_field not in ('facility','tofacility','fromfacility') and order_type not in ('TRANSIENT'))
    loop
      v_column_list := v_column_list || ', ' || rec.order_field;
      if (rec.order_type = 'VARCHAR') then
        v_value_list := v_value_list ||  ', ' || ws_utility.qs(rec.order_value);
      elsif (rec.order_type = 'DATE') then
        v_value_list := v_value_list || ', ' || 'to_date(' || ws_utility.qs(rec.order_value) || ',''mm/dd/yyyy'')';
      elsif (rec.order_type = 'NUMBER') then
        v_value_list := v_value_list ||   ', ' || rec.order_value;
      end if;
      
    end loop;
    
    v_sql := 'insert into orderhdr(' || v_column_list || ') values (' || v_value_list || ')';
    execute immediate v_sql;
    
    return v_orderid;
    
  end create_inbound_order;
  
  /* -----------------------------------------------------------------------------------------------
  CREATE_OUTBOUND_ORDER
  -------------------------------------------------------------------------------------------------*/
  function create_outbound_order(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_savedata in ws_savedata_list) return number
  as
    v_message varchar2(255);
    v_orderid number;
    v_count number;
    v_sql varchar2(10000);
    v_column_list varchar2(4000);
    v_value_list varchar2(4000);
    v_savedata_row varchar2(4000);
    v_shiptoonetime number;
    v_billtoonetime number;
    v_billtoshipto number;
    v_consignee number;
    v_shipto number;
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    select count(1)
    into v_count
    from custfacility
    where custid = p_custid and facility = p_facility;
    
    if (v_count = 0) then
      raise_application_error(-20001, INVALID_FACILITY);
    end if;
    
    zoe.get_next_orderid(v_orderid, v_message);
    if (p_savedata is not null) then
      for elem in 1 .. p_savedata.count loop
        v_savedata_row := p_savedata(elem);
		if (ws_utility.get_token(v_savedata_row,'|',1) = 'bolcomment') then
			insert into orderhdrbolcomments (orderid, shipid, bolcomment, lastuser, lastupdate)
			values (v_orderid, 1, substr(v_savedata_row,instr(v_savedata_row,'|',1,2)+1), p_nameid, sysdate);
		else
			insert into ws_order_updates (order_field, order_type, order_value)
			values (ws_utility.get_token(v_savedata_row,'|',1), ws_utility.get_token(v_savedata_row,'|',2), substr(v_savedata_row,instr(v_savedata_row,'|',1,2)+1));
		end if;
      end loop;
    end if;
    
    select count(1)
    into v_shiptoonetime
    from ws_order_updates
    where order_field = 'shiptoonetime' and order_type = 'TRANSIENT' and order_value = 'Y';
    
    select count(1)
    into v_billtoonetime
    from ws_order_updates
    where order_field = 'billtoonetime' and order_type = 'TRANSIENT' and order_value = 'Y';
    
    select count(1)
    into v_billtoshipto
    from ws_order_updates
    where order_field = 'billtoshipto' and order_type = 'TRANSIENT' and order_value = 'Y';
    
    if (v_shiptoonetime = 0) then
      select count(1)
      into v_shipto
      from ws_order_updates
      where order_field = 'shipto';
      
      if (v_shipto = 0) then
        v_shiptoonetime := 1;
      end if;
    end if;
    
    if (v_billtoonetime = 0 and v_billtoonetime = 0) then
      select count(1)
      into v_consignee
      from ws_order_updates
      where order_field = 'consignee';
      
      if (v_consignee = 0) then
        v_billtoonetime := 1;
      end if;
    end if;
    
    v_column_list := 'orderid, shipid, ordertype, orderstatus, custid, fromfacility, entrydate, lastuser, lastupdate, websynapse_order_status, source';
    v_value_list := v_orderid || ',1,''O'',0,' || ws_utility.qs(p_custid) || ',' || ws_utility.qs(p_facility) || ',sysdate,' 
		|| ws_utility.qs(p_nameid) || ',sysdate,' || ws_utility.qs('INPROCESS') || ',' || ws_utility.qs('WEB');
    
    for rec in (select * from ws_order_updates where order_field not in ('facility','tofacility','fromfacility') and order_type not in ('TRANSIENT'))
    loop
      if (rec.order_field != 'shipto' and rec.order_field like 'shipto%' and v_shiptoonetime = 0) then
        goto continue_loop;
      end if;
      
      if (rec.order_field like 'billto%' and v_billtoonetime = 0) then
        goto continue_loop;
      end if;
      
      v_column_list := v_column_list || ', ' || rec.order_field;
      if (rec.order_type = 'VARCHAR') then
        v_value_list := v_value_list ||  ', ' || ws_utility.qs(rec.order_value);
      elsif (rec.order_type = 'DATE') then
        v_value_list := v_value_list || ', ' || 'to_date(' || ws_utility.qs(rec.order_value) || ',''mm/dd/yyyy'')';
      elsif (rec.order_type = 'NUMBER') then
        v_value_list := v_value_list ||   ', ' || rec.order_value;
      end if;
      
    << continue_loop >>
      null;
    end loop;
    
    v_sql := 'insert into orderhdr(' || v_column_list || ') values (' || v_value_list || ')';
    execute immediate v_sql;
    
    if (v_billtoshipto > 0) then
      update orderhdr
      set billtoname = shiptoname, billtocontact = shiptocontact, billtoaddr1 = shiptoaddr1, billtoaddr2 = shiptoaddr2, billtocity = shiptocity, billtostate = shiptostate,
        billtopostalcode = shiptopostalcode, billtocountrycode = shiptocountrycode, billtophone = shiptophone, billtofax = shiptofax, billtoemail = shiptoemail
      where orderid = v_orderid;
    end if;
    
    return v_orderid;
    
  end create_outbound_order;
  
  /* -----------------------------------------------------------------------------------------------
  UPDATE_ORDER_HEADER
  -------------------------------------------------------------------------------------------------*/
  function update_order_header(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2, p_savedata in ws_savedata_list) return sys_refcursor
  as
    v_message varchar2(255);
    v_savedata_row varchar2(4000);
    v_sql varchar2(5000);
    v_cursor SYS_REFCURSOR;
    v_billtoshipto number;
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order_modifiable(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_savedata is not null) then
      for elem in 1 .. p_savedata.count loop
        v_savedata_row := p_savedata(elem);
		if (ws_utility.get_token(v_savedata_row,'|',1) = 'bolcomment') then
			delete from orderhdrbolcomments where orderid = p_orderid and shipid = p_shipid;
			insert into orderhdrbolcomments (orderid, shipid, bolcomment, lastuser, lastupdate)
			values (p_orderid, p_shipid, substr(v_savedata_row,instr(v_savedata_row,'|',1,2)+1), p_nameid, sysdate);
		else
			insert into ws_order_updates (order_field, order_type, order_value)
			values (ws_utility.get_token(v_savedata_row,'|',1), ws_utility.get_token(v_savedata_row,'|',2), substr(v_savedata_row,instr(v_savedata_row,'|',1,2)+1));
		end if;
      end loop;
    end if;
    
    v_sql := 'update orderhdr set lastuser = ' || ws_utility.qs(p_nameid) || ', lastupdate = sysdate';
    
    for rec in (select * from ws_order_updates)
    loop
      v_sql := v_sql || get_update_segment(rec);
    end loop;
    
    v_sql := v_sql || ' where orderid = ' || p_orderid || ' and shipid = ' || p_shipid;
    
    execute immediate v_sql;
    
    select count(1)
    into v_billtoshipto
    from ws_order_updates
    where order_field = 'billtoshipto' and order_type = 'TRANSIENT' and order_value = 'Y';
    
    if (v_billtoshipto > 0) then
      update orderhdr
      set billtoname = shiptoname, billtocontact = shiptocontact, billtoaddr1 = shiptoaddr1, billtoaddr2 = shiptoaddr2, billtocity = shiptocity, billtostate = shiptostate,
        billtopostalcode = shiptopostalcode, billtocountrycode = shiptocountrycode, billtophone = shiptophone, billtofax = shiptofax, billtoemail = shiptoemail
      where orderid = p_orderid and shipid = p_shipid;
    end if;
    
    return get_order_header(p_nameid, p_orderid, p_shipid);
    
    exception
      when others then
        raise_application_error(-20001, 'Error Updating Order: ' + sqlerrm(sqlcode));
  end update_order_header;
  
  /* -----------------------------------------------------------------------------------------------
  CREATE_ORDER_ITEM
  -------------------------------------------------------------------------------------------------*/
  function create_order_item(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2, 
	p_item in varchar2, p_qty in number, p_lot in varchar2, p_uom in varchar2) 
	return varchar2
  as
    v_message varchar2(255);
    v_count number;
	v_uom custitem.baseuom%type;
	v_weight orderdtl.weightorder%type;
	v_cube orderdtl.cubeorder%type;
	v_lot orderdtl.lotnumber%type;
    v_sql varchar2(10000);
	v_date date;
	v_ret varchar2(50);
	v_rowid rowid;
	
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    select count(1)
    into v_count
    from custfacility
    where custid = p_custid and facility = p_facility;
    
    if (v_count = 0) then
      raise_application_error(-20001, INVALID_FACILITY);
    end if;
    
    v_message := ws_security.validate_order_modifiable(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;

	v_date := sysdate;
	v_ret := '0';
	v_lot := p_lot;
	v_uom := nvl(p_uom,'');
	
	if (v_lot = 'null' or v_lot = '(none)') then
		v_lot := null;
	end if;
    
	if (length(v_uom) = 0) then
		select baseuom
		into v_uom
		from custitem
		where custid = p_custid and item = p_item;
	end if;
	
	v_weight := zci.item_weight(p_custid,p_item,v_uom) * p_qty;
    v_cube := zci.item_cube(p_custid,p_item,v_uom) * p_qty;
    
    v_sql := 'insert into orderdtl(orderid, shipid, custid, item, fromfacility, uom, linestatus, priority, ' 
		|| 'backorder, allowsub, qtyorder, qtyentered, itementered, uomentered, lotnumber, weightorder, cubeorder, ' 
		|| 'statususer, lastuser, statusupdate, lastupdate, qtytype, invstatus, invstatusind, invclassind, inventoryclass'
		|| ') values (' 
		|| '''' || p_orderid || ''','
		|| '''' || p_shipid || ''','
		|| '''' || p_custid || ''','
		|| '''' || p_item || ''','
		|| '''' || p_facility || ''','
		|| '''' || v_uom || ''','
		|| '''' || 'A' || ''','
		|| '''' || 'A' || ''','
		|| '''' || 'N' || ''','
		|| '''' || 'N' || ''','
		|| p_qty || ','
		|| p_qty || ','
		|| '''' || p_item || ''','
		|| '''' || v_uom || ''','
		|| '''' || v_lot || ''','
		|| v_weight || ','
		|| v_cube || ','
		|| '''' || p_nameid || ''','
		|| '''' || p_nameid || ''','
		|| '''' || v_date || ''','
		|| '''' || v_date || ''''
		|| ',' || ws_utility.qs('E')
		|| ',' || ws_utility.qs('AV')
		|| ',' || ws_utility.qs('I')
		|| ',' || ws_utility.qs('I')
		|| ',' || ws_utility.qs('RG')
		|| ') returning rowid into :1';
	BEGIN
      execute immediate v_sql returning into v_rowid;
	EXCEPTION
	  WHEN OTHERS THEN
	    v_ret := '0';
	END;
    
	v_ret := rowidtochar(v_rowid);
    return v_ret;
    
  end create_order_item;
  
  /* -----------------------------------------------------------------------------------------------
  REACTIVATE_ORDER_ITEM
  -------------------------------------------------------------------------------------------------*/
  function reactivate_order_item(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2, p_item in varchar2, p_lot in varchar2) 
	return varchar2
  as
    v_message varchar2(255);
    v_sql varchar2(10000);
	v_lot orderdtl.lotnumber%type;
	
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    v_message := ws_security.validate_order_modifiable(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;

	v_lot := p_lot;
	if (v_lot = 'null') then
		v_lot := null;
	end if;
    
    --zoe.uncancel_item(p_orderid, p_shipid, p_item, v_lot, p_facility, p_nameid, v_message);
    
    --v_sql := 'delete from orderdtl' 
    v_sql := 'update orderdtl set linestatus = ' || '''A'''
		|| ' where orderid = ' || p_orderid 
		|| ' and shipid = ' || p_shipid
		|| ' and item = ' 
		|| '''' || p_item || '''';
		
	if (v_lot is null) then
		v_sql := v_sql || ' and lotnumber is null';
	else
		v_sql := v_sql || ' and lotnumber = ' || '''' || v_lot || ''''; 
	end if;
    execute immediate v_sql;
    
	v_message := 'OKAY';
    return v_message;
    
  end reactivate_order_item;
  
  /* -----------------------------------------------------------------------------------------------
  REMOVE_ORDER_ITEM
  -------------------------------------------------------------------------------------------------*/
  function remove_order_item(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2, p_item in varchar2, p_lot in varchar2) 
	return varchar2
  as
    v_message varchar2(255);
	v_lot orderdtl.lotnumber%type;
	
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    v_message := ws_security.validate_order_modifiable(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;

	v_lot := p_lot;
	if (v_lot = 'null') then
		v_lot := null;
	end if;
    
    zoe.cancel_item(p_orderid, p_shipid, p_item, v_lot, p_facility, p_nameid, v_message);
    
    return v_message;
    
  end remove_order_item;
  
  /* -----------------------------------------------------------------------------------------------
  MARK_ORDER_COMPLETE
  -------------------------------------------------------------------------------------------------*/
  function mark_order_complete(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_orderid in varchar2, p_shipid in varchar2) 
	return varchar2
  as
    v_message varchar2(255);
	
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;

	v_message := 'OKAY';

	update orderhdr 
		set websynapse_order_status = 'DONE',
			lastuser = p_nameid,
			lastupdate = sysdate
		where orderid = p_orderid and shipid = p_shipid;
    
    return v_message;
    
  end mark_order_complete;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_WSSTATUS
  -------------------------------------------------------------------------------------------------*/
  function get_order_wsstatus(p_nameid in varchar2, p_orderid in varchar2, p_shipid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_sql := 'select nvl(websynapse_order_status, ''x'') as websynapse_order_status 
              from orderhdr
              where orderid = ' || p_orderid || ' and shipid = ' || p_shipid;
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_order_wsstatus;

  /* -----------------------------------------------------------------------------------------------
  GET_QUALIFIER_STRING
  -------------------------------------------------------------------------------------------------*/
  function get_qualifier_string(p_qualifier_row in ws_order_qualifiers%rowtype) return varchar2
  as
    v_return_string varchar2(255);
  begin
    if (p_qualifier_row.qualifier_type is null 
		or p_qualifier_row.qualifier_field is null 
		or p_qualifier_row.qualifier_comparison is null 
		or p_qualifier_row.qualifier_source is null
		or p_qualifier_row.qualifier_value is null) then
			raise_application_error(-20001, INVALID_QUALIFIER);
    end if; 
    
    if (lower(p_qualifier_row.qualifier_source) = 'header') then
      if (lower(p_qualifier_row.qualifier_type) = 'string') then
        if (lower(p_qualifier_row.qualifier_comparison) = 'eq') then
          return ' and a.' || p_qualifier_row.qualifier_field || ' = ' || ws_utility.qs(p_qualifier_row.qualifier_value);
        elsif (lower(p_qualifier_row.qualifier_comparison) = 'sw') then
          return ' and a.' || p_qualifier_row.qualifier_field || ' like ' || ws_utility.qs(p_qualifier_row.qualifier_value || '%');
        elsif (lower(p_qualifier_row.qualifier_comparison) = 'co') then
          return ' and a.' || p_qualifier_row.qualifier_field || ' like ' || ws_utility.qs('%' || p_qualifier_row.qualifier_value || '%');
        elsif (lower(p_qualifier_row.qualifier_comparison) = 'il') then
          return ' and a.' || p_qualifier_row.qualifier_field || ' in (' || p_qualifier_row.qualifier_value || ')';
        else
          raise_application_error(-20001, INVALID_STRING_COMP);
        end if;
      elsif (lower(p_qualifier_row.qualifier_type) = 'date') then
        if (lower(p_qualifier_row.qualifier_comparison) = 'eq') then
          return ' and trunc(a.' || p_qualifier_row.qualifier_field || ') = to_date(' || ws_utility.qs(p_qualifier_row.qualifier_value) || ',''mm/dd/yyyy'')';
        elsif (lower(p_qualifier_row.qualifier_comparison) = 'lt') then
          return ' and trunc(a.' || p_qualifier_row.qualifier_field || ') < to_date(' || ws_utility.qs(p_qualifier_row.qualifier_value) || ',''mm/dd/yyyy'')';
        elsif (lower(p_qualifier_row.qualifier_comparison) = 'gt') then
          return ' and trunc(a.' || p_qualifier_row.qualifier_field || ') > to_date(' || ws_utility.qs(p_qualifier_row.qualifier_value) || ',''mm/dd/yyyy'')';
        else
          raise_application_error(-20001, INVALID_DATE_COMP);
        end if;
      elsif (lower(p_qualifier_row.qualifier_type) = 'integer') then
        if (lower(p_qualifier_row.qualifier_comparison) = 'eq') then
          return ' and a.' || p_qualifier_row.qualifier_field || ' = ' || p_qualifier_row.qualifier_value;
        elsif (lower(p_qualifier_row.qualifier_comparison) = 'lt') then
          return ' and a.' || p_qualifier_row.qualifier_field || ' < ' || p_qualifier_row.qualifier_value;
        elsif (lower(p_qualifier_row.qualifier_comparison) = 'gt') then
          return ' and a.' || p_qualifier_row.qualifier_field || ' > ' || p_qualifier_row.qualifier_value;
        else
          raise_application_error(-20001, INVALID_NUMBER_COMP);
        end if;
      else
        raise_application_error(-20001, INVALID_QUALIFIER);
      end if;
    elsif (lower(p_qualifier_row.qualifier_source) = 'detail') then
		return get_detail_qualifier_string(p_qualifier_row);
    elsif (lower(p_qualifier_row.qualifier_source) = 'mod') then
		return get_modifiable_qualifier_str(p_qualifier_row);
    elsif (lower(p_qualifier_row.qualifier_source) = 'special') then
		if (lower(p_qualifier_row.qualifier_field) = 'trackingnumber') then
			if (lower(p_qualifier_row.qualifier_comparison) = 'eq') then
				return ' and (orderid,shipid) in (select orderid,shipid from shippingplate where trackingno = '
					|| ws_utility.qs(p_qualifier_row.qualifier_value) || ')';
			elsif (lower(p_qualifier_row.qualifier_comparison) = 'sw') then
				return ' and (orderid,shipid) in (select orderid,shipid from shippingplate where trackingno like '
					|| ws_utility.qs(p_qualifier_row.qualifier_value || '%') || ')';
			elsif (lower(p_qualifier_row.qualifier_comparison) = 'co') then
				return ' and (orderid,shipid) in (select orderid,shipid from shippingplate where trackingno like '
					|| ws_utility.qs('%' || p_qualifier_row.qualifier_value || '%') || ')';
			else
				raise_application_error(-20001, INVALID_STRING_COMP);
			end if;
		elsif (lower(p_qualifier_row.qualifier_field) = 'trailer') then
			if (lower(p_qualifier_row.qualifier_comparison) = 'eq') then
				return ' and loadno in (select loadno from loads where trailer = '
					|| ws_utility.qs(p_qualifier_row.qualifier_value) || ')';
			elsif (lower(p_qualifier_row.qualifier_comparison) = 'sw') then
				return ' and loadno in (select loadno from loads where trailer like '
					|| ws_utility.qs(p_qualifier_row.qualifier_value || '%') || ')';
			elsif (lower(p_qualifier_row.qualifier_comparison) = 'co') then
				return ' and loadno in (select loadno from loads where trailer like '
					|| ws_utility.qs('%' || p_qualifier_row.qualifier_value || '%') || ')';
			else
				raise_application_error(-20001, INVALID_STRING_COMP);
			end if;
		else
			raise_application_error(-20001, NOT_IMPLEMENTED_YET);
		end if;
    end if;
    
    raise_application_error(-20001, INVALID_QUALIFIER);
  end get_qualifier_string;

  /* -----------------------------------------------------------------------------------------------
  GET_DETAIL_QUALIFIER_STRING
  -------------------------------------------------------------------------------------------------*/
  function get_detail_qualifier_string(p_qualifier_row in ws_order_qualifiers%rowtype) return varchar2
  as
  begin
    if (lower(p_qualifier_row.qualifier_comparison) = 'eq') then
      return ' and  exists (select 1 from orderdtl where '
		|| p_qualifier_row.qualifier_field 
		|| ' = ' || ws_utility.qs(p_qualifier_row.qualifier_value)
		|| ' and orderid = a.orderid and shipid = a.shipid)';
    elsif (lower(p_qualifier_row.qualifier_comparison) = 'sw') then
      return ' and  exists (select 1 from orderdtl where '
		|| p_qualifier_row.qualifier_field 
		|| ' like ' || ws_utility.qs(p_qualifier_row.qualifier_value || '%')
		|| ' and orderid = a.orderid and shipid = a.shipid)';
    elsif (lower(p_qualifier_row.qualifier_comparison) = 'co') then
      return ' and  exists (select 1 from orderdtl where '
		|| p_qualifier_row.qualifier_field 
		|| ' like ' || ws_utility.qs('%' || p_qualifier_row.qualifier_value || '%')
		|| ' and orderid = a.orderid and shipid = a.shipid)';
    end if;
    
    raise_application_error(-20001, INVALID_QUALIFIER);
  end get_detail_qualifier_string;

  /* -----------------------------------------------------------------------------------------------
  GET_MODIFIABLE_QUALIFIER_STRING
  -------------------------------------------------------------------------------------------------*/
  function get_modifiable_qualifier_str(p_qualifier_row in ws_order_qualifiers%rowtype) return varchar2
  as
  begin
    --return ' and (a.orderstatus = ' || ws_utility.qs('0') || 'or a.orderstatus = ' || ws_utility.qs('1') || ')'
    return ' and a.orderstatus = ' || ws_utility.qs('0') 
		|| ' and nvl(a.websynapse_order_status,' || ws_utility.qs('x') || ') != ' || ws_utility.qs('DONE')
		|| ' and (a.ordertype = ' || ws_utility.qs('O') || ' or a.ordertype = ' || ws_utility.qs('R') || ')';
		
  end get_modifiable_qualifier_str;
  
  function get_update_segment(p_update_row in ws_order_updates%rowtype) return varchar2
  as
    v_shipto_once varchar2(1);
    v_billto_once varchar2(1) := 'Y';
    v_count number;
    v_sql varchar2(2000);
  begin
  
    if (p_update_row.order_field like 'shipto%') then
      begin
        select order_value
        into v_shipto_once
        from ws_order_updates
        where order_field = 'shiptoonetime' and order_type = 'TRANSIENT';
      exception
        when others then
          v_shipto_once := 'M';
      end;
          
      if (v_shipto_once = 'N' and p_update_row.order_field = 'shipto') then
        v_sql :=  ', ' || p_update_row.order_field || ' = ' || ws_utility.qs(p_update_row.order_value);
        v_sql := v_sql || ', shiptoname='''', shiptocontact='''', shiptoaddr1='''', shiptoaddr2='''', shiptocity='''', shiptostate='''', shiptopostalcode='''', shiptocountrycode=''''';
        v_sql := v_sql || ', shiptophone='''', shiptofax='''', shiptoemail=''''';
        return v_sql;
      elsif (v_shipto_once = 'N') then
        return '';
      end if;
    end if;
    
    if (p_update_row.order_field like 'billto%' or p_update_row.order_field = 'consignee') then
      
      select count(1)
      into v_count
      from ws_order_updates
      where order_field in ('billtoonetime','billtoshipto') and order_type = 'TRANSIENT' and order_value = 'Y';
      
      if (v_count = 0) then
        select count(1)
        into v_count
        from ws_order_updates 
        where order_field in ('billtoonetime','billtoshipto') and order_type = 'TRANSIENT' and order_value = 'N';
        
        if (v_count > 0) then
          v_billto_once := 'N';
        end if;
      end if;
          
      if (v_billto_once = 'N' and p_update_row.order_field = 'consignee') then
        v_sql :=  ', ' || p_update_row.order_field || ' = ' || ws_utility.qs(p_update_row.order_value);
        v_sql := v_sql || ', billtoname='''', billtocontact='''', billtoaddr1='''', billtoaddr2='''', billtocity='''', billtostate='''', billtopostalcode='''', billtocountrycode=''''';
        v_sql := v_sql || ', billtophone='''', billtofax='''', billtoemail=''''';
        return v_sql;
      elsif (v_shipto_once = 'N') then
        return '';
      end if;
    end if;

    
    if (p_update_row.order_type = 'VARCHAR') then
      return ', ' || p_update_row.order_field || ' = ' || ws_utility.qs(p_update_row.order_value);
    elsif (p_update_row.order_type = 'DATE') then
      return ', ' || p_update_row.order_field || ' = to_date(' || ws_utility.qs(p_update_row.order_value) || ',''mm/dd/yyyy'')';
    elsif (p_update_row.order_type = 'NUMBER') then
      return ', ' || p_update_row.order_field || ' = ' || p_update_row.order_value;
    end if;
    
    return '';
  end get_update_segment;
  
  /* -----------------------------------------------------------------------------------------------
  SAVE_QUERY_PARMS
  -------------------------------------------------------------------------------------------------*/
  function save_query_parms(p_nameid in varchar2, p_custid in varchar2, p_rqst_type in varchar2,
	p_qryid in varchar2, p_savedata in ws_savedata_list) return number
  as
    v_message varchar2(255);
    v_savedata_row varchar2(255);
	v_cnt number;
	v_col varchar2(255);
	v_type varchar2(255);
	v_op varchar2(20);
	v_value varchar2(255);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;

	delete from save_request_parms 
		where nameid = p_nameid and rqst_type = p_rqst_type and rpt_or_query_name = p_qryid;
    
	v_cnt := 0;
    if (p_savedata is not null) then
      for elem in 1 .. p_savedata.count loop
	    v_cnt := v_cnt + 1;
        v_savedata_row := p_savedata(elem);
		v_type := ws_utility.get_token(v_savedata_row,'|',1);
		v_col := ws_utility.get_token(v_savedata_row,'|',2);
		v_op := ws_utility.get_token(v_savedata_row,'|',3);
		--v_value := ws_utility.get_token(v_savedata_row,'|',5);
		v_value := substr(v_savedata_row,instr(v_savedata_row,'|',1,4)+1);
		
		insert into save_request_parms
			(nameid, rqst_type, rpt_or_query_name, parm_number, parm_descr, parm_type, 
			parm_opcode, parm_value, lastuser, lastupdate)
			values (p_nameid, p_rqst_type, p_qryid, v_cnt, v_col, v_type, v_op, v_value, p_nameid, sysdate);
      end loop;
    end if;
    
    return v_cnt;
    
    exception
      when others then
        raise_application_error(-20001, 'Error Updating Save Request Parms Table: ' + sqlerrm(sqlcode));
  end save_query_parms;
  
  /* -----------------------------------------------------------------------------------------------
  GET_QUERY_PARMS
  -------------------------------------------------------------------------------------------------*/
  function get_query_parms(p_nameid in varchar2, p_custid in varchar2, p_rqst_type in varchar2,
	p_qryid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    v_sql := 'select parm_number, parm_descr, parm_type, parm_opcode, parm_value'; 
	v_sql := v_sql || ' from save_request_parms ';
	v_sql := v_sql || ' where nameid = ' || ws_utility.qs(p_nameid);
    v_sql := v_sql || ' and rqst_type = ' || ws_utility.qs(p_rqst_type); 
    v_sql := v_sql || ' and rpt_or_query_name = ' || ws_utility.qs(p_qryid); 
    v_sql := v_sql || ' order by parm_number';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_query_parms;
  
  /* -----------------------------------------------------------------------------------------------
  DELETE_QUERY_PARMS
  -------------------------------------------------------------------------------------------------*/
  function delete_query_parms(p_nameid in varchar2, p_custid in varchar2, p_rqst_type in varchar2,
	p_qryid in varchar2) return number
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;

	delete from save_request_parms 
		where nameid = p_nameid and rqst_type = p_rqst_type and rpt_or_query_name = p_qryid;
    return 1; 

  end delete_query_parms;
  
  /* -----------------------------------------------------------------------------------------------
  GET_SAVED_QUERIES
  -------------------------------------------------------------------------------------------------*/
  function get_saved_queries(p_nameid in varchar2, p_rqst_type in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_sql := 'select distinct rpt_or_query_name from save_request_parms where nameid = ' || ws_utility.qs(p_nameid);
    v_sql := v_sql || ' and rqst_type = ' || ws_utility.qs(p_rqst_type); 
    v_sql := v_sql || ' order by rpt_or_query_name';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_saved_queries;
  
  /* -----------------------------------------------------------------------------------------------
  GET_CUSTDICT
  -------------------------------------------------------------------------------------------------*/
  function get_custdict(p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_sql varchar2(5000);
  begin
    
    v_sql := 'select fieldname, labelvalue from custdict where custid = ' || ws_utility.qs(p_custid);
    v_sql := v_sql || ' order by fieldname';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_custdict;
  
  /* -----------------------------------------------------------------------------------------------
  GET_CUSTDICT_LABEL
  -------------------------------------------------------------------------------------------------*/
  function get_custdict_label(p_custid in varchar2, p_colname in varchar2, p_dflt in varchar2) return varchar2
  as
    v_label custdict.labelvalue%type;
  begin
    
	BEGIN
		select labelvalue into v_label from custdict 
		where custid = p_custid and fieldname = p_colname;
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		v_label := p_dflt;
	END;	

    return v_label; 

  end get_custdict_label;
  
  /* -----------------------------------------------------------------------------------------------
  QUERY_SUMMARY_GET_PREFS
  -------------------------------------------------------------------------------------------------*/
  function query_summary_get_prefs(p_nameid in varchar2, p_qtype in varchar2, 
	p_otype in varchar2, p_hdrpassthru in varchar2, p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
	v_user_cnt number;
    v_message varchar2(255);
    v_sql varchar2(5000);
	v_otype varchar2(50);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;

	v_otype := nvl(p_otype, 'ALL');
	
	select count(1) into v_count from ws_user_columns 
	 where nameid = p_nameid and query_type = p_qtype and query_subtype = v_otype;

	v_sql := 'select col_db_name, ';
	v_sql := v_sql || 'ws_orders.get_custdict_label(' || ws_utility.qs(p_custid) || ', col_db_name, col_user_descr) as col_user_descr, '; 
	v_sql := v_sql || 'col_type, nvl(hide_types, 0) as hide_types, ';
	v_sql := v_sql || 'target_width, disappear_order, visible_by_default as col_visible, col_order_num ';
	v_sql := v_sql || 'from ws_columns ';
	v_sql := v_sql || 'where query_type = ' || ws_utility.qs(p_qtype);

	if p_hdrpassthru = 'N' then
		v_sql := v_sql || ' and col_db_name not like ' || ws_utility.qs('%PASSTHRU%');
	end if;

	if (v_count > 0) then
		-- all this more complicated than one would think simply to support the situation where 
		-- new columns get added, and a user has saved preferences. this code will preserve the 
		-- user's preferences, and merge in the new columns at the end.
		-- Also NOTE: ws_columns.col_user_num starts with 1, ws_user_columns.col_order_num starts with 0
		select nvl(max(u.col_order_num),0) into v_user_cnt 
		  from ws_columns a, ws_user_columns u
		 where a.col_db_name = u.col_db_name and a.query_type = u.query_type
		   and u.nameid = p_nameid and u.query_type = p_qtype and u.query_subtype = v_otype
		   and a.target_width > 0;

		v_user_cnt := v_user_cnt + 1;

		v_sql := v_sql || ' and col_order_num > ' || v_user_cnt;
		v_sql := v_sql || ' UNION ';

		v_sql := v_sql || 'select a.col_db_name, ';
		v_sql := v_sql || 'ws_orders.get_custdict_label(' || ws_utility.qs(p_custid) || ', a.col_db_name, a.col_user_descr) as col_user_descr, '; 
		v_sql := v_sql || 'a.col_type, nvl(a.hide_types, 0) as hide_types, ';
		v_sql := v_sql || 'u.col_width as target_width, a.disappear_order, u.col_visible, u.col_order_num ';
		v_sql := v_sql || 'from ws_columns a, ws_user_columns u ';
		v_sql := v_sql || 'where u.query_type = ' || ws_utility.qs(p_qtype);
		v_sql := v_sql || ' and u.query_subtype = ' || ws_utility.qs(v_otype);
		v_sql := v_sql || ' and u.nameid = ' || ws_utility.qs(p_nameid);
		v_sql := v_sql || ' and a.col_db_name = u.col_db_name and a.query_type = u.query_type';
		v_sql := v_sql || ' and u.col_order_num < ' || v_user_cnt;

		if p_hdrpassthru = 'N' then
			v_sql := v_sql || ' and u.col_db_name not like ' || ws_utility.qs('%PASSTHRU%');
		end if;
	end if;
	v_sql := v_sql || ' order by col_order_num';
                
    open v_cursor for v_sql;
    return v_cursor; 

  end query_summary_get_prefs;
  
  /* -----------------------------------------------------------------------------------------------
  QUERY_SUMMARY_SAVE_PREFS
  -------------------------------------------------------------------------------------------------*/
  function query_summary_save_prefs(p_nameid in varchar2, p_custid in varchar2, 
	p_qtype in varchar2, p_otype in varchar2, p_collist in ws_savedata_list) 
	return varchar2
  as
    v_message varchar2(255);
    v_sql varchar2(10000);
	v_cnt number;
	v_pos number;
	v_width number;
	v_col ws_user_columns.col_db_name%type;
	v_visible ws_user_columns.col_visible%type;
    v_savedata_row varchar2(255);
	v_otype varchar2(50);
	
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;

	v_otype := nvl(p_otype, 'ALL');

	delete from ws_user_columns 
		where nameid = p_nameid and query_type = p_qtype and query_subtype = v_otype;

	v_cnt := 0;
    if (p_collist is not null) then
      for elem in 1 .. p_collist.count loop
	    v_cnt := v_cnt + 1;
        v_savedata_row := p_collist(elem);
		v_col := ws_utility.get_token(v_savedata_row,'|',1);
		v_pos := to_number(ws_utility.get_token(v_savedata_row,'|',2));
		v_visible := ws_utility.get_token(v_savedata_row,'|',3);
		v_width := to_number(ws_utility.get_token(v_savedata_row,'|',4));
		
		insert into ws_user_columns
			(nameid, query_type, query_subtype, col_order_num, col_db_name, col_visible, col_width, lastuser, lastupdate)
			values (p_nameid, p_qtype, v_otype, v_pos, v_col, v_visible, v_width, p_nameid, sysdate);
      end loop;
    end if;
    
	v_message := 'OKAY';
    return v_message;
    
  end query_summary_save_prefs;
  
  /* -----------------------------------------------------------------------------------------------
  QUERY_SUMMARY_RESET_PREFS
  -------------------------------------------------------------------------------------------------*/
  function query_summary_reset_prefs(p_nameid in varchar2, p_custid in varchar2, 
	p_qtype in varchar2, p_otype in varchar2) 
	return varchar2
  as
    v_message varchar2(255);
	v_otype varchar2(50);
	
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;

	v_otype := nvl(p_otype, 'ALL');

	delete from ws_user_columns 
		where nameid = p_nameid and query_type = p_qtype and query_subtype = v_otype;
    
	v_message := 'OKAY';
    return v_message;
    
  end query_summary_reset_prefs;

  /* -----------------------------------------------------------------------------------------------
  GET_HDR_PASSTHRU_COLUMNS
  -------------------------------------------------------------------------------------------------*/
  function get_hdr_passthru_columns(p_tabid in varchar2) return varchar2
  as
    v_sql varchar2(5000);
  begin
	v_sql := '';
	for cc in (select column_name from user_tab_columns
					where table_name = 'ORDERHDR'
					  and column_name like '%PASSTHRU%'
					order by column_name)
		loop
			v_sql := v_sql || ', ' || p_tabid || cc.column_name;
		end loop;

    return v_sql;
		
  end get_hdr_passthru_columns;

  /* -----------------------------------------------------------------------------------------------
  GET_ORDER_ATTACHMENT
  -------------------------------------------------------------------------------------------------*/
  function get_order_attachment(p_orderid in number) return varchar2
  as
    v_flnm varchar2(1000);
  begin
	v_flnm := '';
	for oa in (select filepath from orderattach
					where orderid = p_orderid
					order by lastupdate desc)
		loop
			v_flnm := oa.filepath;
			exit;
		end loop;

    return v_flnm;
		
  end get_order_attachment;
  
  /* -----------------------------------------------------------------------------------------------
  CHECK_ORDER_DUPLICATE
  -------------------------------------------------------------------------------------------------*/
  function check_order_duplicate(p_custid in varchar2, p_ref in varchar2, p_po in varchar2,
		p_orderid in varchar2, p_shipid in varchar2) return varchar2
  as
    v_yn varchar2(10);
	v_ref varchar2(10);
	v_cnt number;
  begin
    v_cnt := 0;
	v_yn := 'N';
    
	BEGIN
		select nvl(dup_reference_ynw,'N') into v_ref from customer 
		where custid = p_custid;
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		v_ref := 'N';
	END;

	if (v_ref = 'Y') then
		return v_yn;
	end if;

	if (v_ref = 'H') then
		return v_yn;
	end if;

	for xx in (select reference, orderid from orderhdr
					where nvl(reference,'') = nvl(p_ref,''))
		loop
			if (length(xx.reference) > 0 and to_char(xx.orderid) != nvl(p_orderid,'x')) then
				v_cnt := v_cnt + 1;
				exit;
			end if;
		end loop;

	if (v_cnt > 0) then
		if (v_ref = 'N') then
			v_yn := 'Y';
		else
			v_yn := 'W';
		end if;
	end if;

    return v_yn; 

  end check_order_duplicate;
  
  /* -----------------------------------------------------------------------------------------------
  set_massitem_settings
  -------------------------------------------------------------------------------------------------*/
  procedure set_massitem_settings(p_nameid in varchar2, 
	p_include_status in varchar2, p_include_class in varchar2, p_display_ic in varchar2, p_message out varchar2)
  as 
    v_message varchar2(255);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    p_message := 'OK';

	BEGIN
		update ws_user_settings set
			include_status = p_include_status,
			include_class = p_include_class,
			display_ic = p_display_ic,
			lastupdate = sysdate
		where nameid = p_nameid;
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		insert into ws_user_settings (nameid, include_status, include_class, display_ic, lastupdate)
			values (p_nameid, p_include_status, p_include_class, p_display_ic, sysdate);
	END;
  end set_massitem_settings;
  
  /* -----------------------------------------------------------------------------------------------
  get_massitem_settings
  -------------------------------------------------------------------------------------------------*/
  procedure get_massitem_settings(p_nameid in varchar2, 
	p_include_status out varchar2, p_include_class out varchar2, p_display_ic out varchar2, 
	p_allow_gt_allocable out varchar2, p_rlse_orders out varchar2, p_message out varchar2)
  as 
    v_message varchar2(255);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    p_message := 'OK';

	BEGIN
		select include_status, include_class, display_ic 
		  into p_include_status, p_include_class, p_display_ic
		  from ws_user_settings 
		 where nameid = p_nameid;
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		p_include_status := 'Y';
		p_include_class := 'Y'; 
		p_display_ic := 'Y';
	END;

	BEGIN
		select defaultvalue 
		  into p_allow_gt_allocable
		  from systemdefaults 
		 where defaultid = 'WEBSYNAPSEALLOWENTRYGTALLOCABLE';
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		p_allow_gt_allocable := 'Y';
	END;

	BEGIN
		select defaultvalue 
		  into p_rlse_orders
		  from systemdefaults 
		 where defaultid = 'WEBSYNAPSEREMOVEFROMHOLD';
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		p_rlse_orders := 'N';
	END;
  end get_massitem_settings;
  
  /* -----------------------------------------------------------------------------------------------
  GET_ALLOCABLE_ITEMS
  -------------------------------------------------------------------------------------------------*/
  function get_allocable_items(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, 
	p_invstatus in varchar2, p_invclass in varchar2, p_display_ic in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;

	if (p_invstatus = 'Y' and p_invclass = 'Y') then
		v_sql := 'select ci.item, ci.descr, ci.baseuom, ci.lotrequired, citot.lotnumber, citot.uom, 
			citot.inventoryclass, ic.descr as invclassdescr, citot.invstatus, ist.descr as invstatusdescr, 
			citot.qty as allocable, 0 as qty,
			ws_orders.get_item_uoms(' || ws_utility.qs(p_nameid) || ',citot.custid,citot.facility,ci.item) as uoms
			from custitemtot citot, custitemview ci, inventoryclass ic, inventorystatus ist
			where citot.custid = ci.custid and citot.item = ci.item
			and ci.invstatus like ''%'' || citot.invstatus || ''%''
			and ci.inventoryclass like ''%'' || citot.inventoryclass || ''%''
			and citot.inventoryclass = ic.code(+)
			and citot.invstatus = ist.code(+)
			and citot.custid = ' || ws_utility.qs(p_custid) || ' and citot.facility = ' || ws_utility.qs(p_facility) || '
			and ci.status in (''ACTV'',''PEND'') 
			and citot.status = ''A'' and citot.qty > 0
			order by 1,5,9,7'; 
	elsif (p_invstatus = 'N' and p_invclass = 'Y') then
		v_sql := 'select x.*, ws_orders.get_item_uoms(' || ws_utility.qs(p_nameid) || 
			',' || ws_utility.qs(p_custid) || ',' || ws_utility.qs(p_facility) || ',x.item) as uoms 
			from (select ci.item, ci.descr, ci.baseuom, ci.lotrequired, citot.lotnumber, citot.uom, 
			citot.inventoryclass, ic.descr as invclassdescr, 
			sum(citot.qty) as allocable, sum(0) as qty
			from custitemtot citot, custitemview ci, inventoryclass ic
			where citot.custid = ci.custid and citot.item = ci.item
			and ci.invstatus like ''%'' || citot.invstatus || ''%''
			and ci.inventoryclass like ''%'' || citot.inventoryclass || ''%''
			and citot.inventoryclass = ic.code(+)
			and citot.custid = ' || ws_utility.qs(p_custid) || ' and citot.facility = ' || ws_utility.qs(p_facility) || '
			and ci.status in (''ACTV'',''PEND'') 
			and citot.status = ''A'' and citot.qty > 0
			group by ci.item, ci.descr, ci.baseuom, ci.lotrequired, citot.lotnumber, citot.uom, citot.inventoryclass, ic.descr) x 
			order by 1,5,7'; 
	elsif (p_invstatus = 'Y' and p_invclass = 'N') then
		v_sql := 'select x.*, ws_orders.get_item_uoms(' || ws_utility.qs(p_nameid) || 
			',' || ws_utility.qs(p_custid) || ',' || ws_utility.qs(p_facility) || ',x.item) as uoms 
			from (select ci.item, ci.descr, ci.baseuom, ci.lotrequired, citot.lotnumber, citot.uom, 
			citot.invstatus, ist.descr as invstatusdescr, 
			sum(citot.qty) as allocable, sum(0) as qty
			from custitemtot citot, custitemview ci, inventorystatus ist
			where citot.custid = ci.custid and citot.item = ci.item
			and ci.invstatus like ''%'' || citot.invstatus || ''%''
			and ci.inventoryclass like ''%'' || citot.inventoryclass || ''%''
			and citot.invstatus = ist.code(+)
			and citot.custid = ' || ws_utility.qs(p_custid) || ' and citot.facility = ' || ws_utility.qs(p_facility) || '
			and ci.status in (''ACTV'',''PEND'') 
			and citot.status = ''A'' and citot.qty > 0
			group by ci.item, ci.descr, ci.baseuom, ci.lotrequired, citot.lotnumber, citot.uom, citot.invstatus, ist.descr) x 
			order by 1,5,7'; 
	else 
		v_sql := 'select x.*, ws_orders.get_item_uoms(' || ws_utility.qs(p_nameid) || 
			',' || ws_utility.qs(p_custid) || ',' || ws_utility.qs(p_facility) || ',x.item) as uoms 
		    from (select ci.item, ci.descr, ci.baseuom, ci.lotrequired, citot.lotnumber, citot.uom, 
			sum(citot.qty) as allocable, sum(0) as qty
			from custitemtot citot, custitemview ci
			where citot.custid = ci.custid and citot.item = ci.item
			and ci.invstatus like ''%'' || citot.invstatus || ''%''
			and ci.inventoryclass like ''%'' || citot.inventoryclass || ''%''
			and citot.custid = ' || ws_utility.qs(p_custid) || ' and citot.facility = ' || ws_utility.qs(p_facility) || '
			and ci.status in (''ACTV'',''PEND'') 
			and citot.status = ''A'' and citot.qty > 0
			group by ci.item, ci.descr, ci.baseuom, ci.lotrequired, citot.lotnumber, citot.uom) x 
			order by 1,5'; 
	end if;
                
    open v_cursor for v_sql;
    return v_cursor; 

  end get_allocable_items;
  
  /* -----------------------------------------------------------------------------------------------
  ADD_ORDER_ITEMS
  -------------------------------------------------------------------------------------------------*/
  function add_order_items(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2,
		p_orderid in varchar2, p_shipid in varchar2, p_savedata in ws_savedata_list) return number
  as
    v_message varchar2(255);
    v_cnt number;
    v_savedata_row varchar2(4000);
	v_item orderdtl.item%type;
	v_lot orderdtl.lotnumber%type;
	v_uom orderdtl.uom%type;
	v_qty orderdtl.qtyorder%type;
	v_invstatus orderdtl.invstatus%type;
	v_inventoryclass orderdtl.inventoryclass%type;
	v_ordertype orderhdr.ordertype%type;
	v_lotrequired varchar2(10);
	v_instr varchar2(1000);
	v_bol varchar2(1000);
	v_rowidx varchar2(50);
	v_rowid rowid;
  begin
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else 
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    if (p_custid is not null) then 
      v_message := ws_security.validate_customer(p_nameid, p_custid);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_CUSTOMER);
    end if;
    
    v_message := ws_security.validate_order(p_nameid, p_orderid, p_shipid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;

	BEGIN
	select ordertype into v_ordertype
	  from orderhdr
	 where orderid = p_orderid and shipid = p_shipid;
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		v_ordertype := 'O';
	END;

	delete from orderdtl where orderid = p_orderid and shipid = p_shipid;
	delete from orderdtlbolcomments where orderid = p_orderid and shipid = p_shipid;
    
    if (p_savedata is not null) then
      for elem in 1 .. p_savedata.count loop
        v_savedata_row := p_savedata(elem);

		v_item := ws_utility.get_token(v_savedata_row,'|',1);
		v_qty := to_number(ws_utility.get_token(v_savedata_row,'|',2));
		v_uom := ws_utility.get_token(v_savedata_row,'|',3);
		v_lot := ws_utility.get_token(v_savedata_row,'|',7);
		v_lotrequired := ws_utility.get_token(v_savedata_row,'|',6);
		if (v_ordertype = 'R') then
			if (v_lotrequired != 'Y' and v_lotrequired != 'O' and v_lotrequired != 'S') then
				v_lot := '';
			end if;
		else
			if (v_lotrequired != 'O' and v_lotrequired != 'S') then
				v_lot := '';
			end if;
		end if;
		if (v_lot = '(none)') then
			v_lot := '';
		end if;

		v_rowidx := ws_orders.create_order_item(p_nameid, p_custid, p_facility, p_orderid, p_shipid, 
			v_item, v_qty, v_lot, v_uom); 
		v_rowid := chartorowid(v_rowidx);

		--update invstatus, inventoryclass, instructions, etc
		v_invstatus := ws_utility.get_token(v_savedata_row,'|',4);
		v_inventoryclass := ws_utility.get_token(v_savedata_row,'|',5);
		v_instr := ws_utility.get_token(v_savedata_row,'|',8);
		v_bol := ws_utility.get_token(v_savedata_row,'|',9);
		if (v_instr = '(none)') then
			v_instr := '';
		end if;
		if (v_bol = '(none)') then
			v_bol := '';
		end if;

		if (v_invstatus != 'AV' and length(v_invstatus) > 0) then
			update orderdtl set invstatus = v_invstatus where rowid = v_rowid;
		end if;
		if (v_inventoryclass != 'RG' and length(v_inventoryclass) > 0) then
			update orderdtl set inventoryclass = v_inventoryclass where rowid = v_rowid;
		end if;
		if (length(v_instr) > 0) then
			update orderdtl set comment1 = v_instr where rowid = v_rowid;
		end if;
		if (length(v_bol) > 0) then
			insert into orderdtlbolcomments (orderid, shipid, item, lotnumber, bolcomment, lastuser, lastupdate)
				values (p_orderid, p_shipid, v_item, v_lot, v_bol, p_nameid, sysdate);
		end if;

		v_cnt := v_cnt + 1;
      end loop;
    end if;
    
    return v_cnt;
    
  end add_order_items;

PROCEDURE compute_arrivaldate
(in_facility varchar2
,in_shipto varchar2
,in_shipdate varchar2
,out_arrivaldate IN OUT varchar2
,out_msg IN OUT varchar2
) is

v_arrdate date;

begin

zms.compute_arrivaldate(in_facility, in_shipto, in_shipdate, v_arrdate, out_msg);
out_arrivaldate := to_char(v_arrdate, 'YYYY-MM-DD');

end compute_arrivaldate;

PROCEDURE compute_shipdate
(in_facility varchar2
,in_shipto varchar2
,in_arrivaldate varchar2
,out_shipdate OUT varchar2
,out_msg OUT varchar2
) is

v_shipdate date;

begin

zms.compute_shipdate(in_facility, in_shipto, in_arrivaldate, v_shipdate, out_msg);
out_shipdate := to_char(v_shipdate, 'YYYY-MM-DD');

end compute_shipdate;

end ws_orders;
/

show error package body ws_orders;
exit;