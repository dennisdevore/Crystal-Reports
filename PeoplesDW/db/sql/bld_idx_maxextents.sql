--
-- $Id$
--
set heading off feedback off verify off

select 'alter index "' || index_name || '" storage (maxextents unlimited);'
   from user_indexes
   where max_extents < 2147483645;

spool idx_maxextents.sql
/
spool off
set heading on feedback on verify on
