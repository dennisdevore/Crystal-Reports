create or replace package body ws_inventory
as

  /* -----------------------------------------------------------------------------------------------
  GET_CUSTOMER_PRODUCT_GROUPS
  -------------------------------------------------------------------------------------------------*/
  function get_customer_product_groups (p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    
    open v_cursor for
    select distinct productgroup, descr, abbrev
    from custproductgroup
    where custid = p_custid
    order by productgroup;
    
    return v_cursor;
  end get_customer_product_groups;

  /* -----------------------------------------------------------------------------------------------
  GET_CUSTOMER_ITEMS
  -------------------------------------------------------------------------------------------------*/
  function get_customer_items (p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    
    open v_cursor for
    select distinct item, descr, abbrev, item || ': ' || abbrev || ', BaseUOM: ' || baseuom as display,
      pkg_manage_orders.item_alias(p_custid, item) as alias
    from custitem
    where custid = p_custid and status = 'ACTV'
    order by item;
    
    return v_cursor;
  end get_customer_items;
  
  /* -----------------------------------------------------------------------------------------------
  GET_INVENTORY
  -------------------------------------------------------------------------------------------------*/
  function get_inventory(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_product_group in varchar2, p_item_exp in varchar2,
    p_item_string in varchar2, p_specific_item in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_facility varchar2(10);
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
    end if;
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    end if;

    v_sql := 'with user_filter as (select /*+ materialize */ * from ws_useraccess where nameid = ' || ws_utility.qs(p_nameid) || ')
              select a.custid, e.baseuom, a.item, nvl(pkg_manage_orders.item_alias(a.custid,a.item),'' '') alias, 
				a.descr, c.abbrev as productgroup, a.facility, 
                a.cnttotal, a.qtytotal, a.qtyalloc, zci.item_qty_backorder(a.facility, a.custid, a.item) qtybackorder            
              from custitemsummary a, customer b, custproductgroup c, user_filter d, custitem e 
              where a.custid = b.custid and a.custid = c.custid(+) and a.productgroup = c.productgroup(+)
			    and a.custid = e.custid and a.item = e.item
                and a.custid = d.custid and a.facility = d.facility and a.qtytotal > 0';
   
    if (p_custid is not null) then
      v_sql := v_sql || ' and a.custid = ' || ws_utility.qs(p_custid);
    end if;
    
    if (p_facility is not null) then
      v_sql := v_sql || ' and a.facility = ' || ws_utility.qs(p_facility);
    end if;
    
    if (p_product_group is not null) then
      v_sql := v_sql || ' and a.productgroup = ' || ws_utility.qs(p_product_group);
    end if;
    
    if (upper(p_item_exp) = 'EQ') then
      v_sql := v_sql || ' and a.item = ' || ws_utility.qs(p_specific_item);
    elsif (upper(p_item_exp) = 'SW') then
      v_sql := v_sql || ' and a.item like ' || ws_utility.qs(p_item_string || '%');
    elsif (upper(p_item_exp) = 'CO') then
      v_sql := v_sql || ' and a.item like ' || ws_utility.qs('%' || p_item_string || '%');
    end if;
	
	v_sql := v_sql || ' order by item';
    
    open v_cursor for v_sql;
    return v_cursor;
  end get_inventory;
  
  /* -----------------------------------------------------------------------------------------------
  GET_INVENTORY_DETAIL
  -------------------------------------------------------------------------------------------------*/
  function get_inventory_detail(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2) return sys_refcursor
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
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    if (p_item is null) then
      raise_application_error(-20001, REQUIRE_ITEM);
    end if;
    
    v_sql := 'select item, custid, facility, lotnumber, uom, qty as quantity, status, statusabbrev, invstatus, invstatusabbrev, inventoryclass, inventoryclassabbrev, hazardous            
              from custitemtotview 
              where custid = ' || ws_utility.qs(p_custid) || ' and item = ' || ws_utility.qs(p_item) || ' and facility = ' || ws_utility.qs(p_facility);
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_inventory_detail;
  
  /* -----------------------------------------------------------------------------------------------
  GET_COMMITTED_DETAIL
  -------------------------------------------------------------------------------------------------*/
  function get_committed_detail(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2, p_lot in varchar2,
    p_invstatus in varchar2, p_invclass in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_facility varchar2(10);
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
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    if (p_item is null) then
      raise_application_error(-20001, REQUIRE_ITEM);
    end if;
    if (p_invstatus is null) then
      raise_application_error(-20001, REQUIRE_INV_STATUS);
    end if;
    if (p_invclass is null) then
      raise_application_error(-20001, REQUIRE_INV_CLASS);
    end if;
    
    v_sql := 'select od.fromfacility, oh.orderid, oh.shipid, oh.reference, oh.po, oh.name shiptoname, od.uom, sum(nvl(od.qtyorder,0)) qtyorder, sum(nvl(cm.commitqty,0)) qtycommit, 
                sum(nvl(od.qtypick,0) - nvl(od.qtyship,0)) qtypick
              from orderhdrshiptoview oh, orderdtl od, 
               (select orderid, shipid, orderitem, orderlot, sum(qty) as commitqty
                from commitments
                where facility = ' || ws_utility.qs(p_facility) || ' and custid = ' || ws_utility.qs(p_custid) || '
                  and item = ' || ws_utility.qs(p_item) || ' and nvl(lotnumber,''(none)'') = nvl(' || ws_utility.qs(p_lot) || ',''(none)'')
                  and invstatus = ' || ws_utility.qs(p_invstatus) || ' and inventoryclass = ' || ws_utility.qs(p_invclass) || '
                group by orderid, shipid, orderitem, orderlot) cm
              where oh.orderid = od.orderid and oh.shipid = od.shipid
                and oh.orderid = cm.orderid and oh.shipid = cm.shipid
                and od.item = cm.orderitem and nvl(od.lotnumber,''(none)'') = nvl(cm.orderlot,''(none)'')
              group by od.fromfacility, oh.orderid, oh.shipid, oh.reference, oh.po, oh.name, od.uom
              order by od.fromfacility, oh.orderid, oh.shipid';
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_committed_detail;
  
  /* -----------------------------------------------------------------------------------------------
  GET_PICKNOTSHIP_DETAIL
  -------------------------------------------------------------------------------------------------*/
  function get_picknotship_detail(p_nameid in varchar2, p_custid in varchar2, p_facility in varchar2, p_item in varchar2, p_lot in varchar2,
    p_invstatus in varchar2, p_invclass in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_facility varchar2(10);
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
    
    if (p_facility is not null) then
      v_message := ws_security.validate_facility(p_nameid, p_facility);
      if (v_message <> 'OK') then
        raise_application_error(-20001, v_message);
      end if; 
    else
      raise_application_error(-20001, REQUIRE_FACILITY);
    end if;
    
    if (p_item is null) then
      raise_application_error(-20001, REQUIRE_ITEM);
    end if;
    if (p_invstatus is null) then
      raise_application_error(-20001, REQUIRE_INV_STATUS);
    end if;
    if (p_invclass is null) then
      raise_application_error(-20001, REQUIRE_INV_CLASS);
    end if;
    
    v_sql := 'select od.fromfacility, oh.orderid, oh.shipid, oh.reference, oh.po, oh.name shiptoname, od.uom, sum(nvl(od.qtyorder,0)) qtyorder, sum(nvl(od.qtycommit,0)) qtycommit, 
                sum(nvl(sp.quantity,0)) qtypick
              from orderhdrshiptoview oh, orderdtl od,
                (select orderid, shipid, orderitem, orderlot, sum(quantity) as quantity
                 from shippingplate
                 where facility = ' || ws_utility.qs(p_facility) || ' and custid = ' || ws_utility.qs(p_custid) || '
                  and item = ' || ws_utility.qs(p_item) || ' and nvl(lotnumber,''(none)'') = nvl(' || ws_utility.qs(p_lot) || ',''(none)'')
                  and invstatus = ' || ws_utility.qs(p_invstatus) || ' and inventoryclass = ' || ws_utility.qs(p_invclass) || '
                  and status in (''P'',''S'',''L'',''FA'') and type in (''F'',''P'')
                 group by orderid, shipid, orderitem, orderlot) sp
              where oh.orderid = od.orderid and oh.shipid = od.shipid
                and oh.orderid = sp.orderid and oh.shipid = sp.shipid
                and od.item = sp.orderitem and nvl(od.lotnumber,''(none)'') = nvl(sp.orderlot,''(none)'')
              group by od.fromfacility, oh.orderid, oh.shipid, oh.reference, oh.po, oh.name, od.uom
              order by od.fromfacility, oh.orderid, oh.shipid';
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_picknotship_detail;
  
end ws_inventory;
/

show error package body ws_inventory;
exit;