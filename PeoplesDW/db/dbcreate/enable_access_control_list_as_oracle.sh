#!/bin/bash
# before running, modify the enable_access_control_list.sql
# script with the client's smtp server name (or IP address) and port
#
sql @${ORACLE_HOME}/rdbms/admin/utlmail.sql
sql @${ORACLE_HOME}/rdbms/admin/prvtmail.plb

sql @enable_access_control_list

