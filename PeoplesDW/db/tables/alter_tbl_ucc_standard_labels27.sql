--
-- $Id: alter_tbl_ucc_standard_labels_27.sql 5943 2011-01-11 15:27:01Z ed $
--
alter table ucc_standard_labels add
(
   totalcases  number(7),
   serialnumber varchar2(30),
   useritem1 varchar2(30),
   useritem2 varchar2(30),
   useritem3 varchar2(30),
   expirationdate date,
   manufacturedate date
);

exit;
