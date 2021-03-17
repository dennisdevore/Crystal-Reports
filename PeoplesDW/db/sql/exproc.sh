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

select 'create or replace ' 
  from dual;

select text
  from user_source
 where name = '${SYN_UPPER}'
   and type = 'PROCEDURE'
 order by line;
 
select '/'
  from dual;
select 'exit;'
  from dual;

exit;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
cat ${SYN_LOWER}_tmp.sql | tr -s '\n' > ${SYN_LOWER}.sql
rm ${SYN_LOWER}_tmp.sql
rm /tmp/$IAM.$$.sql
