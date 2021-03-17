
alter table customer_aux add
(
upd_orderdtl_when_validating char(1)
);

update customer_aux
   set upd_orderdtl_when_validating = 'N'
 where upd_orderdtl_when_validating is null;

exit;
