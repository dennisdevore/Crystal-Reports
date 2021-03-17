--
-- $Id: alter_tbl_customer_aux_allowtransferlipoverride.sql 5854 2010-12-13 14:41:08Z ed $
--
alter table customer_aux add
(
   allowtransferlipoverride char(1)
);

exit;
