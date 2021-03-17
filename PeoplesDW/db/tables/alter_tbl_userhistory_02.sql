--
-- $Id: alter_tbl_userhistory_02.sql 3234 2012-09-10 22:41:54Z sanjay $
--
alter table userhistory add
(
   employeecost        number(10,2)
   ,equipmentcost      number(10,2)
);
exit;
