#!/bin/sh

echo -n "Preparing to OVERWRITE `uname -n` $ORACLE_SID (y/n)? "
read REPLY
if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ]; then
  return
fi

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

shutdown immediate;
startup;
drop user alps cascade;
exit;
EOF
sql @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
sql @create_alps
sql @reclaim_datafile_space


