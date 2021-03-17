--
-- $Id: alter_tbl_custitem_pallet_controls.sql 1558 2007-02-05 20:26:20Z brianb $
--
alter table custitem add
(
nomixeditemlp char(1),
disallowoverbuiltlp char(1),
warnshortlp char(1),
warnshortlpqty number(7)
);

exit;
