alter table customer_aux add(auto_assign_inbound_load char(1));

update customer_aux
  set auto_assign_inbound_load = 'N'
  where auto_assign_inbound_load is null;

exit;
