--
-- $Id$
--
create user alps identified by alps
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
grant connect to alps;
grant resource to alps;
alter user alps default role connect,
                             resource;
grant select any table to alps;
grant create session to alps;
grant create library to alps;
grant create procedure to alps;
grant create public synonym to alps;
grant create sequence to alps;
grant create synonym to alps;
grant create table to alps;
grant create trigger to alps;
grant create type to alps;
grant create view to alps;
grant drop public synonym to alps;
grant execute any library to alps;
grant execute any procedure to alps;
grant unlimited tablespace to alps;
exit;
