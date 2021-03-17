--
-- $Id$
--
drop index custshipper_unique;

create unique index custshipper_unique
on custshipper(custid,shipper);

exit;
