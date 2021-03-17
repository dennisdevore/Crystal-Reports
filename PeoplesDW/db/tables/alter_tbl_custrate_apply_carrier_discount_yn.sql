alter table custrate 
add
(apply_carrier_discount_yn char(1)
);
update custrate
   set apply_carrier_discount_yn = 'N'
 where apply_carrier_discount_yn is null;
exit;


