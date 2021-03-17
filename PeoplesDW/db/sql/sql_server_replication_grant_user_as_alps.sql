set serveroutput on;

declare
l_cnt pls_integer;
l_cmd varchar2(4000);

begin

l_cnt := 0;

for obj in (select table_name
              from user_tables)
loop

  l_cmd := 'grant select on ' || obj.table_name || ' to sqlsrvrepl';
  zut.prt(l_cmd);
  execute immediate l_cmd;
  l_cnt := l_cnt + 1;

end loop;

zut.prt('grants executed: ' || l_cnt);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit
