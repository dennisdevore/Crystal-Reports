--
-- $Id: alter_tbl_weber_pallet_labels06.sql 2446 2007-11-19 19:52:48Z ed $
--
alter table weber_pallet_labels add
(
   mixedorderorderid  number(9),
   mixedordershipid   number(2)
);

alter table weber_pallet_labels_temp add
(
   mixedorderorderid  number(9),
   mixedordershipid   number(2)
);

exit;
