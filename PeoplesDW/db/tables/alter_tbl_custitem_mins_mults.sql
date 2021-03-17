--
-- $Id: alter_tbl_mins_mults.sql 1550 2007-02-02 07:45:54Z brianb $
--
-- use_min_units_qty value is 'Y'es, 'N'o, 'C'ust Default (from custproductgroup)
alter table custitem add
(use_min_units_qty char(1) default 'C'
,min_units_qty number(7)
,use_multiple_units_qty char(1) default 'C'
,multiple_units_qty number(7)
);

exit;
