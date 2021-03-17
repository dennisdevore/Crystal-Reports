--
-- $Id$
--
drop index consshipwght;

create unique index consshipwghtzip on
  consigneecarriers(consignee, shiptype, fromweight, begzip);

exit;
