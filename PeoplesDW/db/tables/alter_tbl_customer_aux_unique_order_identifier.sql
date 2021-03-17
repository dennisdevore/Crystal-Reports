alter table customer_aux add(unique_order_identifier char(1) default 'R');

update customer_aux
   set unique_order_identifier = 'R' where unique_order_identifier is null;

commit;

exit;
