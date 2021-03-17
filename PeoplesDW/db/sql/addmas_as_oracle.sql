--
-- $Id: addmas.sql 1 2005-05-26 12:20:03Z ed $
--
spool addmas.log;


create user mas identified by masR3p0rt1ng
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;

grant connect, resource to mas;
grant create synonym to mas;

spool off;

exit;
