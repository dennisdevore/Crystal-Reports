--
-- $Id$
--
drop index waves_unique;
drop index waves_status;
drop index waves_facility;
create unique index waves_unique
on waves(wave);
create unique index waves_status
on waves(facility,wavestatus,wave);
create unique index waves_facility
on waves(facility,wave,wavestatus);
exit;