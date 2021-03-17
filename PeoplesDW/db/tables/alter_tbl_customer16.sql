--
-- $Id$
--
alter table customer add
(
   use_catch_weights char(1),
   catch_weight_out_cap_type char(1)
);

update customer
	set use_catch_weights = 'N'
   where use_catch_weights is null;

commit;

exit;
