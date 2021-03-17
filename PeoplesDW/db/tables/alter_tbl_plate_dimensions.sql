--
-- $Id: alter_tbl_plate_dimensions.sql 1 2005-05-26 12:20:03Z ed $
--
alter table plate
add
(length number(10,4)
,width  number(10,4)
,height number(10,4)
,pallet_weight number(10,4)
);
alter table deletedplate
add
(length number(10,4)
,width  number(10,4)
,height number(10,4)
,pallet_weight number(10,4)
);
exit;
