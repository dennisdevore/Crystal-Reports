alter table customer_aux add
(
duplicate_aliases_allowed char(1)
);

update customer_aux
   set duplicate_aliases_allowed = 'N'
 where duplicate_aliases_allowed is null;
 
exit;

