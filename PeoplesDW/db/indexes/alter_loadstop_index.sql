--
-- $Id$
--
drop index loadstop_stageloc_idx;
create index loadstop_stageloc_idx
on loadstop(facility,stageloc);
exit;

