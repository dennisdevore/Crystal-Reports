#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
set verify off trimspool on feedback off
drop directory synapse_$1_filter;

drop table tmp_customers;
drop table tmp_users;
drop table tmp_progress;

exit
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql

