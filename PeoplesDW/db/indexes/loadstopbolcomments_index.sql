--
-- $Id$
--
drop index loadstopbolcomments_unique;

create unique index loadstopbolcomments_unique
   on loadstopbolcomments(loadno,stopno);

exit;