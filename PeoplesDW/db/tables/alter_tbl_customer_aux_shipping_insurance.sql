alter table customer_aux add(shipping_insurance char(1));

update customer_aux
   set shipping_insurance = 'N'
   where shipping_insurance is null;

exit;
