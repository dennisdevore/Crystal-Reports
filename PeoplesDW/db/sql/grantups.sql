--
-- $Id$
--
spool grantups.log;

drop public synonym multishiphdr;
drop public synonym multishipdtl;
drop public synonym worldshipdtl;
drop public synonym smallpackage;

create public synonym multishiphdr for alps.multishiphdr;
create public synonym multishipdtl for alps.multishipdtl;
create public synonym worldshipdtl for alps.worldshipdtl;
create public synonym smallpackage for alps.smallpackage;

grant select, update on multishiphdr to ups;
grant select, update on multishipdtl to ups;
grant select, insert on worldshipdtl to ups;
grant select on smallpackage to ups;

spool off;
exit;
