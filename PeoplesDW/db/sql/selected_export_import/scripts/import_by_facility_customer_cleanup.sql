set serveroutput on size 1000000

declare 

  procedure drop_table(v_table_name varchar2)
  as
  begin
    execute immediate 'drop table ' || v_table_name;
    dbms_output.put_line('Dropped table ' || v_table_name);
  exception
    when others then
      null;
  end;
  
begin
  drop_table('EXPORT_TMP_FACILITY');
  drop_table('EXPORT_TMP_CUSTOMER');
  drop_table('EXPORT_TMP_ORDERS');
  drop_table('EXPORT_TMP_LOADS');
  drop_table('EXPORT_TMP_POSTHDR');
  drop_table('EXPORT_TMP_CUSTWO');
end;
/

exit;