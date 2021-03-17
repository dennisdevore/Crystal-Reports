--
-- $Id: alter_tbl_customer_aux_mixed_order_shiplp_buildmst_ok.sql 3127 2008-10-15 17:33:28Z ed $
--
alter table customer_aux add
(
   mixed_order_shiplp_buildmst_ok   char(1) default 'N'
);

exit;
