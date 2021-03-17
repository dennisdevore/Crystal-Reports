--
-- $Id: alter_tbl_customer_aux_estimate_cartons.sql 5804 2010-12-02 19:21:57Z ed $
--
alter table customer_aux add
(
   estimate_billing  char(1) default 'N'
);

exit;
