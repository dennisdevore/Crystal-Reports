--
-- $Id: 
--
alter table customer_aux add
(returns_default_quantity number(10)
);

update customer_aux
   set returns_default_quantity = 0
 where returns_default_quantity is null;
 
exit;
