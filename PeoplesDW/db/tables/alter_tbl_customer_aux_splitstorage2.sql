--
-- $Id: alter_tbl_customer_aux_packlist.sql 5985 2011-01-14 17:42:16Z eric $
--
alter table customer_aux add
(
  proratedays_2  number(2),
  proratepct_2  number(3)
);

exit;
/