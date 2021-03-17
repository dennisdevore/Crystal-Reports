#!/bin/sh

case $# in 
2) ;;
*) echo -e "\nusage: $IAM <table_name> <remote_connection>\n"
   return ;;
esac

sqlplus -S ${ALPS_DBLOGON} << EOF
 set serveroutput on size unlimited format wrapped
 set pagesize 50000
 set linesize 200
  
 exec zcomparedata.compare_table_across_env('$1','$2');
EOF



