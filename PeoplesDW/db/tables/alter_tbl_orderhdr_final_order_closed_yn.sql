--
-- $Id: alter_tbl_orderhdr36.sql 297 2005-11-08 20:04:35Z ed $
--

alter table ORDERHDR add
(
  final_order_closed_yn  char(1)
);

exit;