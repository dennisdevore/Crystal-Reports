--
-- $Id$
--
drop index custitemcount_unique;

create unique index custitemcount_unique on custitemcount
   (custid, item, type, uom);

exit;
