--
-- $Id$
--
drop index custsqft_unique;

create unique index custsqft_unique
on custsqft(facility,custid);
exit;
