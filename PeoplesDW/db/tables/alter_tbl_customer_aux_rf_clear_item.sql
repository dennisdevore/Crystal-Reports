--
-- $Id: alter_tbl_customer_aux_trackinboundtemps.sql 3829 2009-09-01 16:14:49Z ed $
--
alter table customer_aux add
(
   rf_clear_item	char(1) default 'N'
);

exit;
