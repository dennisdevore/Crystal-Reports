--
-- $Id$
--
set heading off feedback off verify off linesize 200

select 'set heading off feedback off verify off' from dual;

select 'select rpad(''' || table_name || ''', 32), count(1) from ' || table_name || ';'
   from user_tables
   order by 1

spool tblstemp.sql
/

spool off
spool tbls.lst
@tblstemp
!rm tblstemp.sql
exit;
