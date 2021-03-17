--
-- $Id: alter_tbl_custproductgroup_phyinv_item.sql 0 2008-02-04 00:00:00Z eric $
--
alter table custproductgroup add
(
   require_phyinv_item varchar(1)
);
update custproductgroup set require_phyinv_item = 'C'
   where require_phyinv_item is null;
commit;

exit;
