--
-- $Id$
--
--drop index userhistory_name_event;

create index userhistory_name_event on
   userhistory(nameid, event) tablespace users16kb;

exit;
