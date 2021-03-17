--
-- $Id$
--

create unique index custitemlotcatchweight_unique on custitemlotcatchweight
   (facility, custid, item, lotnumber);

exit;
