--
-- $Id$
--
create index deletedplate_lotnumber_idx
on deletedplate(lotnumber);
create index deletedplate_serialnumber_idx
on deletedplate(serialnumber);
create index deletedplate_useritem1_idx
on deletedplate(useritem1);
create index deletedplate_useritem2_idx
on deletedplate(useritem2);
create index deletedplate_useritem3_idx
on deletedplate(useritem3);
--exit;

