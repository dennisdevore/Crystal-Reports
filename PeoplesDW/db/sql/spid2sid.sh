#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM queue_name\n"
   exit ;;
esac

echo "select s.sid, s.serial#, s.status, p.spid, p.program from v\$session s, v\$process p where s.username = 'ALPS' and p.addr (+) = s.paddr and p.spid = ${1};" >/tmp/$IAM.$$.sql
echo " " >>/tmp/$IAM.$$.sql
echo "exit;" >>/tmp/$IAM.$$.sql

sqlplus -S alps/alps @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
