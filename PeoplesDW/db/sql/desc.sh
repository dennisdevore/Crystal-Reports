#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM table_name\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
set heading off
desc ${1};
select count(1) from user_tab_columns where table_name = upper('${1}');
exit;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
