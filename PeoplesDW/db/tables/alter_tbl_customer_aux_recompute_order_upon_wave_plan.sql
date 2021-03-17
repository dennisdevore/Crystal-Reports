alter table customer_aux add
(recompute_order_upon_wave_plan  char(1)
);
update customer_aux
   set recompute_order_upon_wave_plan = 'N'
 where recompute_order_upon_wave_plan is null;
exit;
