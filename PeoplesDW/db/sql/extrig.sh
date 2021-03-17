#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM table_name\n"
   exit ;;
esac

SYN_LOWER=`echo ${1} | tr '[A-Z]' '[a-z]'`
SYN_UPPER=`echo ${1} | tr '[a-z]' '[A-Z]'`

cat >/tmp/$IAM.$$.sql <<EOF
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

spool ${SYN_LOWER}_trigger.sql;

begin

dbms_output.enable(1000000);

for tr in (select distinct trigger_name
             from user_triggers
            where table_name = '${SYN_UPPER}'
            order by trigger_name)
loop

  for src in (select decode(substr(text,1,15), 'TRIGGER "ALPS."',
                'create or replace ' || substr(text,16,4000), text) as text
                from user_source
               where name = tr.trigger_name
               order by line)
  loop

    if substr(src.text,length(src.text),1) = chr(10) then
      dbms_output.put_line(substr(src.text,1,length(src.text)-1));
    else
      dbms_output.put_line(src.text);
    end if;

  end loop;

  dbms_output.put_Line('/');
  dbms_output.put_Line('show error trigger ' || lower(tr.trigger_name) || ';');

end loop;

dbms_output.put_Line('exit;');

end;

/

exit
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql

