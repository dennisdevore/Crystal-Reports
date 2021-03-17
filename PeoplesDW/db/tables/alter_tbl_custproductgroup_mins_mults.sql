--
-- $Id: alter_tbl_custproductgroup_mins_mults.sql 1550 2007-02-02 07:45:54Z brianb $
--
alter table custproductgroup add
(use_min_units_qty char(1) default 'N'
,min_units_qty number(7) default 1
,use_multiple_units_qty char(1) default 'N'
,multiple_units_qty number(7) default 1
);

exit;
