#!/bin/bash

IAM=mod_alter

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
spool ${LOWER_PARM_01}_mod_alter.sql

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
l_alter_needed boolean;
l_exist_col_count pls_integer;

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
  
  l_alter_needed := false;

  for utc in (select column_name,data_type,data_scale,
                     data_precision,data_length
                from user_tab_columns
               where table_name = l_table_name_parm
               order by column_id)
  loop

    l_col_count := l_col_count + 1;
    begin
      select count(1)
        into l_exist_col_count
        from user_tab_columns
       where table_name = l_table_name
         and column_Name = utc.column_name;
    exception when others then
      l_exist_col_count := 0;
    end;
    if l_exist_col_count = 0 then
      if l_alter_needed = False then
        dbms_output.put_line('alter table ' || l_table_name || ' add ');
      end if;
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
      if l_alter_needed = False then
        l_column_name := '(' || l_column_name;
        l_alter_needed := True;
      else
        l_column_name := ',' || l_column_name;
      end if;
      dbms_output.put_line(l_column_name || ' ' || l_data_type);
    end if;    
  end loop;

  if l_alter_needed = True then
    dbms_output.put_line(');');
    dbms_output.put_line('');
  end if;
  
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
