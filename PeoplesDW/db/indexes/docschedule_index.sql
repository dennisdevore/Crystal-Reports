--
-- $Id$
--

drop index docschedule_idx;
drop index docschedule_facility_idx;
drop index docschedule_startDate_idx;
drop index docschedule_endDate_idx;

create unique index docschedule_idx
on docschedule(scheduleID);

create index docschedule_facility_idx
on docschedule(facility);

create index docschedule_startDate_idx
on docschedule(startDate);

create index docschedule_endDate_idx
on docschedule(endDate);

exit;
