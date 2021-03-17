#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM queue_name\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
set heading off
select q_name,corrid,to_char(enq_time, 'mm/dd/yy hh24:mi:ss') enq_time,
       user_data from qt_rp_$1 order by enq_time;
exit
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
