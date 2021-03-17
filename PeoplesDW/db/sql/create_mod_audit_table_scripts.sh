#!/bin/bash

IAM=mod_table

case $# in
1) ;;
*) echo "\nusage: $IAM <table_name>"
   exit ;;
esac

UPPER_PARM_01=`echo ${1} | tr 'a-z' 'A-Z'`
LOWER_PARM_01=`echo ${1} | tr 'A-Z' 'a-z'`

cat >/tmp/$IAM_sql.$$.sql <<EOF
set serveroutput on format wrapped;
set heading off;
set verify off;
set echo off;
set term off;
set pagesize 0;
set linesize 32000;
set trimspool on;
spool ${LOWER_PARM_01}_mod_tables.sql

declare

l_column_name varchar2(4000);
l_data_type varchar2(255);
l_col_count pls_integer;
l_ind_col_count pls_integer;
l_index_name varchar2(255);
l_table_name varchar2(255);
l_table_name_parm varchar2(255);
l_unique_index_name varchar2(255);
l_unique_index_count pls_integer;
l_object_suffix varchar2(4);
l_unique_index_col_count pls_integer;
l_loop_count pls_integer;

begin

dbms_output.enable(1000000);

l_table_name_parm := '${UPPER_PARM_01}';

for l_loop_count in 1..2
loop

  l_col_count := 0;

  if l_loop_count = 1 then
    l_object_suffix := '_OLD';
  else
    l_object_suffix := '_NEW';
  end if;    
  
  l_table_name := zaud.table_name(l_table_name_parm || l_object_suffix);
  
  dbms_output.put_line('create table ' || l_table_name);
  dbms_output.put_line('(MOD_SEQ NUMBER(10) not null');
  dbms_output.put_line(',MOD_TABLE_NAME VARCHAR2(30) not null');
  dbms_output.put_line(',MOD_TYPE CHAR(1) not null');
  dbms_output.put_line(',MOD_TIME DATE not null');
  
  for utc in (select column_name,data_type,data_scale,
                     data_precision,data_length
                from user_tab_columns
               where table_name = l_table_name_parm
               order by column_id)
  loop

    l_col_count := l_col_count + 1;
    l_column_name := utc.column_name;
    l_data_type := utc.data_type;
    if utc.data_type in ('NUMBER') then
      if utc.data_precision is not null then
        l_data_type := l_data_type || '(' || utc.data_precision;
        if nvl(utc.data_scale,0) <> 0 then
          l_data_type := l_data_type || ',' || utc.data_scale;
        end if;
        l_data_type := l_data_type || ')';
      end if;
    end if;
    if utc.data_type in ('CHAR','VARCHAR2') then
      l_data_type := l_data_type || '(' || utc.data_length;
      l_data_type := l_data_type || ')';
    end if;
    l_column_name := ',' || l_column_name;
    dbms_output.put_line(l_column_name || ' ' || l_data_type);
    
  end loop;

  dbms_output.put_line(');');
  dbms_output.put_line('');
  l_index_name := zaud.table_name(l_table_name || '_IDX');
  dbms_output.put_line('create index ' || l_index_name || ' on ' || l_table_name ||
                       '(mod_time);');
  dbms_output.put_line('');

  case l_table_name
    when 'CUST_INBOUND_DIMENSIONS_OLD' then
      l_index_name := 'INBOUND_DIMENSIONS_OLD_SEQ_IDX';
    when 'CUST_INBOUND_DIMENSIONS_NEW' then
      l_index_name := 'INBOUND_DIMENSIONS_NEW_SEQ_IDX';
    when 'USTITEM_INBOUND_DIMENSIONS_OLD' then
      l_index_name := 'INBOUND_DIMENSIONS_OLD_SEQ_ID2';
    when 'USTITEM_INBOUND_DIMENSIONS_NEW' then
      l_index_name := 'INBOUND_DIMENSIONS_NEW_SEQ_ID2';
    else
      l_index_name := zaud.table_name(l_table_name || '_SEQ_IDX');
  end case;

  dbms_output.put_line('create index ' || l_index_name || ' on ' || l_table_name ||
                       '(mod_seq);');
  
end loop;

dbms_output.put_line('exit;');

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
exit;
spool off;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM_sql.$$.sql
rm /tmp/$IAM_sql.$$.sql
