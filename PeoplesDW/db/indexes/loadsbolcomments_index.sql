--
-- $Id$
--
drop index loadsbolcomments_unique;
drop index loadbolcomments_unique;

create unique index loadsbolcomments_unique
   on loadsbolcomments(loadno);

exit;