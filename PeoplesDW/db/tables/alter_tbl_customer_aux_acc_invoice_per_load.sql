--
-- $Id: alter_tbl_customer_aux_allow_lineitem_weights.sql 5854 2010-12-13 14:41:08Z ed $
--
alter table customer_aux add
(
   acc_invoice_per_load  char(1) default 'N'
);

update customer_aux
   set acc_invoice_per_load = 'N'
 where acc_invoice_per_load is null;
commit;

exit;
