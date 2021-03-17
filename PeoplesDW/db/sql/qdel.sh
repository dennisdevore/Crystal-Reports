#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM queue_name\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
delete from qt_rp_$1;
exit
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
