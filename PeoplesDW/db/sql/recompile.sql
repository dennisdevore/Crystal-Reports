--
-- $Id$
--
set serveroutput on;
declare
sqlcur integer;
sqlcount integer;
totcount integer;
loopcount integer;
objtype varchar2(15);
suffix varchar2(5);

cursor objcur is
  select object_name, object_type
    from user_objects
   where status != 'VALID'
     and object_type in
         ('VIEW', 'PACKAGE','PACKAGE BODY', 'TRIGGER', 'PROCEDURE', 'FUNCTION');

begin

loopcount := 1;

dbms_output.put_line('<Begin invalid object recompilation>');

while (loopcount < 4)
loop

  totcount := 0;

  for obj in objcur
  loop
    begin
      dbms_output.put_line('Processing ' || obj.object_name || ' ' || obj.object_type || '...');
      sqlcur := dbms_sql.open_cursor;
      if obj.object_type = 'PACKAGE BODY' then
        objtype := 'PACKAGE';
        suffix := 'BODY';
      else
        objtype := obj.object_type;
        suffix := '';
      end if;
      dbms_sql.parse(sqlcur, 'alter ' || objtype ||
        ' ' || obj.object_name || ' compile ' || suffix,
         dbms_sql.native);
      sqlcount := dbms_sql.execute(sqlcur);
      dbms_output.put_line('Recompilation complete');
      totcount := totcount + 1;
    exception when others then
      dbms_output.put_line('Exception: ' || sqlerrm);
    end;
    dbms_sql.close_cursor(sqlcur);
  end loop;

  dbms_output.put_line('Invalid objects recompiled: ' || totcount ||
    ' (pass ' || loopcount || ')');

  if totcount = 0 then
    exit;
  end if;

  loopcount := loopcount + 1;

end loop;

dbms_output.put_line('<End invalid object recompilation>');

exception when OTHERS then
  dbms_output.put_line('when others ');
  dbms_output.put_line(sqlerrm);
end;

/
exit;
