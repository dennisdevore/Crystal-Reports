
alter table customer_aux add
(
  warn_overwt_orders  char(1) default 'N',
  order_weight_limit  number(7),
  warn_overwt_loads   char(1) default 'N',
  load_weight_limit  number(7)
);

exit;
