alter table customer_aux add(
seal_required char(1)
);

update customer_aux
   set seal_required = 'N'
 where seal_required is null;

alter table consignee add(
seal_required char(1)
);

update consignee
   set seal_required = 'N'
 where seal_required is null;

exit;