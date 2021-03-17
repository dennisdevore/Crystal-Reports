--
-- $Id$
--
create index deletedplate_child_idx
on deletedplate(childfacility,childitem);
create index deletedplate_parent_idx
on deletedplate(parentfacility,parentitem);
exit;

