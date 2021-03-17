--
-- $Id: alter_tbl_customer_aux_order_by_lot.sql 1558 2007-02-05 20:26:20Z brianb $
--
alter table customer_aux add
(
order_by_lot char(1) default 'N'
);

update customer_aux set order_by_lot = 'N' where order_by_lot is null;

exit;
