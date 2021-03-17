--
-- $Id$
--
accept sid_v Prompt 'Enter SID: '
declare
   cursor opencur is select * from v$open_cursor where sid = &&sid_v
      order by sql_text;
   ccount number;
begin
   dbms_output.enable(1000000);
   select count(*) into ccount from v$open_cursor where sid = &&sid_v;
   dbms_output.put_line(' Num cursors open is '||ccount);
   ccount := 0;
-- get text of open/parsed cursors
   for vcur in opencur loop
      ccount := ccount + 1;
      dbms_output.put_line(' Cursor #'||ccount);
    	dbms_output.put_line('     text: '|| vcur.sql_text);
   end loop;
end;
/
