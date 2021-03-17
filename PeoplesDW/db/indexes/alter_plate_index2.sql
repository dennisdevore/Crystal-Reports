--
-- $Id$
--
drop index plate_invstatus_idx;
drop index plate_invclass_idx;

create index plate_invstatus_idx
   on plate(facility,invstatus);
create index plate_invclass_idx
   on plate(facility,inventoryclass);

exit;
