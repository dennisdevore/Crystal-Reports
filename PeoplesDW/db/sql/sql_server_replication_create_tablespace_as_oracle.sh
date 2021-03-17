#!/bin/bash
cat >/tmp/$IAM.$$.sql <<EOF
create tablespace sqlsrvrepl
  datafile '/u01/app/oracle/oradata/${ORACLE_SID}/sqlsrvrepl01.dbf'
  size 100m
  autoextend on
  next 100m
  maxsize unlimited;
exit;
EOF
sql @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
