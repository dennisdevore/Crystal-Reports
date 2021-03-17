--
-- $Id$
--
drop index loads_stageloc_idx;
create index loads_stageloc_idx
on loads(facility,stageloc);
exit;

