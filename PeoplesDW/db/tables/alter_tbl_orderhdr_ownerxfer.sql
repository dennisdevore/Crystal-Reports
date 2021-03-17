--
-- $Id: alter_tbl_orderhdr_ownerxfer.sql 3180 2008-11-12 19:45:06Z ed $
--
alter table orderhdr add
(
   ownerxferorderid  number(9),
   ownerxfershipid   number(2)
);

exit;


