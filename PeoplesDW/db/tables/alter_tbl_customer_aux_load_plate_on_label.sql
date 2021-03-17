alter table customer_aux add(load_plate_on_label char(1));

update customer_aux
set load_plate_on_label = 'N'
where load_plate_on_label is null;

exit;