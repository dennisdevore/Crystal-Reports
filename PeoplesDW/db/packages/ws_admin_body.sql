create or replace package body ws_admin
as

  /* -----------------------------------------------------------------------------------------------
  GET_USER_LIST
  -------------------------------------------------------------------------------------------------*/
  function get_user_list (p_nameid in varchar2, p_custid in varchar2) return sys_refcursor
  is
    v_allcusts varchar2(1);
    v_cursor SYS_REFCURSOR;
  begin
    
    begin
      select nvl(allcusts,'X')
      into v_allcusts
      from ws_userheader
      where upper(nameid) = upper(p_nameid) and userstatus = 'A';
    exception
      when others then
        v_allcusts := 'X';
    end;

    open v_cursor for
    select a.nameid, a.username, a.groupid, a.facility, a.userstatus, a.allcusts, a.chgfacility, 
		a.title, a.addr1, a.addr2, a.city, a.state, a.postalcode, a.countrycode, a.phone, a.fax, a.email,
      cursor(select facility, groupid from ws_userfacility where nameid = a.nameid) as facilities,
      cursor(select custid from ws_usercustomer where nameid = a.nameid) as customers,
      cursor(select formid, facility, setting from ws_userdetail where nameid = a.nameid) as settings
    from ws_userheader a
    where a.usertype = 'U' 
	  and (p_custid in (select custid from ws_usercustomer where nameid = a.nameid) 
	   or  p_custid = a.custid
       or  v_allcusts = 'A')
	  and (a.groupid = 'WEBGRP' or (a.groupid = 'SUPER' and p_nameid <> a.nameid))
    order by a.nameid;
    
    return v_cursor;
  end get_user_list;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_NAMEID
  -------------------------------------------------------------------------------------------------*/
  function validate_nameid (p_nameid in varchar2, p_update_user in varchar2 default null) return varchar2
  as
    v_count number;
  begin
  
    if (p_nameid is null) then
      return REQUIRE_NAMEID;
    end if;
  
    select count(1)
    into v_count
    from ws_userheader
    where nameid = p_nameid;
    
    if (v_count = 0) then
      return INVALID_NAMEID;
    end if;
    
    if (p_update_user is not null) then
      -- todo: make sure the update user has access to this customer
      null;
    end if;
    
    return 'OK';
  end validate_nameid;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_CUSTOMER_FLAG
  -------------------------------------------------------------------------------------------------*/
  function validate_customer_flag (p_customer_flag in varchar2) return varchar2
  as
    v_count number;
  begin
  
    if (p_customer_flag is null) then
      return REQUIRE_CUST_FLAG;
    end if;
    
    if (p_customer_flag not in ('A','S')) then
      return INVALID_CUST_FLAG;
    end if;
    
    return 'OK';
  end validate_customer_flag;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_FACILITY_FLAG
  -------------------------------------------------------------------------------------------------*/
  function validate_facility_flag (p_facility_flag in varchar2) return varchar2
  as
    v_count number;
  begin
  
    if (p_facility_flag is null) then
      return REQUIRE_FACILITY_FLAG;
    end if;
    
    if (p_facility_flag not in ('A','N','S')) then
      return INVALID_FACILITY_FLAG;
    end if;
    
    return 'OK';
  end validate_facility_flag;
  
  /* -----------------------------------------------------------------------------------------------
  RESET_PASSWORD
  -------------------------------------------------------------------------------------------------*/
  procedure reset_password (p_nameid in varchar2, p_password in varchar2)
  as
    v_message varchar2(255);
  begin
    
    v_message := validate_nameid(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
  
    update ws_userheader
    set blendedpword = zus.blenderize_user(p_nameid, p_password)
    where nameid = p_nameid;
    
  end reset_password;
  
  /* -----------------------------------------------------------------------------------------------
  UPDATE_USER_BASIC_INFO
  -------------------------------------------------------------------------------------------------*/
  procedure update_user_basic_info(p_nameid in varchar2, p_username in varchar2, 
	p_groupid in varchar2, p_facility in varchar2, p_userstatus in varchar2, 
	p_ws_reports in varchar2, p_ws_report_admin in varchar2,
	p_ws_admin in varchar2, p_ws_inv_inq in varchar2,
	p_ws_ord_inq in varchar2, p_ws_ord_add in varchar2,
	p_ws_ord_can in varchar2, p_ws_ord_mod in varchar2,
	p_update_user in varchar2, p_custid in varchar2, p_pswd in varchar2)
  as
    v_count number;
    v_message varchar2(255);
  begin
    
    update ws_userheader
    set username = nvl(p_username, username),
      groupid = nvl(p_groupid, groupid),
      facility = nvl(p_facility, facility),
      userstatus = nvl(p_userstatus, userstatus),
      lastuser = p_update_user,
      lastupdate = sysdate
    where nameid = p_nameid;
	if sql%rowcount = 0 then 
		insert into ws_userheader (nameid, username, groupid, facility, userstatus, custid, 
				blendedpword, lastuser, lastupdate, usertype)
			values (p_nameid, p_username, p_groupid, p_facility, p_userstatus, p_custid, 
				zus.blenderize_user(p_nameid, p_pswd), p_update_user, sysdate, 'U');
	end if;

	delete from ws_userdetail where nameid = p_nameid and formid like 'WS%';
	
	if (p_ws_reports = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSREPORTS', 'DISPLAY', p_update_user, sysdate);
	end if;
	if (p_ws_report_admin = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSREPORTADMIN', 'DISPLAY', p_update_user, sysdate);
	end if;
	if (p_ws_admin = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSADMIN', 'DISPLAY', p_update_user, sysdate);
	end if;
	if (p_ws_inv_inq = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSINVINQUIRE', 'DISPLAY', p_update_user, sysdate);
	end if;
	if (p_ws_ord_inq = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSORDINQUIRE', 'DISPLAY', p_update_user, sysdate);
	end if;
	if (p_ws_ord_add = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSORDCREATE', 'DISPLAY', p_update_user, sysdate);
	end if;
	if (p_ws_ord_can = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSORDCANCEL', 'DISPLAY', p_update_user, sysdate);
	end if;
	if (p_ws_ord_mod = 'Y') then
		insert into ws_userdetail (nameid, formid, setting, lastuser, lastupdate)
			values (p_nameid, 'WSORDMODIFY', 'DISPLAY', p_update_user, sysdate);
	end if;
    
  end update_user_basic_info;
  
  /* -----------------------------------------------------------------------------------------------
  GET_USER_BASIC_INFO
  -------------------------------------------------------------------------------------------------*/
  function get_user_basic_info(p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
    
    open v_cursor for
    select nameid, username, groupid, facility, userstatus
    from ws_userheader
    where nameid = p_nameid;
    
    return v_cursor;
    
  end get_user_basic_info;
  
  /* -----------------------------------------------------------------------------------------------
  GET_USER_ACCESS_INFO
  -------------------------------------------------------------------------------------------------*/
  function get_user_access_info(p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
  
    open v_cursor for
    select formid
    from ws_userdetail
    where nameid = p_nameid;
    
    return v_cursor;
    
  end get_user_access_info;
  
  /* -----------------------------------------------------------------------------------------------
  UPDATE_USER_CONTACT_INFO
  -------------------------------------------------------------------------------------------------*/
  procedure update_user_contact_info (p_nameid in varchar2, p_title in varchar2, p_street_1 in varchar2, p_street_2 in varchar2, p_city in varchar2, p_state in varchar2,
    p_postal_code in varchar2, p_country in varchar2, p_phone in varchar2, p_fax in varchar2, p_email in varchar2, p_update_user in varchar2)
  as
    v_message varchar2(255);
  begin
  
    v_message := validate_nameid(p_nameid, p_update_user);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    update ws_userheader
    set title = upper(p_title), 
        addr1 = upper(p_street_1), 
        addr2 = upper(p_street_2), 
        city = upper(p_city), 
        state = upper(p_state), 
        postalcode = upper(p_postal_code), 
        countrycode = p_country, 
        phone = p_phone, 
        fax = p_fax, 
        email = p_email,
        lastuser = p_update_user,
        lastupdate = sysdate
	where nameid = p_nameid;
      
  end update_user_contact_info;
  
  /* -----------------------------------------------------------------------------------------------
  GET_USER_CONTACT_INFO
  -------------------------------------------------------------------------------------------------*/
  function get_user_contact_info (p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
  
    v_message := validate_nameid(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    open v_cursor for
    select nameid, title, addr1, addr2, city, state, postalcode, countrycode, phone, fax, email
    from ws_userheader
    where nameid = p_nameid;
    
    return v_cursor;
    
  end get_user_contact_info;
  
  /* -----------------------------------------------------------------------------------------------
  UPDATE_USER_CUSTOMERS
  -------------------------------------------------------------------------------------------------*/
  procedure update_user_customers (p_nameid in varchar2, p_customer_flag in varchar2, p_customers in ws_customer_list, p_update_user in varchar2)
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
  
    v_message := validate_nameid(p_nameid, p_update_user);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := validate_customer_flag(p_customer_flag);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    update ws_userheader
    set allcusts = p_customer_flag,
        lastuser = p_update_user,
        lastupdate = sysdate
    where nameid = p_nameid;
    
    delete from ws_usercustomer
    where nameid = p_nameid;
    
    if (p_customer_flag = 'S') then
      for elem in 1 .. p_customers.count loop
        insert into ws_usercustomer(nameid, custid, lastuser, lastupdate)
        values (p_nameid, p_customers(elem), p_update_user, sysdate);
      end loop;
    end if;
    
  end update_user_customers;
  
  /* -----------------------------------------------------------------------------------------------
  GET_USER_CUSTOMERS
  -------------------------------------------------------------------------------------------------*/
  function get_user_customers (p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
  
    v_message := validate_nameid(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    open v_cursor for
    select nameid, allcusts,
      cursor(select custid from ws_usercustomer where nameid = a.nameid) as customers
    from ws_userheader a
    where nameid = p_nameid;
    
    return v_cursor;
    
  end get_user_customers;
  
    /* -----------------------------------------------------------------------------------------------
  UPDATE_USER_FACILITIES
  -------------------------------------------------------------------------------------------------*/
  procedure update_user_facilities (p_nameid in varchar2, p_facility_flag in varchar2, p_facilities in ws_facility_list, p_update_user in varchar2)
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
    v_groupid varchar2(30);
  begin
  
    v_message := validate_nameid(p_nameid, p_update_user);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    v_message := validate_facility_flag(p_facility_flag);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    update ws_userheader
    set chgfacility = p_facility_flag,
        lastuser = p_update_user,
        lastupdate = sysdate
    where nameid = p_nameid;
    
    delete from ws_userfacility
    where nameid = p_nameid;
    
    if (p_facility_flag = 'S') then
      select groupid
      into v_groupid
      from ws_userheader
      where nameid = p_nameid;
      
      for elem in 1 .. p_facilities.count loop
        insert into ws_userfacility(nameid, facility, groupid, lastuser, lastupdate)
        values (p_nameid, p_facilities(elem), v_groupid, p_update_user, sysdate);
      end loop;
    end if;
    
  end update_user_facilities;
  
  /* -----------------------------------------------------------------------------------------------
  GET_USER_FACILITIES
  -------------------------------------------------------------------------------------------------*/
  function get_user_facilities (p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
  
    v_message := validate_nameid(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    open v_cursor for
    select nameid, chgfacility,
      cursor(select facility, groupid from ws_userfacility where nameid = a.nameid) as facilities
    from ws_userheader a
    where nameid = p_nameid;
    
    return v_cursor;
    
  end get_user_facilities;
  
  /* -----------------------------------------------------------------------------------------------
  UPDATE_USER_REPORTS
  -------------------------------------------------------------------------------------------------*/
  procedure update_user_reports (p_nameid in varchar2, p_reports_flag in varchar2, p_reports in ws_report_list, p_update_user in varchar2)
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
  
    v_message := validate_nameid(p_nameid, p_update_user);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    update ws_userheader
    set allreports = p_reports_flag,
        lastuser = p_update_user,
        lastupdate = sysdate
    where nameid = p_nameid;
    
    delete from ws_user_reports
    where nameid = p_nameid;
    
    if (p_reports_flag = 'S') then
      for elem in 1 .. p_reports.count loop
        insert into ws_user_reports(nameid, report_name, lastuser, lastupdate)
        values (p_nameid, p_reports(elem), p_update_user, sysdate);
      end loop;
    end if;
    
  end update_user_reports;
  
  /* -----------------------------------------------------------------------------------------------
  GET_USER_REPORTS
  -------------------------------------------------------------------------------------------------*/
  function get_user_reports (p_nameid in varchar2, p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
  
    v_message := validate_nameid(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    open v_cursor for
    select nameid, nvl(allreports,'S') as allreports,
      cursor(select report_name as key, report_name as value from ws_user_reports where nameid = a.nameid) as reports
    from ws_userheader a
	where (p_custid in (select custid from ws_usercustomer where nameid = a.nameid) 
	   or  p_custid = a.custid);
    
    return v_cursor;
    
  end get_user_reports;

  /* -----------------------------------------------------------------------------------------------
  CHECK_USER_EXISTS
  -------------------------------------------------------------------------------------------------*/
  function check_user_exists (p_nameid in varchar2, p_newuser in varchar2) return sys_refcursor
  is
    v_cursor SYS_REFCURSOR;
    v_message varchar2(255);
  begin
    v_message := validate_nameid(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
    open v_cursor for
		select 'Y' as usrexists 
		from ws_userheader
		where nameid = p_newuser; 
    return v_cursor;
  end check_user_exists;
  
end ws_admin;
/

show error package body ws_admin;
exit;