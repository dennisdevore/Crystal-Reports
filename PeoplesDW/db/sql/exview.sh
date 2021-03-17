#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM view_name\n"
   exit ;;
esac

SYN_LOWER=`echo ${1} | tr '[A-Z]' '[a-z]'`
SYN_UPPER=`echo ${1} | tr '[a-z]' '[A-Z]'`

cat >/tmp/$IAM.$$.sql <<EOF
spool ${SYN_LOWER}_tmp.sql;
set linesize 32000;
set pagesize 0;
set heading off;
set verify off;
set echo off;
set termout off;
set long 2000000000;
set trimspool on;
set feedback off;
set serveroutput on;

declare
l_col_cnt pls_integer;

begin

dbms_output.put_line('create or replace view ' || '${SYN_UPPER}');

l_col_cnt := 1;

for col in (select column_name
              from user_tab_columns
             where table_name = '${SYN_UPPER}'
             order by column_id)
loop

  if l_col_cnt = 1 then
    dbms_output.put_line('(' || col.column_name);
  else
    dbms_output.put_line(',' || col.column_name);
  end if;
  
  l_col_cnt := l_col_cnt + 1;
  
end loop;

dbms_output.put_line(') as ');

for txt in (select text
              from user_views
             where view_name = '${SYN_UPPER}')
loop
  dbms_output.put_line(txt.text);
end loop;

dbms_output.put_line('/');
dbms_output.put_line('exit;');

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others...');
end;
/
exit;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
cat ${SYN_LOWER}_tmp.sql | tr -s '\n' > ${SYN_LOWER}.sql
rm ${SYN_LOWER}_tmp.sql
rm /tmp/$IAM.$$.sql
