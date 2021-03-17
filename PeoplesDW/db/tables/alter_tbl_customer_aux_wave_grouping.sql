--
-- $Id: alter_tbl_customer_aux_paper_based_sortpick.sql 6856 2011-06-27 19:41:27Z ed $
--
alter table customer_aux add
(
   order_grouping_procedure  varchar2(128)
);

exit;
