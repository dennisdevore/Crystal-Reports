--
-- $Id$
--
drop index userhistory_idx;

create index userhistory_idx on
   userhistory(nameid, begtime);

exit;
