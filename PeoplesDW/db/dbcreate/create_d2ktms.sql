--
-- $Id: create_d2ktms.sql 6290 2011-03-15 05:42:56Z brianb $
--
create user d2ktms
  identified by d2ktms
  default tablespace users
  temporary tablespace temp
  profile default
  account unlock;
grant connect to d2ktms;
grant resource to d2ktms;
grant select_catalog_role to d2ktms;
grant aq_administrator_role to d2ktms;
alter user d2ktms default role all;
grant create type to d2ktms;
grant create view to d2ktms;
grant create table to d2ktms;
grant select any table to d2ktms;
grant drop public synonym to d2ktms;
grant create public synonym to d2ktms;
grant execute any procedure to d2ktms;
revoke unlimited tablespace from d2ktms;
alter user d2ktms
  quota unlimited on users;
alter user d2ktms
  quota unlimited on users16kb;
grant execute on  sys.aq$_agent to d2ktms with grant option;
grant execute on  sys.aq$_dequeue_history to d2ktms with grant option;
grant execute on  sys.aq$_dequeue_history_t to d2ktms with grant option;
grant execute on  sys.aq$_history to d2ktms with grant option;
grant execute on  sys.aq$_notify_msg to d2ktms with grant option;
grant execute on  sys.aq$_recipients to d2ktms with grant option;
grant execute on  sys.aq$_subscribers to d2ktms with grant option;
grant select on  sys.dba_objects to d2ktms;
grant execute on  sys.dbms_alert to d2ktms;
grant execute on  sys.dbms_aq to d2ktms;
grant execute on  sys.dbms_pipe to d2ktms;
grant execute on  sys.dbms_lock to d2ktms;
grant select on  sys.v_$session to d2ktms;
grant create sequence to d2ktms;
grant create database link to d2ktms;
exit;
