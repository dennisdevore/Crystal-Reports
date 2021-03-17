--
-- $Id: alter_tbl_customer_aux01.sql 1243 2007-02-12 00:00:00Z eric $
--
alter table customer_aux add
(
   generatebolnumber  char(1)
);

update customer_aux
   set generatebolnumber = 'N'
 where generatebolnumber is null;

exit;
