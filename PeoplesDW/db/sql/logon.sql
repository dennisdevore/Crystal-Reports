--
-- $Id$
--
set serveroutput on
set verify off
accept p_user prompt 'Enter user: '
accept p_facility prompt 'Enter facility: '
accept p_origin prompt 'Enter origin: '

declare
   msgno number;
   msg varchar2(256);
begin
   dbms_output.enable(1000000);
   zlic.logon(upper('&&p_user'), upper('&&p_facility'), upper('&&p_origin'), msgno, msg);
   dbms_output.put_line('msgno = ' || msgno);
   dbms_output.put_line('msg = ' || msg);
end;
/
