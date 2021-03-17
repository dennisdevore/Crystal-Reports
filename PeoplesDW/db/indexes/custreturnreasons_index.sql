--
-- $Id$
--
drop index custreturnreasons_unique;

create unique index custreturnreasons_unique
   on custreturnreasons(custid, code);

exit;
