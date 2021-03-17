#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
grant create any directory to alps;
grant drop any directory to alps;
exit;
EOF
sql @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
