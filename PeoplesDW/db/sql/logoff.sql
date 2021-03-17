--
-- $Id$
--
set serveroutput on
set verify off

declare
   msgno number;
   msg varchar2(256);
begin
   dbms_output.enable(1000000);
   zlic.logoff(msgno, msg);
   dbms_output.put_line('msgno = ' || msgno);
   dbms_output.put_line('msg = ' || msg);
end;
/
