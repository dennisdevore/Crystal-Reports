#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM package_name\n"
   exit ;;
esac

SYN_LOWER=`echo ${1} | tr '[A-Z]' '[a-z]'`
SYN_UPPER=`echo ${1} | tr '[a-z]' '[A-Z]'`

cat >/tmp/$IAM.$$.sql <<EOF
set termout off echo off feedback off trimspool on heading off line 32000
set pagesize 0 serveroutput on;
set null ""

spool ${SYN_LOWER}spec.sql;

select '--' || CHR(10) ||
       '-- \$Id: ${SYN_LOWER}spec.sql 1483 2008-09-21 11:46:02Z brianb $' || CHR(10) ||
       '--'
  from dual;
select 'create or replace' from dual;
select rtrim(decode(substr(text,length(text),1),chr(10),substr(text,1,length(text)-1),text))
  from user_source
where name = '${SYN_UPPER}'
and type = 'PACKAGE';

select '/' from dual;
select 'exit;' from dual;

spool ${SYN_LOWER}body.sql;

select '--' || CHR(10) ||
       '-- \$Id: ${SYN_LOWER}body.sql 1483 2008-09-21 11:46:02Z brianb $' || CHR(10) ||
       '--'
  from dual;

select 'create or replace' from dual;
select rtrim(decode(substr(text,length(text),1),chr(10),substr(text,1,length(text)-1),text))
  from user_source
where name = '${SYN_UPPER}'
and type = 'PACKAGE BODY';

select '/' from dual;
select 'exit;' from dual;

exit
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
