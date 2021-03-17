--
-- $Id$
--
drop index palletinventory_unique;

create unique index palletinventory_unique
on palletinventory(custid, facility, pallettype);

exit;
