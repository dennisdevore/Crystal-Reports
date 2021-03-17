#!/bin/sh

echo `pwd`

cat >/tmp/$IAM.$$.sql <<EOF
set verify off trimspool on feedback off
create or replace directory synapse_$$_filter as '`pwd`';

create table tmp_customers (
  custid varchar2(10) primary key
);

create table tmp_users (
  nameid varchar2(12) primary key
);
  
create table tmp_facilities (
  facility varchar2(3) primary key
);

create table tmp_progress (
  table_name varchar2(30),
  start_time date,
  end_time date,
  rows_filtered number
);

exit
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
