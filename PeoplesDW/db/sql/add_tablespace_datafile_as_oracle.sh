#!/bin/bash
cat >/tmp/$IAM.$$.sql <<EOF
alter tablespace users
  add datafile '/u01/app/oracle/oradata/${ORACLE_SID}/users02.dbf'
  size 500m;
alter database datafile '/u01/app/oracle/oradata/${ORACLE_SID}/users02.dbf'
  autoextend on next 50m maxsize unlimited;
exit;
EOF
sql @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
