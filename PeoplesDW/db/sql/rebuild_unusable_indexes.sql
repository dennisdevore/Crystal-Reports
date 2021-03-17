set serveroutput on;

declare
updflag char(1);
cmdSql varchar2(2000);

begin

updflag := substr(upper('&1'),1,1);

for obj in (select index_name
             from user_indexes
            where status = 'UNUSABLE')
loop

  cmdSql := 'alter index ' || obj.index_name || ' rebuild';
  dbms_output.put_line(cmdSql);
  if updflag = 'Y' then
    execute immediate cmdSql;
  end if;
end loop;

end;
/
exit;
