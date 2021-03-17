--
-- $Id: alter_tbl_customer_aux_prohibit_asn_reuse.sql 1558 2007-02-05 20:26:20Z brianb $
--
alter table customer_aux add
(
prohibit_asn_reuse char(1)
);

exit;
