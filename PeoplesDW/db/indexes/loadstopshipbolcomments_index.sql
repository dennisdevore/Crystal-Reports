--
-- $Id$
--
drop index loadstopshipbolcomments_unique;

create unique index loadstopshipbolcomments_unique
   on loadstopshipbolcomments(loadno,stopno,shipno);

exit;