set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
spool item_cols.out
select
distinct column_name
from user_tab_columns utc
where column_name like upper('%ITEM%')
  and column_name not like upper('USERITEM%')
  and column_name not like upper('ORIG_USERITEM%')
  and column_name not like upper('PACKAGEITEM%')
  and column_name not like upper('PACKAGEDITEM%')
  and char_length = 20
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
order by column_name;
select
table_name,column_name,char_length,nullable
from user_tab_columns utc
where column_name like upper('%ITEM%')
  and column_name not like upper('USERITEM%')
  and column_name not like upper('ORIG_USERITEM%')
  and column_name not like upper('PACKAGEITEM%')
  and column_name not like upper('PACKAGEDITEM%')
  and char_length = 20
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
order by table_name,column_name;
spool off;
spool alters_for_item_expansion.sql
select 'alter table ' || table_name ||
  ' modify ' || column_name || ' varchar2(50);'
from user_tab_columns utc
where column_name like upper('%ITEM%')
  and column_name not like upper('USERITEM%')
  and column_name not like upper('ORIG_USERITEM%')
  and column_name not like upper('PACKAGEITEM%')
  and column_name not like upper('PACKAGEDITEM%')
  and char_length = 20
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
order by table_name,column_name;
select 'alter table custitem modify descr varchar2(255);'
  from dual;
select 'alter table custitem_new modify descr varchar2(255);'
  from dual;
select 'alter table custitem_old modify descr varchar2(255);'
  from dual;
spool off;
exit;
