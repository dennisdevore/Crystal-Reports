--
-- $Id: userhistory.sql 1 2005-05-26 12:20:03Z ed $
--
drop index userhistory_idx;

create index userhistory_idx on userhistory
   (nameid, begtime) tablespace users16kb;

exit;
