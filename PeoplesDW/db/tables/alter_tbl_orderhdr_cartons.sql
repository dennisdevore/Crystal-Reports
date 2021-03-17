--
-- $Id$
--
alter table orderhdr add
(
   estimated_cartons             number(10),
   estimated_package_cube        number(10,4),
   estimated_package_weight_lbs  number(17,8),
   estimated_weight_lbs          number(17,8),
   actual_cartons                number(10),
   actual_package_cube           number(10,4),
   actual_weight_lbs             number(17,8)
);

exit;


