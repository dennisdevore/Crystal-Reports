--
-- $Id$
--
alter table custitem add
(
   require_cyclecount_lot  char(1),
   require_phyinv_lot      char(1)
);

update custitem
   set require_cyclecount_lot = 'C'
   where require_cyclecount_lot is null;

update custitem
   set require_phyinv_lot = 'C'
   where require_phyinv_lot is null;

exit;
