--
-- $Id$
--
create index plate_child_idx
on plate(childfacility,childitem);
create index plate_parent_idx
on plate(parentfacility,parentitem);
exit;

