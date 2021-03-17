alter table requests add
(
  select_statements clob,
  where_clause varchar2(4000)
);
exit;

