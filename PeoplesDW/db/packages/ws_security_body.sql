create or replace package body ws_security
as

  /* -----------------------------------------------------------------------------------------------
  GET_USER_CUSTOMERS
  -------------------------------------------------------------------------------------------------*/
  function get_user_customers (p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_allcusts varchar2(1);
  begin
    
    begin
      select nvl(allcusts,'X')
      into v_allcusts
      from ws_userheader
      where upper(nameid) = upper(p_nameid) and userstatus = 'A';
    exception
      when others then
        raise_application_error(-20001,INVALID_USER);
    end;
    
    if (v_allcusts = 'A') then
      open v_cursor for
      select distinct custid, name
      from customer
      where status = 'ACTV' and custid <> 'DEFAULT'
      order by custid;
      
      return v_cursor;
    end if;
    
    open v_cursor for
    select distinct b.custid, b.name
    from ws_usercustomer a, customer b
    where a.custid = b.custid
      and upper(a.nameid) = upper(p_nameid) and b.status = 'ACTV';
      
    return v_cursor;
  end get_user_customers;
  
  /* -----------------------------------------------------------------------------------------------
  GET_USER_FACILITIES
  -------------------------------------------------------------------------------------------------*/
  function get_user_facilities (p_nameid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_chgfacility varchar2(1);
  begin
     
    begin
      select nvl(chgfacility,'A')
      into v_chgfacility
      from ws_userheader
      where upper(nameid) = upper(p_nameid) and userstatus = 'A';
    exception
      when others then
        raise_application_error(-20001,INVALID_USER);
    end;
    
    if  (v_chgfacility = 'A') then
      open v_cursor for
      select distinct facility, name
      from facility
      where facilitystatus = 'A'
      order by facility;
      
      return v_cursor;
    end if;
    
    open v_cursor for
    select distinct c.facility, c.name
    from ws_userheader a, ws_userfacility b, facility c
    where a.nameid = b.nameid and (a.facility = c.facility or b.facility = c.facility)
      and upper(a.nameid) = upper(p_nameid) and c.facilitystatus = 'A' order by 1;
      
    return v_cursor;
    
  end get_user_facilities;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_USER
  -------------------------------------------------------------------------------------------------*/
  function validate_user(p_nameid in varchar2) return varchar2
  as
    v_count number;
  begin
    begin
      select count(1)
      into v_count
      from ws_userheader
      where nameid = p_nameid and userstatus = 'A';
    exception
      when others then
        v_count := 0;
    end;
    
    if (v_count = 0) then
      return INVALID_USER;
    end if;
    
    return 'OK';
    
  end validate_user;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_CUSTOMER
  -------------------------------------------------------------------------------------------------*/
  function validate_customer (p_nameid in varchar2, p_custid in varchar2) return varchar2
  as
    v_allcusts varchar2(1);
    v_count number;
  begin
    
    begin
      select nvl(allcusts,'N')
      into v_allcusts
      from ws_userheader
      where nameid = p_nameid and userstatus = 'A';
    exception
      when others then
        return NA_CUSTOMER;
    end;
    
    select count(1)
    into v_count
    from customer
    where custid = p_custid and status = 'ACTV';
    
    if (v_count = 0) then
      return INVALID_CUSTOMER;
    end if;
    
    if (v_allcusts = 'A') then
      return 'OK';
    end if;
    
    select count(1)
    into v_count
    from ws_usercustomer
    where nameid = p_nameid and custid = p_custid;
    
    if (v_count = 0) then
      return NA_CUSTOMER;
    end if;
    
    return 'OK';
  end validate_customer;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_FACILITY
  -------------------------------------------------------------------------------------------------*/
  function validate_facility (p_nameid in varchar2, p_facility in varchar2) return varchar2
  as
    v_chgfacility varchar2(1);
    v_facility varchar2(20);
    v_count number;
  begin
  
    begin
      select facility, nvl(chgfacility,'N')
      into v_facility, v_chgfacility
      from ws_userheader 
      where nameid = p_nameid and userstatus = 'A';
    exception
      when others then
        return NA_FACILITY;
    end;
    
    select count(1)
    into v_count
    from facility
    where facility = p_facility and facilitystatus = 'A';
    
    if (v_count = 0) then
      return INVALID_FACILITY;
    end if;
    
    if (v_chgfacility = 'A' or p_facility = v_facility) then
      return 'OK';
    end if;
    
    if (v_chgfacility <> 'S') then
      return NA_FACILITY;
    end if;
    
    select count(1)
    into v_count
    from ws_userfacility
    where nameid = p_nameid and facility = p_facility;
    
    if (v_count = 0) then
      return NA_FACILITY;
    end if;
    
    return 'OK';
    
  end validate_facility;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_ORDER
  -------------------------------------------------------------------------------------------------*/
  function validate_order (p_nameid in varchar2, p_orderid in number, p_shipid in number) return varchar2
  as
    v_message varchar2(255);
    v_fromfacility varchar2(3);
    v_tofacility varchar2(3);
    v_custid varchar2(10);
  begin 
  
    begin
      select custid, nvl(fromfacility,'---'), nvl(tofacility,'---')
      into v_custid, v_fromfacility, v_tofacility
      from orderhdr
      where orderid = p_orderid and shipid = p_shipid;
    exception
      when others then
        return INVALID_ORDER;
    end;
    
    v_message := validate_customer(p_nameid, v_custid);
    if (v_message <> 'OK') then
      return v_message;
    end if; 
    
    v_message := validate_facility(p_nameid, v_fromfacility);
    if (v_message <> 'OK') then
      v_message := validate_facility(p_nameid, v_tofacility);
      if (v_message <> 'OK') then
        return v_message;
      end if;
    end if;
    
    return 'OK';
    
  end validate_order;
  
  /* -----------------------------------------------------------------------------------------------
  VALIDATE_ORDER_MODIFIABLE
  -------------------------------------------------------------------------------------------------*/
  function validate_order_modifiable (p_nameid in varchar2, p_orderid in number, p_shipid in number) return varchar2
  as
    v_message varchar2(255);
    v_orderstatus orderhdr.orderstatus%type;
  begin 
  
    begin
      select orderstatus
      into v_orderstatus
      from orderhdr
      where orderid = p_orderid and shipid = p_shipid;
    exception
      when others then
        return INVALID_ORDER;
    end;

	--if (v_orderstatus <> '0' and v_orderstatus <> '1') then
	if (v_orderstatus <> '0') then
		return NONMODIFIABLE_ORDER;
	end if;
    
    return 'OK';
    
  end validate_order_modifiable;

  
  /* -----------------------------------------------------------------------------------------------
  KILL_WS_USER
  -------------------------------------------------------------------------------------------------*/
  procedure kill_ws_user
		(in_userid    in varchar2,
		out_error    out number,
		out_message  out varchar2) is

	cursor curUH(in_userid varchar2) is
		select nameid, ws_session_id
			from ws_userheader
			where nameid = in_userid;
	uh curUH%rowtype;
    v_message varchar2(255);
	v_cnt number;

	begin

	out_error := 0;
	out_message := 'OKAY';
	uh := null;
	v_cnt := -1;

	open curUH(upper(in_userid));
	fetch curUH into uh;
	close curUH;

	if uh.nameid is null then
		out_error := -1;
		out_message := 'Invalid user: ' || in_userid;
		return;
	end if;

	begin
	select count(1)
      into v_cnt
    from ws_user_history
    where nameid = upper(in_userid)
     and event_time > sysdate - 2/1440;
	exception when others then
		v_cnt := -1;
	end;

	if v_cnt > 0 then
		out_error := -4;
		out_message :=  in_userid || ' has recent actvity.';
		return;
    end if;

    zms.log_autonomous_msg('WSUTIL',  null, null,
                           'WebSynapse kill for ' || in_userid,
                           'I', in_userid, v_message);

	logout_ws_user(in_userid, out_error, out_message);
  end kill_ws_user;

  
  /* -----------------------------------------------------------------------------------------------
  LOGOUT_WS_USER
  -------------------------------------------------------------------------------------------------*/
  procedure logout_ws_user
		(in_userid    in varchar2,
		out_error    out number,
		out_message  out varchar2) is
  begin
	out_error := 0;
	out_message := 'OKAY';
	update ws_userheader
		set ws_session_id = null
	where nameid = upper(in_userid);
  end logout_ws_user;

  
  /* -----------------------------------------------------------------------------------------------
  LOG_USER_ACTIVITY
  -------------------------------------------------------------------------------------------------*/
  procedure log_user_activity
   (in_userid    in varchar2,
    in_custid    in varchar2,
    in_facility  in varchar2,
    in_pgm       in varchar2,
    in_opcode    in varchar2,
    in_parms     in varchar2,
    in_ipaddr    in varchar2,
    in_session   in varchar2,
    out_message  out varchar2) is

	v_logyn systemdefaults.defaultvalue%type;

  begin
	out_message := 'OKAY';

	begin
	select nvl(defaultvalue, 'N') 
	  into v_logyn
	  from systemdefaults
      where defaultid = 'WEBSYNAPSELOGUSERACTIVITY';
    exception
      when others then
        v_logyn := 'N';
    end;

	if v_logyn != 'Y' then
		return;
	end if;

	insert into ws_user_history (nameid, event_time, custid, facility, pgm, opcode, parms, ipaddr, sessionid)
		values (in_userid, sysdate, in_custid, in_facility, in_pgm, in_opcode, in_parms, in_ipaddr, in_session);
	commit;
  end log_user_activity;

end ws_security;
/

show errors package body ws_security;
exit;