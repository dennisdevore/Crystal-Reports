alter table customer_aux add
(
  ignore_smallpkg_station_weight char(1)
);

update customer_aux
   set ignore_smallpkg_station_weight = 'N'
 where ignore_smallpkg_station_weight is null;
 
exit;
