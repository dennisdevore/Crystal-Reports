--
-- $Id: alter_tbl_customer_aux_defaultworkordertype.sql 5854 2010-12-13 14:41:08Z ed $
--

alter table customer_aux add
(
defaultworkordertype char(1)
);

update customer_aux
   set defaultworkordertype = 'K' -- make this 'M' for Parke
 where defaultworkordertype is null;
 
exit;