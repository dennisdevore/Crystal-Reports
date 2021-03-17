set serveroutput on size 1000000

declare
  v_start_time date;
  v_rows_deleted number;
  

  /* DISPLAY TIME */
  procedure display_time(v_heading varchar2, v_rows_deleted number, v_start_time date)
  as
    v_hours number;
    v_minutes number;
    v_seconds number;
  begin
    v_hours := floor((sysdate - v_start_time)*24);
    v_minutes := floor((((sysdate - v_start_time)*24) - v_hours)*60);
    v_seconds := floor((((sysdate - v_start_time)*24*60) - v_minutes) * 60);
    dbms_output.put_line(v_heading || ' (' || v_rows_deleted || ' row(s) deleted): ' || v_hours || ':' || lpad(v_minutes,2,'0') || ':' || lpad(v_seconds,2,'0'));
  end;
  
  
  /* ALTER TRIGGERS */
  procedure alter_triggers(v_enable varchar2)
  as
  begin
    for rec in (select 'alter trigger ' || table_owner || '.' || trigger_name || ' ' || v_enable as ddl_statement
                from user_triggers
                where table_owner = 'ALPS')
    loop
      execute immediate rec.ddl_statement;
    end loop;
  end;
  
  
  /* FILTER ORDERHDR */
  procedure filter_orderhdr
  as
  begin
    v_start_time := sysdate;
  
    delete from orderhdr
    where fromfacility not in (select facility from facility)
      or tofacility not in (select facility from facility);
      
    v_rows_deleted := sql%rowcount;
    commit;
    display_time('orderhdr', v_rows_deleted, v_start_time);
  end;
  
  
  /* FILTER TABLES BY ORDERID AND OPTIONALLY SHIPID */
  procedure filter_table_by_orderhdr(v_table_name varchar2, v_no_shipid boolean default false)
  as
    v_sql varchar2(2000);
  begin
  
    if (not v_no_shipid) then
      v_sql := 'delete from ' || v_table_name || ' a
                where not exists (select 1 from orderhdr where orderid = a.orderid and shipid = a.shipid)';
    else
      v_sql := 'delete from ' || v_table_name || ' a
                where not exists (select 1 from orderhdr where orderid = a.orderid)';
    end if;
              
    v_start_time := sysdate;
    begin
      execute immediate v_sql;
      v_rows_deleted := sql%rowcount;
    exception
      when others then
        dbms_output.put_line('could not filter ' || v_table_name || ': ' || sqlerrm(sqlcode));
        v_rows_deleted := 0;
    end;
    commit;
    display_time(v_table_name, v_rows_deleted, v_start_time);
  end;


  /* FILTER TABLES BY LOADNO */
  procedure filter_table_by_load(v_table_name varchar2)
  as
    v_sql varchar2(2000);
  begin

    v_sql := 'delete from ' || v_table_name || ' a
              where not exists (select 1 from loads where loadno = a.loadno)';
              
    v_start_time := sysdate;
    begin
      execute immediate v_sql;
      v_rows_deleted := sql%rowcount;
    exception
      when others then
        dbms_output.put_line('could not filter ' || v_table_name || ': ' || sqlerrm(sqlcode));
        v_rows_deleted := 0;
    end;
    commit;
    display_time(v_table_name, v_rows_deleted, v_start_time);
  end;
  
  
  /* FILTER POSTDTL TABLE */
  procedure filter_postdtl
  as
  begin
    v_start_time := sysdate;
    delete from postdtl a where not exists (select 1 from posthdr where invoice = a.invoice);
    v_rows_deleted := sql%rowcount;
    commit;
    display_time('postdtl', v_rows_deleted, v_start_time);
  end;
  
  
  /* FILTER WORKORDER TABLES */
  procedure filter_cust_workorder
  as
  begin
    v_start_time := sysdate;
    
    delete from custworkorderinstructions a 
    where not exists (select 1 from custworkorder where seq = a.seq);
    
    v_rows_deleted := sql%rowcount;
    commit;
    display_time('custworkorderinstructions', v_rows_deleted, v_start_time);
    
    v_start_time := sysdate;
    
    delete from custworkorderdestinations a 
    where not exists (select 1 from custworkorder where seq = a.seq);
                       
    v_rows_deleted := sql%rowcount;
    commit;
    display_time('custworkorderdestinations', v_rows_deleted, v_start_time);
  end;
  
  
  /* FITLER USERHEADER TABLE */
  procedure filter_userheader
  as
  begin
    v_start_time := sysdate;
    
    delete from userheader a 
    where facility is not null
      and facility not in (select facility from facility)
      and chgfacility != 'A'
      and (chgfacility != 'S' or not exists (
        select 1 from userfacility
        where nameid = a.nameid and facility in (select facility from facility)));

    v_rows_deleted := sql%rowcount;
    commit;
    display_time('userheader', v_rows_deleted, v_start_time);
  end;
  
  
  /* FILTER BY NAMEID */
  procedure filter_table_by_nameid (v_table_name varchar2, v_column_name varchar2 default 'nameid')
  as
    v_sql varchar2(2000);
  begin

    v_sql := 'delete from ' || v_table_name || ' a
              where not exists (select 1 from userheader where nameid = a.' || v_column_name || ')';
              
    v_start_time := sysdate;
    begin
      execute immediate v_sql;
      v_rows_deleted := sql%rowcount;
    exception
      when others then
        dbms_output.put_line('could not filter ' || v_table_name || ': ' || sqlerrm(sqlcode));
        v_rows_deleted := 0;
    end;
    commit;
    display_time(v_table_name, v_rows_deleted, v_start_time);
  end;
  
