create or replace view facilityview
(
facility,
name,
state,
phone,
campus,
manager,
facilitystatus,
facilitystatusabbrev,
campusabbrev
)
as
select
facility,
name,
state,
phone,
campus,
manager,
facilitystatus,
facilitystatus.abbrev,
campusidentifiers.abbrev
from facility, facilitystatus, campusidentifiers
where facility.facilitystatus = facilitystatus.code (+)
  and facility.campus = campusidentifiers.code (+);

comment on table facilityview is '$Id$';

exit;
