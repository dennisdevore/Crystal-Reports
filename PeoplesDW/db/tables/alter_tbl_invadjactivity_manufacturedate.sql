--
-- $Id: alter_tbl_invadjactivity_manufacturedate.sql 1 2005-05-26 12:20:03Z ed $
--

alter table invadjactivity add
(
manufacturedate date,
expirationdate date,
oldmanufacturedate date,
oldexpirationdate date,
newmanufacturedate date,
newexpirationdate date
);
exit;
