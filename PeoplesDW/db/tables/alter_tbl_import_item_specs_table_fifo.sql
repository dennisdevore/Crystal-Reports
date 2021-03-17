--
-- $Id: alter_tbl_import_item_specs_table_fifo.sql 2149 2013-08-14 19:11:27Z ay $
--
alter table import_item_specs_table add
(
   use_fifo        varchar2(1),
   labelqty        number(3)
);

exit;
