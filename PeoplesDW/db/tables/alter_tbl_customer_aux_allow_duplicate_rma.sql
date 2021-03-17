--
-- $Id: alter_tbl_customer_allow_paperbased_loads.sql 8703 2012-07-26 17:17:40Z eric $
--
alter table customer_aux add(
        allow_duplicate_rma    char(1)
);

update customer_aux
   set allow_duplicate_rma  = 'N'
   where allow_duplicate_rma is null;

commit;
-- exit;