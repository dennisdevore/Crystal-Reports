
alter table customer_aux add
(
  validate_staging  char(1) default 'F'
);

update customer_aux
set validate_staging = 'F'
where validate_staging is null;

commit;

exit;