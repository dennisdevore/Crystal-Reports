#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM oracle_sid\n"
   exit ;;
esac

if [ "${1}" == "$ORACLE_SID" ]; then
   $ORACLE_HOME/bin/sqlplus ${ALPS_DBLOGON} @backout_inventory.sql
else
   echo -e "\noracle_sid mismatch\n"
fi