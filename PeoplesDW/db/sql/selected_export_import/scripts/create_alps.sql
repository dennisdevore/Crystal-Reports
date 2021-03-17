--
-- $Id: create_alps.sql 9595 2013-02-23 16:18:33Z brianb $
--
ALTER PROFILE DEFAULT LIMIT
  FAILED_LOGIN_ATTEMPTS UNLIMITED
  PASSWORD_LIFE_TIME UNLIMITED;
create user alps
  identified by alps
  default tablespace users
  temporary tablespace temp
  profile default
  account unlock;
grant connect to alps;
grant resource to alps;
grant select_catalog_role to alps;
grant aq_administrator_role to alps;
alter user alps default role all;
grant create type to alps;
grant create view to alps;
grant create table to alps;
grant select any table to alps;
grant drop public synonym to alps;
grant create public synonym to alps;
grant execute any procedure to alps;
revoke unlimited tablespace from alps;
alter user alps
  quota unlimited on users;
alter user alps
  quota unlimited on users16kb;
grant execute on  sys.aq$_agent to alps with grant option;
grant execute on  sys.aq$_dequeue_history to alps with grant option;
grant execute on  sys.aq$_dequeue_history_t to alps with grant option;
grant execute on  sys.aq$_history to alps with grant option;
grant execute on  sys.aq$_notify_msg to alps with grant option;
grant execute on  sys.aq$_recipients to alps with grant option;
grant execute on  sys.aq$_subscribers to alps with grant option;
grant select on  sys.dba_objects to alps;
grant execute on  sys.dbms_alert to alps;
grant execute on  sys.dbms_aq to alps;
grant execute on  sys.dbms_pipe to alps;
grant execute on  sys.dbms_lock to alps;
grant select on  sys.v_$session to alps;
grant create sequence to alps;
grant create database link to alps;
grant select on dba_data_files to alps;
grant create any directory to alps;
grant drop any directory to alps;
grant debug connect session to alps;
grant debug any procedure to alps;
exit;
