#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
create or replace directory dumpdir as '/backup';
grant read, write on directory dumpdir to alps;
exit
exit
EOF
sql @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
