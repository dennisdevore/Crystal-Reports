--
-- $Id: alter_tbl_shippingplatehistory_lpdates.sql 5946 2011-01-11 18:57:31Z ed $
--
alter table shippingplatehistory 
add
(length number(10,4)
,width  number(10,4)
,height number(10,4)
,pallet_weight number(10,4)
);

exit;
