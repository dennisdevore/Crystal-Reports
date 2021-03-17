--
-- $Id: alterinvoicedtl5.sql 1 2005-05-26 12:20:03Z ed $
--
alter table invoicedtl add(
      pallet_count_total  number(12,2)
);

exit;

