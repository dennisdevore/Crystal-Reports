--
-- $Id$
--
spool addarc.log;


create user arc identified by arc
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;

grant connect to arc with admin option;
grant resource to arc with admin option;
alter user arc default role connect,
                            resource;
alter user arc default role connect,
                             resource;
grant select any table to arc with admin option;
grant insert any table to arc with admin option;
grant create any table to arc with admin option;
grant drop any table to arc with admin option;
grant unlimited tablespace to arc;

spool off;

exit;
