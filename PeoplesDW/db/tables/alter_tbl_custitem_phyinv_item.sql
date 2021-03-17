--
-- $Id: alter_tbl_custitem_phyinv_item.sql 0 2008-02-04 00:00:00Z eric $
--
alter table custitem add
(
   require_phyinv_item varchar(1)
);
update custitem set require_phyinv_item = 'C'
   where require_phyinv_item is null;
commit;

exit;
