--
-- $Id: alter_tbl_orderhdr_freightvalue.sql $
--
alter table orderhdr add
(
   freightvalue number(12,6),
   bill_freight_yn varchar2(1)
);

exit;
