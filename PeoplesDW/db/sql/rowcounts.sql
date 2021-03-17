set heading off
Set trimout on
Set trimspool on
Set linesize 100
set timing on
set tab off
set serveroutput on;
spool rowcounts.out;

create table tmp_rowcounts
(table_name varchar2(30)
,rowcount integer
);

declare
l_cmd varchar2(255);
l_rowcount pls_integer;
l_length pls_integer;
l_str varchar2(255);
begin

  for obj in (select table_name
                from user_tables
               where table_name not like 'BIN$%'
               order by table_name)
  loop
    l_cmd := 'select count(1) from ' || obj.table_name;
    begin
      execute immediate l_cmd
        into l_rowcount;
    exception when others then
      dbms_output.put_line('Table not found: ' || obj.table_name);
      l_rowcount := 0;
    end;
    insert into tmp_rowcounts values (obj.table_name, l_rowcount);
  end loop;

  commit;
  
  for obj in (select cast(table_name as char(30)) table_name,rowcount
                from tmp_rowcounts
               order by rowcount desc)
  loop
    dbms_output.put_line(obj.table_name || ' ' || to_char(obj.rowcount,'FM9,999,999,999'));
  end loop;

end;
/
drop table tmp_rowcounts;
exit;


