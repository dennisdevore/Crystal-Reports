--
-- $Id: alter_tbl_import_item_hazset_table_msds.sql 2149 2013-08-14 19:11:27Z ay $
--
alter table import_item_hazset_table add
(
   printmsds                  char(1),
   msdsformat                 varchar2(255)   
); 

exit;
