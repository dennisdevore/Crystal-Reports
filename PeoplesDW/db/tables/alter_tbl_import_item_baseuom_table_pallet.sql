--
-- $Id: alter_tbl_import_item_baseuom_table_pallet.sql 2149 2013-08-14 19:11:27Z ay $
--
alter table import_item_baseuom_table add
(
   pallet_qty                  number(7),
   pallet_uom                  varchar2(4),
   pallet_name                 varchar2(20),
   limit_pallet_to_qty_yn      char(1) 
);

exit;
