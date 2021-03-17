--
-- $Id: alter_customer_rcptnote_cross_cust_yn.sql 285 2005-10-28 17:35:55Z ed $
--
alter table customer_aux add
(
 rcptnote_include_cross_cust_yn char(1)
);

update customer_aux
   set rcptnote_include_cross_cust_yn = 'N'
 where rcptnote_include_cross_cust_yn is null;

exit;
