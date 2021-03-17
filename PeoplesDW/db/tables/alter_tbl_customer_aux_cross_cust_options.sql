--
-- $Id: alter_tbl_customer_aux_cross_cust_options.sql 8703 2012-07-26 17:17:40Z eric $
--
alter table customer_aux add
(xcust_customer_as_shipto_yn char(1)
,xcust_shipdate_offset number(3)
,xcust_carrier varchar2(4)
,xcust_shipterms varchar2(3)
,xcust_shiptype char(1)
);

update customer_aux
   set xcust_customer_as_shipto_yn = 'Y'
 where xcust_customer_as_shipto_yn is null;

exit;
