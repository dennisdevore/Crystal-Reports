set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
spool lpid_cols.out
break on report
compute sum of count(1) on report
select
column_name, count(1)
from user_tab_columns utc
where (column_name like upper('%LPID%') or column_name = 'CARTONID')
  and char_length = 15
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
group by column_name
order by column_name;
select
table_name,column_name,char_length,nullable
from user_tab_columns utc
where (column_name like upper('%LPID%') or column_name = 'CARTONID')
  and char_length = 15
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
order by table_name,column_name;
select
distinct table_name
from user_tab_columns utc
where (column_name like upper('%LPID%') or column_name = 'CARTONID')
  and char_length = 15
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
order by table_name;
spool off;
spool alters_for_lpid_expansion.sql
select 'alter table ' || table_name ||
  ' modify ' || column_name || ' varchar2(22);'
from user_tab_columns utc
where (column_name like upper('%LPID%') or column_name = 'CARTONID')
  and char_length = 15
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
order by table_name,column_name;
spool off;
exit;
