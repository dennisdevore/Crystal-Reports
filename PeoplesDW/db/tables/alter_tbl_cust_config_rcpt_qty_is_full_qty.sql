--
-- $Id: alter_tbl_cust_config_rcpt_qty_is_full_qty.sql 8580 2012-06-25 13:06:24Z brianb $
--
alter table customer_aux add
(rcpt_qty_is_full_qty char(1)
);

update customer_aux
   set rcpt_qty_is_full_qty = 'N'
 where rcpt_qty_is_full_qty is null;
 
alter table custproductgroup add
(rcpt_qty_is_full_qty char(1)
);

update custproductgroup
   set rcpt_qty_is_full_qty = 'C'
 where rcpt_qty_is_full_qty is null;
 
alter table custitem add
(rcpt_qty_is_full_qty char(1)
);

update custitem
   set rcpt_qty_is_full_qty = 'C'
 where rcpt_qty_is_full_qty is null;
 
exit;
