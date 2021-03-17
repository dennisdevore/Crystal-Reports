--
-- $Id: add_report.sql 5114 2010-06-14 15:55:21Z eric $
--
set serveroutput on
set verify off
accept p_report prompt 'Enter report filename: '
accept p_label prompt 'Enter report label: '

declare
   return_status integer;
   return_msg VARCHAR2(1000);
begin

   dbms_output.enable(1000000);
   pkg_manage_reports.usp_add_report(
     '&&p_report',
     '&&p_label',
     return_status,
     return_msg);

   if return_status != 1 then
     zut.prt('  Error adding report: '||return_msg);
   else
     zut.prt('  Report added successfully');
   end if;
end;
/
exit;
