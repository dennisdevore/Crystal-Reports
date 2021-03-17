create or replace package body ws_reports
as
  
  /* -----------------------------------------------------------------------------------------------
  GET_REPORT_LIST
  -------------------------------------------------------------------------------------------------*/
  function get_report_list(p_nameid in varchar2, p_custid in varchar2) return sys_refcursor
  as
    v_cursor SYS_REFCURSOR;
    v_count number;
    v_message varchar2(255);
    v_sql varchar2(5000);
	v_as ws_userheader.allreports%type;
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
	
	select nvl(allreports,'S') into v_as
	from ws_userheader where nameid = p_nameid;

	if (v_as = 'A') then
		v_sql := 'select a.objectdescr as id, a.objectname as name from applicationobjects a where a.objecttype = ''R'''; 
	else
		v_sql := 'select a.objectdescr as id, a.objectname as name from applicationobjects a, ws_user_reports u ';
		v_sql := v_sql || 'where a.objectdescr = u.report_name and a.objecttype = ' || ws_utility.qs('R');
		v_sql := v_sql || ' and u.nameid = ' || ws_utility.qs(p_nameid);
	end if;
   
    --if (p_custid is not null) then
    --  v_sql := v_sql || ' and a.custid = ' || ws_utility.qs(p_custid);
    --end if;
	
	v_sql := v_sql || ' order by a.objectname';
    
    open v_cursor for v_sql;
    return v_cursor;
	
  end get_report_list;
  
  /* -----------------------------------------------------------------------------------------------
  GET_REPORT_PARMS
  -------------------------------------------------------------------------------------------------*/
  function get_report_parms(p_nameid in varchar2, p_custid in varchar2, p_sess in varchar2, p_rpt in varchar2) 
	return sys_refcursor
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
    end if;

    v_sql := 'select parm_number as num, parm_descr as descr, parm_type as type, parm_required_optional as ro, ';
	v_sql := v_sql || 'parm_value as val ';
	v_sql := v_sql || 'from report_request_parms '; 
	v_sql := v_sql || 'where session_id = ''';
	v_sql := v_sql || p_sess || ''' and rpt_name = ''';
	v_sql := v_sql || p_rpt;
	v_sql := v_sql || ''' order by session_id, rpt_name, parm_number';
    --dbms_output.put_line(v_sql);
	
    open v_cursor for v_sql;
    return v_cursor;
	
  end get_report_parms;
  
  /* -----------------------------------------------------------------------------------------------
  SET_REPORT_PARMS
  -------------------------------------------------------------------------------------------------*/
  function set_report_parms(p_nameid in varchar2, p_custid in varchar2, p_sess in varchar2, 
	p_rpt in varchar2, p_savedata in ws_savedata_list) return number
  as
    v_message varchar2(255);
    v_savedata_row varchar2(255);
	v_cnt number;
  begin
  
    v_message := ws_security.validate_user(p_nameid);
    if (v_message <> 'OK') then
      raise_application_error(-20001, v_message);
    end if;
    
	v_cnt := 0;
    if (p_savedata is not null) then
      for elem in 1 .. p_savedata.count loop
	    v_cnt := v_cnt + 1;
        v_savedata_row := p_savedata(elem);
        update report_request_parms set parm_value = substr(v_savedata_row,instr(v_savedata_row,'|',1,2)+1)
         where session_id = p_sess and rpt_name = p_rpt and parm_number = ws_utility.get_token(v_savedata_row,'|',1);
      end loop;
    end if;
    
    return v_cnt;
    
    exception
      when others then
        raise_application_error(-20001, 'Error Updating Report Parms Table: ' + sqlerrm(sqlcode));
  end set_report_parms;
  
  /* -----------------------------------------------------------------------------------------------
  DELETE_REPORT_PARMS
  -------------------------------------------------------------------------------------------------*/
  procedure delete_report_parms(p_nameid in varchar2, p_custid in varchar2, p_sess in varchar2, 
	p_rpt in varchar2, p_message out varchar2)
  as
  begin
  
    p_message := ws_security.validate_user(p_nameid);
    if (p_message <> 'OK') then
      raise_application_error(-20001, p_message);
    end if;
    
	-- commented this SQL, to allow a user to repeat running a report without 
	-- having to reinitialize it each time.
    --delete from report_request_parms 
    --  where session_id = p_sess and rpt_name = p_rpt;
	  
	-- remove any extraneous parms more than a day old. 
	delete from report_request_parms
	  where trunc(lastupdate) <= (trunc(CURRENT_DATE) - 2);
    
    p_message := 'OKAY';
    
    exception
      when others then
        raise_application_error(-20001, 'Error Deleting From Report Parms Table: ' + sqlerrm(sqlcode));
  end delete_report_parms;
  
  /* -----------------------------------------------------------------------------------------------
  DELETE_REPORT
  -------------------------------------------------------------------------------------------------*/
  procedure delete_report(p_nameid in varchar2, p_rpt in varchar2, p_message out varchar2)
  as
  begin
  
    p_message := ws_security.validate_user(p_nameid);
    if (p_message <> 'OK') then
      raise_application_error(-20001, p_message);
    end if;
    
    delete from ws_generated_reports 
      where rptkey = p_rpt;
    
    p_message := 'OKAY';
    
    exception
      when others then
        raise_application_error(-20001, 'Error Deleting From Generated Reports Table: ' + sqlerrm(sqlcode));
  end delete_report;
  
  /* -----------------------------------------------------------------------------------------------
  SAVE_REPORT_FORMAT
  -------------------------------------------------------------------------------------------------*/
  procedure save_report_format(p_nameid in varchar2, p_custid in varchar2, 
	p_rptfmt in varchar2, p_message out varchar2)
  as
  begin
  
    p_message := ws_security.validate_user(p_nameid);
    if (p_message <> 'OK') then
      raise_application_error(-20001, p_message);
    end if;
    
    update ws_userheader set report_format = p_rptfmt 
      where nameid = p_nameid;
    
    p_message := 'OKAY';
    
    exception
      when others then
        raise_application_error(-20001, 'Error Saving Report Format: ' + sqlerrm(sqlcode));
  end save_report_format;
  
end ws_reports;
/

show error package body ws_reports;
exit;