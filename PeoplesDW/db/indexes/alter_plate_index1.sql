--
-- $Id$
--
drop index plate_fromshippinglpid;

create index plate_fromshippinglpid
   on plate(fromshippinglpid);
exit;
