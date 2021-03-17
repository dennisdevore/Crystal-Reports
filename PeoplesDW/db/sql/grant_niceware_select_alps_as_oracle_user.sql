set serveroutput on;

declare
l_sql varchar2(4000);


begin

for obj in (select * from all_objects where owner = 'ALPS' and object_type in ('TABLE','VIEW'))
loop

  l_sql := 'grant select on alps.' || obj.object_name || ' to niceware';
  zut.prt(l_sql);
  execute immediate l_sql;

end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
