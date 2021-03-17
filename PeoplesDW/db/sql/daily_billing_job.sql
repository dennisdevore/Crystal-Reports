set serveroutput on
set feedback off
set echo off
set verify off

set termout off



spool BD.&&1..log

begin
   dbms_output.enable(1000000);


   zut.prt('Begin daily renewal processing at '
        ||to_char(sysdate,'MM/DD/YYYY HH24:MM:SS'));

-- Run the daily renewal process
   zbs.daily_billing_job;

   zut.prt('Finnished daily renewal processing at '
        ||to_char(sysdate,'MM/DD/YYYY HH24:MM:SS'));

end;
/
--exit;
