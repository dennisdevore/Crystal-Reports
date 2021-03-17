--
-- $Id: alter_tbl_import_item_recopt1_table_catch.sql 2149 2013-08-14 19:11:27Z ay $
--
alter table import_item_recopt1_table add
(
   use_catch_weights             char(1),
   catch_weight_in_cap_type      char(1),
   catch_weight_out_cap_type     char(1),
   capture_pickuom               char(1),
   bulkcount_expdaterequired     char(1),
   bulkcount_mfgdaterequired     char(1)  
);

exit;
