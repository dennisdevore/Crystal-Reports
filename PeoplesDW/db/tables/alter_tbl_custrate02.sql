--
-- $Id: alter_tbl_custrate01.sql 1 2005-05-26 12:20:03Z ed $
--
alter table custrate add(
  apply_charge_reversal_yn    varchar2(1),
  cr_receipt_activity         varchar2(4),
  cr_reversal_activity        varchar2(4)
);

exit;