begin

-- DISABLE THE TRIGGERS
  alter_triggers('DISABLE');

-- DELETE FROM ORDERHDR
  filter_orderhdr;
  
-- FILTER TABLES BASED ON WHAT IS LEFT IN THE ORDERHDR TABLE
  filter_table_by_orderhdr('orderhistory');
  filter_table_by_orderhdr('orderhdrbolcomments');
  filter_table_by_orderhdr('orderhdrsac');
  filter_table_by_orderhdr('orderattach', true);
  filter_table_by_orderhdr('orderdtl');
  filter_table_by_orderhdr('orderdtlbolcomments');
  filter_table_by_orderhdr('orderdtlline');
  filter_table_by_orderhdr('orderdtlpack');
  filter_table_by_orderhdr('orderdtlsac');
  filter_table_by_orderhdr('orderdtlsn');
  filter_table_by_orderhdr('multishiphdr');
  filter_table_by_orderhdr('multishipdtl');
  filter_table_by_orderhdr('multishipitems');
  filter_table_by_orderhdr('multiship_charges');
  filter_table_by_orderhdr('asncartondtl');
  filter_table_by_orderhdr('qcresult');
  filter_table_by_orderhdr('qcresultdtl');
  filter_table_by_orderhdr('workorderpicks');
  
-- FILTER TABLES BASED ON WHAT IS LEFT IN THE LOADS TABLE
  filter_table_by_load('loadstop');
  filter_table_by_load('loadstopship');
  filter_table_by_load('loadstopshipbolcomments');
  filter_table_by_load('loadsbolcomments');
  filter_table_by_load('loadstopbolcomments');
  
-- DELETE FROM USER HEADER
  filter_userheader;
  
-- FILTER TABLES BASED ON WHAT IS LEFT IN THE USERHEADER TABLE
  filter_table_by_nameid('userheaderview');
  filter_table_by_nameid('usercertificates');
  filter_table_by_nameid('usercustomer');
  filter_table_by_nameid('usercxgrids');
  filter_table_by_nameid('userforms');
  filter_table_by_nameid('usergrids');
  filter_table_by_nameid('usernavigator');
  filter_table_by_nameid('usertoolbar', 'userid');
  --filter_table_by_nameid('user_settings', 'userid');
  
-- OTHER FILTERS
  filter_postdtl;
  filter_cust_workorder;
  
-- ENABLE THE TRIGGERS
  alter_triggers('ENABLE'); 
end;
/

exit;