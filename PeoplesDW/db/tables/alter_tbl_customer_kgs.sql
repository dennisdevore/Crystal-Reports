--
-- $Id$
--
alter table customer add
(
   lbs_to_kgs_conversion_factor   number(11,8),
   lbs_to_kgs_round_up_down_none  char(1),
   default_weight_uom             char(2)
);

update customer
   set default_weight_uom = 'LB',
       lbs_to_kgs_round_up_down_none = 'S',
       lbs_to_kgs_conversion_factor = 0
 where default_weight_uom is null;

exit;
