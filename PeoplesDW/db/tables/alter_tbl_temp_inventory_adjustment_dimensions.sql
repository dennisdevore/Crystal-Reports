alter table TEMP_INVENTORY_ADJUSTMENT 
add
(length number(10,4)
,width  number(10,4)
,height number(10,4)
,pallet_weight number(10,4)
,orig_length number(10,4)
,orig_width  number(10,4)
,orig_height number(10,4)
,orig_pallet_weight number(10,4)
);

exit;
