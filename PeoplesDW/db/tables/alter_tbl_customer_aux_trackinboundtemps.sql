--
-- $Id: alter_tbl_customer_aux_trackinboundtemps.sql 3829 2009-09-01 16:14:49Z ed $
--
alter table customer_aux add
(
   trackoutboundtemps	char(1) default 'N'
);

exit;
