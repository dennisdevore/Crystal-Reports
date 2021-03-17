--
-- $Id$
--
spool grant_arc.log;

grant resource to alps;
grant connect to alps;
grant select any table to alps;
grant insert any table to alps;
grant create any table to alps;
grant drop any table to alps;
grant unlimited tablespace to alps;

spool off;
exit;
