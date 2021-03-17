declare
cmdSql varchar2(4000);

begin

dbms_output.enable(1000000);

for obj in (select name
              from v$database)
loop
  cmdSql := 'update impexp_definitions set targetalias = ''' ||
            obj.name || ''' where nvl(targetalias,''x'') != ''' ||
            obj.name || '''';
  dbms_output.put_line(cmdSql);
  execute immediate cmdSql;
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
