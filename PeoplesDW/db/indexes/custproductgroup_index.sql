--
-- $Id$
--
drop index custproductgroup_unique;

create unique index custproductgroup_unique
   on custproductgroup(custid,productgroup);


exit;
