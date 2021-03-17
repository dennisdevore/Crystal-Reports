--
-- $Id$
--
drop index itempickfronts_unique;

create unique index itempickfronts_unique
on itempickfronts(custid,item,facility,pickfront);

exit;

