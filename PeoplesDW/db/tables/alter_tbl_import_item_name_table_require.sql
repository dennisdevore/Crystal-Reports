--
-- $Id: alter_tbl_import_item_name_table_require.sql 2149 2013-08-14 19:11:27Z ay $
--
alter table import_item_name_table add
(
   iskit                       char(1),
   require_cyclecount_item     varchar2(1),
   require_cyclecount_lot      char(1),
   require_phyinv_item         varchar2(1),
   require_phyinv_lot          char(1)   
); 

exit;
