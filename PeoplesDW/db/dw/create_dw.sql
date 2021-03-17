-- Execute as Sysdba.

whenever sqlerror continue
whenever oserror continue

set verify off;

alter profile default limit
  failed_login_attempts unlimited
  password_life_time unlimited;

create user dw
  identified by dw
  default tablespace users
  temporary tablespace temp
  profile default
  account unlock;

alter user dw default role all;

revoke unlimited tablespace from dw;

alter user dw quota unlimited on users;

alter user dw quota unlimited on users16kb;

grant
  connect,
  resource,
  select_catalog_role,
  aq_administrator_role
to dw;

grant
  create view,
  create table,
  select any table,
  create sequence,
  create any directory,
  drop any directory,
  debug connect session,
  create procedure
to dw;

grant select on sys.v_$session to dw;
grant select on sys.dba_objects to dw;

grant execute on sys.dbms_alert to dw;
grant execute on sys.dbms_pipe to dw;
grant execute on sys.dbms_lock to dw;

exit;
