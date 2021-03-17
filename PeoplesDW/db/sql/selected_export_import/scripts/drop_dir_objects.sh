#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
set verify off trimspool on feedback off
drop directory synapse_$1_dumps;
drop directory synapse_$1_parfiles;
drop directory synapse_$1_scripts;
exit
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql

