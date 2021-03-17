--
-- $Id$
--
create user pecas identified by pecas
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;
grant connect to pecas;
grant resource to pecas;
alter user pecas default role connect,
                             resource;

grant create session to pecas;
grant create library to pecas;
grant create procedure to pecas;
grant create public synonym to pecas;
grant create sequence to pecas;
grant create synonym to pecas;
grant create table to pecas;
grant create trigger to pecas;
grant create type to pecas;
grant create view to pecas;
grant drop public synonym to pecas;
grant unlimited tablespace to pecas;
grant execute on dbms_pipe to pecas;

exit;
