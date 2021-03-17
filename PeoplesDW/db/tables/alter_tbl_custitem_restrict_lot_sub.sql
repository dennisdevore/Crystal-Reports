--
-- $Id: alter_tbl_custitem_26.sql 1 2005-05-26 12:20:03Z ed $
--
alter table custitem add (
  restrict_lot_sub  varchar2(1)
);

alter table custproductgroup add (
  restrict_lot_sub  varchar2(1)
);

alter table customer_aux add (
  restrict_lot_sub  varchar2(1)
);

exit;

