--
-- $Id: alter_tbl_customer_aux_prefill_directed_putaway_loc.sql 1558 2007-02-05 20:26:20Z brianb $
--
alter table customer_aux add
(
prefill_directed_putaway_loc char(1)
);

exit;
