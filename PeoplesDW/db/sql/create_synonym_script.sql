set feedback off verify off serveroutput on;
spool ../dumps/public_synonyms.sql
declare
strLine varchar2(4000);

begin


dbms_output.enable(1000000);

for sq in (select synonym_name, table_name
             from all_synonyms
            where owner = 'PUBLIC'
				  and table_owner = 'ALPS')
loop
  strLine := 'create public synonym ' || sq.synonym_name ||
				 ' for ALPS.' || sq.table_name || ';';
  dbms_output.put_line(strLine);
end loop;

  dbms_output.put_line('exit;');

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others....');
end;
/
spool off;
exit;
