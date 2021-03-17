#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM object_name\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
select
table_name,column_name,char_length,nullable
from user_tab_columns utc
where column_name like upper('%${1}%')
and exists (select 1
              from user_objects uo
             where utc.table_name = uo.object_name
               and object_type = 'TABLE')
order by table_name,column_name;
exit
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
