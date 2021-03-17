#!/bin/sh

case $# in
1) ;;
*) echo -e "\nusage: $IAM <username>\n"
   return ;;
esac

echo -n "Preparing to OVERWRITE `uname -n` $ORACLE_SID (y/n)? "
read REPLY
if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ]; then
  return
fi

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

ALTER PROFILE DEFAULT LIMIT
  FAILED_LOGIN_ATTEMPTS UNLIMITED
  PASSWORD_LIFE_TIME UNLIMITED;
create user $1
  identified by $1
  default tablespace users
  temporary tablespace temp
  profile default
  account unlock;
grant connect to $1;
grant resource to $1;
grant select_catalog_role to $1;
grant aq_administrator_role to $1;
alter user $1 default role all;
grant create type to $1;
grant create view to $1;
grant create table to $1;
grant select any table to $1;
grant drop public synonym to $1;
grant create public synonym to $1;
grant execute any procedure to $1;
revoke unlimited tablespace from $1;
alter user $1
  quota unlimited on users;
alter user $1
  quota unlimited on users16kb;
grant execute on  sys.aq$_agent to $1 with grant option;
grant execute on  sys.aq$_dequeue_history to $1 with grant option;
grant execute on  sys.aq$_dequeue_history_t to $1 with grant option;
grant execute on  sys.aq$_history to $1 with grant option;
grant execute on  sys.aq$_notify_msg to $1 with grant option;
grant execute on  sys.aq$_recipients to $1 with grant option;
grant execute on  sys.aq$_subscribers to $1 with grant option;
grant select on  sys.dba_objects to $1;
grant execute on  sys.dbms_alert to $1;
grant execute on  sys.dbms_aq to $1;
grant execute on  sys.dbms_pipe to $1;
grant execute on  sys.dbms_lock to $1;
grant select on  sys.v_$session to $1;
grant create sequence to $1;
grant create database link to $1;
grant select on dba_data_files to $1;
grant create any directory to $1;
grant drop any directory to $1;
grant debug connect session to $1;
grant debug any procedure to $1;
exit;

EOF
sql @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql



