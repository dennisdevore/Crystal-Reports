--
-- $Id$
--
drop index applocks_unique;

create unique index applocks_unique
   on applocks(lockid);
   
exit;
