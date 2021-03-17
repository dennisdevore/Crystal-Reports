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
        echo -------------------------- ${ORACLE_SID} ------------------------------
        cat >/tmp/$IAM.$$.sql <<EOF
        set heading off
        set pagesize 0
        set linesize 32000
        set long 4000
        set trimspool on
        spool parms_`uname -n`_${ORACLE_SID}_${DS}.out
        SELECT  component,
                current_size/1024/1024 current_mb,
                min_size/1024/1024 min_mb,
                max_size/1024/1024 max_mb
        FROM    v\$memory_dynamic_components
        WHERE   current_size != 0;
        show parameter memory max_target;
        show parameter memory_target;
        show parameter pga_aggregate_target;
        show parameter sga_target;
        show parameter sga_max_size;
        exit;
EOF
        if [ "${ORACLE_SID}" == "ramp" ] ; then
          sqlplus -S ramp/ramp @/tmp/$IAM.$$.sql
        else          
          sqls @/tmp/$IAM.$$.sql
        fi
        rm /tmp/$IAM.$$.sql
      fi
      ;;
   esac
done
