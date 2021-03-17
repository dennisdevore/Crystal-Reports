--
-- $Id$
--
drop index custrenewal_index;
create unique index custrenewal_index 
       on custrenewal(custid, renewal);
exit;
