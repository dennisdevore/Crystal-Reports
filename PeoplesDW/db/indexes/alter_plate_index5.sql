--
-- $Id$
--
create index plate_lotnumber_idx
on plate(lotnumber);
create index plate_serialnumber_idx
on plate(serialnumber);
create index plate_useritem1_idx
on plate(useritem1);
create index plate_useritem2_idx
on plate(useritem2);
create index plate_useritem3_idx
on plate(useritem3);
exit;

