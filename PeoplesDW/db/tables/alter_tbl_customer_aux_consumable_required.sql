alter table customer_aux add(consumable_required char(1));

update customer_aux
  set consumable_required = 'N'  -- 'I'nbound, 'O'utbound, 'B'oth, 'N'one
  where consumable_required is null;

exit;
