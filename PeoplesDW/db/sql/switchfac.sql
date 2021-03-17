--
-- $Id$
--
set serveroutput on
set verify off
accept p_user prompt 'Enter user: '
accept p_newfac prompt 'Enter new facility: '

declare
   msgno number;
   msg varchar2(256);
begin
   dbms_output.enable(1000000);
   zlic.switchfacility(upper('&&p_user'), upper('&&p_newfac'), msgno, msg);
   dbms_output.put_line('msgno = ' || msgno);
   dbms_output.put_line('msg = ' || msg);
end;
/
