#!/bin/bash
DS=`date +"%Y%m%d%H%M%S"`
ORATAB=/etc/oratab

cat $ORATAB | while read LINE
do
   case $LINE in
   \#*)  ;;                   #comment-line in oratab
   *)
#     Proceed only if third field is 'Y'.
      if [ "`echo $LINE | awk -F: '{print $3}' -`" = "Y" ] ; then
        ORATAB_SID=`echo $LINE | awk -F: '{print $1}' -`
        setdb ${ORATAB_SID}
        cat >/tmp/$IAM.$$.sql <<EOF
        set heading off
        set pagesize 0
        set linesize 32000
        set long 4000
        set trimspool on
        spool parms_`uname -n`_${ORACLE_SID}_${DS}.out
        show parameters
        exit;
EOF
        sql @/tmp/$IAM.$$.sql
        rm /tmp/$IAM.$$.sql
      fi
      ;;
   esac
done
