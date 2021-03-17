#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM table_name\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF

set serveroutput on;
exec zut.show_constraints('${1}');
exit;
EOF
sqlplus -S alps/alps @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
