--
-- $Id$
--
alter table customer add(
    allow_receipt_cloning   char(1),
    allow_shipment_split    char(1)
);

exit;
