create or replace procedure zapstatistics
as
   l_cnt pls_integer := 0;
   l_file varchar2(10) := 'analyze';
begin
   execute immediate 'alter session set NLS_DATE_FORMAT=''MM-DD-YYYY HH24:MI:SS''';

   for t in (select table_name, last_analyzed from user_tables
               where last_analyzed is not null) loop
      zdbg.dump_msg(sysdate||': '||t.table_name||' analyzed '||t.last_analyzed, l_file);
      execute immediate 'analyze table ' || t.table_name || ' delete statistics';
      l_cnt := l_cnt + 1;
   end loop;
   zdbg.dump_msg(sysdate||': '||l_cnt||' tables processed', l_file);
end zapstatistics;
/

show errors procedure zapstatistics
exit;
