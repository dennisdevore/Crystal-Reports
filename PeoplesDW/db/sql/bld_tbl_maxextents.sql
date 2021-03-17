--
-- $Id$
--
set heading off feedback off verify off

select 'alter table "' || table_name || '" storage (maxextents unlimited);'
   from user_tables
   where max_extents < 2147483645;

spool tbl_maxextents.sql
/
spool off
set heading on feedback on verify on
