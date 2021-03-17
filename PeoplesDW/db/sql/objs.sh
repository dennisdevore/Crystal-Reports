#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM object_name\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
select
substr(object_name,1,32) as object_name,
object_type,
to_char(last_ddl_time, 'mm/dd/yyyy hh24:mi:ss') as last_ddl_time
from user_objects
where object_name like upper('%${1}%') escape '\'
order by object_name;
exit
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
