--
-- $Id$
--
drop index custshipwght;

create unique index custshipwghtzip on
  customercarriers(custid, shiptype, fromweight, begzip);

exit;
