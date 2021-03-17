--
-- $Id: alter_tbl_invadj947dtlex_manufacturedate.sql 1 2005-05-26 12:20:03Z ed $
--

alter table invadj947dtlex add 
(
oldmanufacturedate date,
oldexpirationdate date,
newmanufacturedate date,
newexpirationdate date,
expirationdate date,
manufacturedate date
);
exit;
