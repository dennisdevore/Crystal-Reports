--
-- $Id: alter_tbl_customer45.sql 606 2006-08-08 00:00:00Z eric $
--
alter table customer add
(
   tracktrailertemps    varchar(1)
);

update customer
   set tracktrailertemps = 'N'
 where tracktrailertemps is null;

exit;
