--
-- $Id$
--
--drop index custdispositionfacility_unique;

create unique index custdispositionfacility_unique
   on custdispositionfacility(custid,disposition,facility);
exit;
