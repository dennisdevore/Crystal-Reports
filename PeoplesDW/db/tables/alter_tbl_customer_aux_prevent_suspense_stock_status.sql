alter table customer_aux add
(prevent_suspense_stock_status char(1)
);

update customer_aux
   set prevent_suspense_stock_status = 'N'
 where prevent_suspense_stock_status is null;

exit;
