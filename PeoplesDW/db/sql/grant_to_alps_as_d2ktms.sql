set serveroutput on;

declare
l_cmd varchar2(4000);

begin

for obj in (select object_name
              from user_objects
             where object_type = 'TABLE')
loop

  l_cmd := 'grant select, insert, update, delete on ' ||
           obj.object_name || 
           ' to alps';
  dbms_output.put_line(l_cmd);
  execute immediate l_cmd;
  
end loop;

exception when others then
  dbms_output.put_line(sqlerrm);
end;
/
exit;

