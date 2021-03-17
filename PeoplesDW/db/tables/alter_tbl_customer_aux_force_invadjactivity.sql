alter table customer_aux add
(force_invadjactivity char(1)
);

update customer_aux
   set force_invadjactivity = 'N'
 where force_invadjactivity is null;
 

exit;
