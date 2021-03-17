--
-- $Id$
--
spool addups.log;


create user ups identified by ups
    default tablespace users
    temporary tablespace temp
    profile default
    account unlock;

grant connect to ups;

spool off;

exit;
