--
-- $Id$
--
alter table custproductgroup add
(
   use_catch_weights char(1),
   catch_weight_out_cap_type char(1)
);

exit;
