--
-- $Id$
--
set heading off feedback off verify off
spool trunctmp.sql

select 'truncate table ' || table_name || ';'
   from user_tables
   order by 1;
   
select 'drop index ' || index_name || ';'
   from user_indexes
   order by 1;

spool off
exit;
