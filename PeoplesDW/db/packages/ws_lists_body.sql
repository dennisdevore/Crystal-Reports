create or replace package body ws_lists
as

  function get_initial_data return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
      select get_ordertype_list as ordertype,
             get_orderpriority_list as orderpriority,
             get_state_list as state,
             get_country_list as country,
             get_shipmenttype_list as shipmenttype,
             get_shipmentterms_list as shipmentterms,
             get_carriers as carriers,
             get_orderstatus_list as orderstatus
      from dual;
      
    return v_cursor;
           
  end get_initial_data;
  
  function get_customer_lists(p_nameid in varchar2, p_custid in varchar2) return sys_refcursor
    as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
      select get_custuserfacility_list(p_nameid, p_custid) as custuserfacility,
             get_custshipto_list(p_custid) as custshipto,
             get_custbillto_list(p_custid) as custbillto,
             get_custshipper_list(p_custid) as custshipper,
             get_custlotrequired_dflt(p_custid) as custlotdflt,
             ws_orders.get_custdict(p_custid) as custdict
      from dual;
      
    return v_cursor;
           
  end get_customer_lists;

  function get_facility_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select facility as key, facility as value
    from facility;
    
    return v_cursor;
  end get_facility_list;
  
  function get_usergroup_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select distinct nameid as key, nvl(username, nameid) as value
    from ws_userheader
    where usertype = 'G'
	  and nameid in ('SUPER','WEBGRP');
    
    return v_cursor;
  end get_usergroup_list;
  
  function get_userstatus_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select code as key, abbrev as value
    from userstatus;
    
    return v_cursor;
  end get_userstatus_list;
  
  function get_state_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select code as key, descr as value
    from stateorprovince
    order by case when code in ('AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME',
      'MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','PR','RI','SC','SD','TN','TX','UT',
      'VT','VI','VA','WA','WV','WI','WY') then 1 else 2 end, descr;
    
    return v_cursor;
  end get_state_list;
  
  function get_country_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select code as key, descr as value
    from countrycodes
    order by case when code = 'USA' then 1 else 2 end, descr;
    
    return v_cursor;
  end get_country_list;
  
  function get_customer_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select custid as key, name as value
    from customer
    where status = 'ACTV'
    order by custid;
    
    return v_cursor;
  end get_customer_list;
  
  function get_ordertype_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select code as key, descr as value
    from ordertypes
	where code in ('R','O')
    order by decode(code,'O',1,'R',2,10), descr;
    
    return v_cursor;
  end get_ordertype_list;
  
  function get_orderstatus_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select code as key, abbrev as value
    from orderstatus
    order by code;
    
    return v_cursor;
  end get_orderstatus_list;
  
  function get_orderpriority_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
    open v_cursor for
    select code as key, abbrev as value
    from orderpriority
    order by abbrev;
    
    return v_cursor;
  end get_orderpriority_list;
  
  function get_custuserfacility_list(p_nameid in varchar2, p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
    v_sql varchar2(1000);
	v_all varchar2(10);
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := ws_security.validate_customer(p_nameid, p_custid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;

	begin
	select nvl(chgfacility,'A') into v_all
	  from ws_userheader
	 where nameid = p_nameid;
	EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		v_all := 'A';
	end;
    
	if (v_all <> 'A') then
		v_sql := 'select uf.facility as key, f.name as value from facility f, ws_userfacility uf';
		v_sql := v_sql || '	where f.facility = uf.facility and uf.nameid = ' || ws_utility.qs(p_nameid);
	else
		v_sql := 'select facility as key, name as value from facility';
	end if;
	v_sql := v_sql || ' order by 1';
              
    open v_cursor for v_sql;
    return v_cursor;
  end get_custuserfacility_list;
  
  function get_shipmenttype_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select code as key, descr as value
    from shipmenttypes
    order by code;
    
    return v_cursor;
  end get_shipmenttype_list;

  function get_shipmentterms_list return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select code as key, descr as value
    from shipmentterms
    order by code;
    
    return v_cursor;
  end get_shipmentterms_list;
  
  function get_deliveryservice_list(p_carrier in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select servicecode as key, descr as value
    from carrierservicecodes
    where carrier = p_carrier
    order by servicecode;
    
    return v_cursor;
    
  end get_deliveryservice_list;
  
  function get_carriers return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select carrier, name, carriertype, multiship, get_deliveryservice_list(carrier) as delivery_service
    from carrier
    where carrierstatus = 'A'
    order by carrier;
    
    return v_cursor;
    
  end get_carriers;
  
  function get_custshipto_list(p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_sql varchar2(1000);
  begin

    v_sql := 'select b.consignee as key, b.name as value
              from custconsignee a, consignee b
              where a.consignee = b.consignee and b.consigneestatus = ''A''
                and a.custid = ' || ws_utility.qs(p_custid) || '
                and nvl(b.shipto,''N'') = ''Y''
              order by b.name';
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_custshipto_list;
  
  function get_custbillto_list(p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_sql varchar2(1000);
  begin
  
    v_sql := 'select b.consignee as key, b.name as value
              from custconsignee a, consignee b
              where a.consignee = b.consignee and b.consigneestatus = ''A''
                and a.custid = ' || ws_utility.qs(p_custid) || '
                and nvl(b.billto,''N'') = ''Y''
              order by b.name';
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_custbillto_list;
  
  function get_custshipper_list(p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_sql varchar2(1000);
  begin
  
    v_sql := 'select b.shipper as key, b.name as value
              from custshipper a, shipper b
              where a.shipper = b.shipper and b.shipperstatus = ''A''
                and a.custid = ' || ws_utility.qs(p_custid) || '
              order by b.name';
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_custshipper_list;
  
  function get_custlotrequired_dflt(p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_sql varchar2(1000);
  begin
  
    v_sql := 'select nvl(lotrequired,''N'') as key, lotrequired as value
              from customer
              where custid = ' || ws_utility.qs(p_custid);
              
    open v_cursor for v_sql;
    return v_cursor;
    
  end get_custlotrequired_dflt;

  function get_report_path return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, defaultvalue as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSERPTPATH';
    
    return v_cursor;
  end get_report_path;

  function get_report_format(p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select nvl(report_format,'PDF') as key, nvl(report_format,'PDF') as value
    from ws_userheader
    where nameid = p_nameid;
    
    return v_cursor;
  end get_report_format;
  
  function get_reports return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select objectdescr as key, objectname as value
    from applicationobjects
    where objecttype = 'R'
    order by objectname;
    
    return v_cursor;
    
  end get_reports;

  function get_help_url return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, defaultvalue as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSEHELPURL';
    
    return v_cursor;
  end get_help_url;

  function get_help_urlx(p_ip in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, 
		'http://' || p_ip || '/websynapse-help-html-links.html' as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSEHELPURL';
    
    return v_cursor;
  end get_help_urlx;

  function get_page_size return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, defaultvalue as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSEPAGESIZE';
    
    return v_cursor;
  end get_page_size;

  function get_timeout return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, defaultvalue as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSETIMEOUTMINS';
    
    return v_cursor;
  end get_timeout;

  function get_massentry_allowed return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, defaultvalue as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSEMASSENTRYALLOWED';
    
    return v_cursor;
  end get_massentry_allowed;

  function get_report_dest return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, defaultvalue as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSERPTDESTSRVR';
    
    return v_cursor;
  end get_report_dest;

  function get_report_url return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
  begin
  
    open v_cursor for
    select defaultid as key, defaultvalue as value
    from systemdefaults
    where defaultid = 'WEBSYNAPSERPTDESTWEB';
    
    return v_cursor;
  end get_report_url;

end ws_lists;
/

show error package body ws_lists;
exit;