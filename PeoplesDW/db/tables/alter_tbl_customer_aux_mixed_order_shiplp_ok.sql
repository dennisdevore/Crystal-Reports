--
-- $Id$
--
alter table customer_aux add
(
   mixed_order_shiplp_ok   char(1) default 'Y'
);

exit;
