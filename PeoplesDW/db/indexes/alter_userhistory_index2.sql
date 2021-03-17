--
-- $Id$
--
drop index userhistory_name_event;

create index userhistory_name_event_begin on
   userhistory(nameid, event, begtime);

create index userhistory_name_event_end on
   userhistory(nameid, event, endtime);

create index userhistory_name_end on
   userhistory(nameid, endtime);

exit;
