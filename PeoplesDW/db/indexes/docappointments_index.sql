--
-- $Id$
--

drop index docappointments_idx;
drop index docappointments_facility_idx;
drop index docappointments_startTime_idx;
drop index docappointments_endTime_idx;

create unique index docappointments_idx
on docappointments(appointmentID);

create index docappointments_facility_idx
on docappointments(facility);

create index docappointments_startTime_idx
on docappointments(startTime);

create index docappointments_endTime_idx
on docappointments(endTime);

exit;
