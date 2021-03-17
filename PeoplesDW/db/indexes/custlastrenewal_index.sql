--
-- $Id$
--
drop index custlastrenewal_index;
create unique index custlastrenewal_index 
       on custlastrenewal(facility,custid);
exit;
