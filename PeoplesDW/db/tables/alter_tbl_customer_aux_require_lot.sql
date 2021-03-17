--
-- $Id$
--
alter table customer_aux add
(
   require_cyclecount_lot  char(1),
   require_phyinv_lot      char(1)
);

update customer_aUx
   set require_cyclecount_lot = 'Y'
   where require_cyclecount_lot is null;

update customer_aUx
   set require_phyinv_lot = 'Y'
   where require_phyinv_lot is null;

exit;
