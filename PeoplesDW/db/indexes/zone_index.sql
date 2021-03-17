--
-- $Id$
--
drop index pk_zone;
drop index zone_unique;
create unique index zone_unique
on zone(facility,zoneid);
exit;