create user ramp
  identified by ramp
  default tablespace users
  temporary tablespace temp
  profile default
  account unlock;
grant connect to ramp;
grant resource to ramp;
grant select_catalog_role to ramp;
alter user ramp default role all;
grant create type to ramp;
grant create view to ramp;
grant create table to ramp;
grant select any table to ramp;
grant drop public synonym to ramp;
grant create public synonym to ramp;
grant execute any procedure to ramp;
grant unlimited tablespace to ramp;
grant create sequence to ramp;
exit;
