set pagesize 10000 linesize 132
set heading off
spool modify_long_to_clob.sql
select 'alter table ' || utc.table_name || ' modify(' || utc.column_name || ' CLOB);' 
from user_tab_columns utc, user_objects uo
where utc.data_type = 'LONG'
and utc.table_name = uo.object_name
and uo.object_type = 'TABLE';
spool off;
exit;
