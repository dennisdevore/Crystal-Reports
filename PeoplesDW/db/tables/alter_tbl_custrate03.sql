--
-- $Id: alter_tbl_custrate01.sql 1 2005-05-26 12:20:03Z ed $
--
alter table custrate add(
  passthru_match varchar2(30),
  passthru_number varchar2(30)
);

exit;
