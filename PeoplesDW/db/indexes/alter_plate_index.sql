--
-- $Id$
--
drop index plate_loadno_idx;

create index plate_loadno_idx
   on plate(loadno);
exit;
