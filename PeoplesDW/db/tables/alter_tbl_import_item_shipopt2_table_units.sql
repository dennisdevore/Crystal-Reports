--
-- $Id: alter_tbl_import_item_shipopt2_table_units.sql 2149 2013-08-14 19:11:27Z ay $
--
alter table import_item_shipopt2_table add
(
   use_min_units_qty            char(1),
   min_units_qty                number(7),
   use_multiple_units_qty       char(1),
   multiple_units_qty           number(7),
   sip_carton_uom               varchar2(4),
   tms_uom                      varchar2(4),
   track_picked_pf_lps          char(1),
   variancepct_use_default      char(1)
);

exit;
