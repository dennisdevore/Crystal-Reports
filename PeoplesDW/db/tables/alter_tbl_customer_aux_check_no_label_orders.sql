--
-- $Id: check_no_label_orders.sql 5854 2010-12-13 14:41:08Z ed $
--
alter table customer_aux add
(
   check_no_label_orders  char(1)
);

exit;
