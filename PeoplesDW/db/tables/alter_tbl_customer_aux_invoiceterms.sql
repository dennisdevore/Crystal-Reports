--
-- $Id: alter_tbl_customer_aux_invoiceterms.sql 5946 2011-01-11 18:57:31Z ed $
--
alter table customer_aux add
(
   invoiceterms_code  varchar2(12)
);

exit;
