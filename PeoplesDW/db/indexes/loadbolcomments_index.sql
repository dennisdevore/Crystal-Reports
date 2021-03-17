--
-- $Id$
--
drop index loadsbolcomments_unique;

create unique index loadbolcomments_unique
   on loadsbolcomments(loadno);

exit;