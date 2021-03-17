--
-- $Id$
--
drop index orderhdr_stageloc_idx;
create index orderhdr_stageloc_idx
   on orderhdr(fromfacility,stageloc);
exit;

