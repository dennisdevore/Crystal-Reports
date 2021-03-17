--
-- $Id: alter_tbl_customer_aux_phyinv_item.sql 0 2008-02-04 00:00:00Z eric $
--
alter table customer_aux add
(
   require_phyinv_item varchar(1)
);
update customer_aux set require_phyinv_item = 'Y'
   where require_phyinv_item is null;
commit;

exit;
