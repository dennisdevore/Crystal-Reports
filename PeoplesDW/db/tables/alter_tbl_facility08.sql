--
-- $ID: alter_tbl_facility08.sql
--
alter table facility add
(
  daysfromport     number(2),
  includeweekend   char(1) default 'Y'
);

commit;

exit;
