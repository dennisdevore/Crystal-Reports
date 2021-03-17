--
-- $Id$
--
drop index laborstandards_unique;

create unique index laborstandards_unique
   on laborstandards(facility,custid,category,zoneid,uom);
exit;