set serveroutput on size 1000000

declare
  v_start_time date;
  v_rows_deleted number;
  v_tmp_cust_rows number := 0;
  v_tmp_user_rows number := 0;
  v_tmp_facility_rows number := 0;
  

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
    
    insert into tmp_progress (table_name, start_time, end_time, rows_filtered)
    values (v_heading, v_start_time, sysdate, v_rows_deleted);
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
  

  /* FILTER CUSTOMER */
  procedure filter_customer
  as
  begin
    v_start_time := sysdate;
  
    delete from customer a
    where not exists (select 1 from tmp_customers where custid = a.custid)
      and custid not in ('DEFAULT');
      
    v_rows_deleted := sql%rowcount;
    display_time('customer', v_rows_deleted, v_start_time);
    commit;
  end;
  
  
  /* FILTER FACILITY */
  procedure filter_facility
  as
  begin
    v_start_time := sysdate;
  
    delete from facility a
    where not exists (select 1 from tmp_facilities where facility = a.facility)
      and facility not in ('ZET');
      
    v_rows_deleted := sql%rowcount;
    display_time('facility', v_rows_deleted, v_start_time);
    commit;
  end;
  
  /* FILTER CUSTOMER TABLES */
  procedure filter_table_by_custid(v_table_name varchar2)
  as
    v_sql varchar2(2000);
  begin
    v_sql := 'delete from ' || v_table_name || ' a
              where custid is not null and not exists (select 1 from customer where custid = a.custid)';
              
    v_start_time := sysdate;
    execute immediate v_sql;
    v_rows_deleted := sql%rowcount;
    display_time(v_table_name, v_rows_deleted, v_start_time);
    commit;
  end;
  
  
  /* FILTER FACILITY TABLES */
  procedure filter_table_by_facility(v_table_name varchar2)
  as
    v_sql varchar2(2000);
  begin
    v_sql := 'delete from ' || v_table_name || ' a
              where facility is not null and not exists (select 1 from facility where facility = a.facility)';
              
    v_start_time := sysdate;
    execute immediate v_sql;
    v_rows_deleted := sql%rowcount;
    display_time(v_table_name, v_rows_deleted, v_start_time);
    commit;
  end;
  
  
  /* FILTER ORDERHDR */
  procedure filter_orderhdr
  as
  begin
    v_start_time := sysdate;
  
    delete from orderhdr a
    where custid is not null and not exists (select 1 from customer where custid = a.custid);
      
    v_rows_deleted := sql%rowcount;
    display_time('orderhdr', v_rows_deleted, v_start_time);
    commit;
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
    execute immediate v_sql;
    v_rows_deleted := sql%rowcount;
    display_time(v_table_name, v_rows_deleted, v_start_time);
    commit;
  end;

  
  /* FILTER WORKORDER TABLES */
  procedure filter_cust_workorder
  as
  begin
    v_start_time := sysdate;
    
    delete from custworkorderinstructions a 
    where not exists (select 1 from custworkorder where seq = a.seq);
    
    v_rows_deleted := sql%rowcount;
    display_time('custworkorderinstructions', v_rows_deleted, v_start_time);
    commit;
    
    v_start_time := sysdate;
    
    delete from custworkorderdestinations a 
    where not exists (select 1 from custworkorder where seq = a.seq);
                       
    v_rows_deleted := sql%rowcount;
    display_time('custworkorderdestinations', v_rows_deleted, v_start_time);
    commit;
  end;
  
  
  /* FITLER USERHEADER TABLE */
  procedure filter_userheader
  as
  begin
    v_start_time := sysdate;
    
    delete from userheader a 
    where not exists (select 1 from tmp_users where nameid = a.nameid)
      and nameid not in ('ZETHCON','SYNAPSE') and usertype = 'U';

    v_rows_deleted := sql%rowcount;
    display_time('userheader', v_rows_deleted, v_start_time);
    commit;
  end;
  
  
  /* FILTER BY NAMEID */
  procedure filter_table_by_nameid (v_table_name varchar2, v_column_name varchar2 default 'nameid')
  as
    v_sql varchar2(2000);
  begin

    v_sql := 'delete from ' || v_table_name || ' a
              where not exists (select 1 from userheader where nameid = a.' || v_column_name || ')';
              
    v_start_time := sysdate;
    execute immediate v_sql;
    v_rows_deleted := sql%rowcount;
    display_time(v_table_name, v_rows_deleted, v_start_time);
    commit;
  end;
  
begin
  
  select count(1) into v_tmp_cust_rows
  from tmp_customers;
  
  select count(1) into v_tmp_user_rows
  from tmp_users;
  
  select count(1) into v_tmp_facility_rows
  from tmp_facilities;
  
-- DISABLE THE TRIGGERS
  alter_triggers('DISABLE');

-- FILTER CUSTOMER
  filter_customer;
  
-- FILTER CUSTOMER TABLES
  for rec in (select distinct a.table_name 
              from user_tab_cols a, user_tables b
              where a.table_name = b.table_name and a.column_name = 'CUSTID' and a.table_name != 'CUSTOMER')
  loop
    filter_table_by_custid(rec.table_name);
  end loop;

-- FILTER ORDERHDR
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

if v_tmp_user_rows != 0 then  
-- FILTER USER HEADER
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
end if;
  
-- FILTER FACILITY
  filter_facility;
  
-- FILTER FACILITY TABLES
  for rec in (select distinct a.table_name 
              from user_tab_cols a, user_tables b
              where a.table_name = b.table_name
              and a.column_name = 'FACILITY'
              and a.table_name not in ('CUSTOMER','USERHEADER'))
  loop
    filter_table_by_facility(rec.table_name);
  end loop;


-- OTHER FILTERS
  filter_cust_workorder;
  
-- ENABLE THE TRIGGERS
  alter_triggers('ENABLE'); 
  
exception
  when others then
    dbms_output.put_line('error: ' || sqlerrm(sqlcode));
    rollback;
end;
/

exit;