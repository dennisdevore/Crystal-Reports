set serveroutput on;

declare
l_cnt pls_integer;


begin

for obj in (select code,count(1)
              from &&1
             group by code
             having count(1) > 1)
loop

  dbms_output.put_line(obj.code);
  delete
    from &&1
   where code = obj.code
	  and rownum < 2;

end loop;

exception when others then
  dbms_output.put_line(sqlerrm);
end;
/
exit;
