#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
set verify off trimspool on feedback off
create or replace directory synapse_$$_dumps as '`pwd`/dumps';
create or replace directory synapse_$$_parfiles as '`pwd`/parfiles_for_facility';
create or replace directory synapse_$$_scripts as '`pwd`/scripts';
exit
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
