--
-- $Id$
--
drop index location_loctype_idx;

create index location_loctype_idx
   on location(facility,loctype);
exit;
