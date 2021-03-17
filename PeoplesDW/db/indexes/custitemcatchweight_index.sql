--
-- $Id$
--
drop index custitemcatchweight_unique;

create unique index custitemcatchweight_unique on custitemcatchweight
   (custid, item);

exit;
