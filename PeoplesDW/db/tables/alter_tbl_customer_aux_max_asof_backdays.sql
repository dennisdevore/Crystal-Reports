
alter table customer_aux add
(
  max_asof_backdate_days  number default 90
);

update customer_aux
set max_asof_backdate_days = 90
where max_asof_backdate_days is null;

commit;

exit;