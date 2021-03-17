create or replace view doorview
(facility
,doorloc
,loadno
,loadstatusabbrev
,loadtypeabbrev
,locationstatus
,ranking -- dummy column; always zero
,trailer_number
)
as
select
door.facility,
door.doorloc,
door.loadno,
nvl(loadstatus.abbrev,''),
nvl(loadtypes.abbrev,'(Available)'),
location.status,
0,
trailer.trailer_number
from door, location, loads, loadstatus, loadtypes, trailer
where door.facility = location.facility
  and door.doorloc = location.locid
  and door.loadno = loads.loadno (+)
  and loads.loadstatus = loadstatus.code (+)
  and loads.loadtype = loadtypes.code (+)
  and door.facility = trailer.facility(+)
  and nvl(door.doorloc, '(none)') = trailer.location(+);

comment on table doorview is '$Id$';

create or replace view doorrankview
(facility
,doorloc
,loadno
,loadstatusabbrev
,loadtypeabbrev
,locationstatus
,ranking
,trailer_number
)
as
select
door.facility,
door.doorloc,
door.loadno,
nvl(loadstatus.abbrev,''),
nvl(loadtypes.abbrev,'(Available)'),
location.status,
nvl(ranking,99999),
trailer.trailer_number
from door, location, loads, loadstatus, loadtypes, door_rankings, trailer
where door.facility = location.facility
  and door.doorloc = location.locid
  and door.loadno = loads.loadno (+)
  and loads.loadstatus = loadstatus.code (+)
  and loads.loadtype = loadtypes.code (+)
  and door.facility = door_rankings.facility(+)
  and door.doorloc = door_rankings.doorloc(+)
  and door.facility = trailer.facility(+)
  and nvl(door.doorloc, '(none)') = trailer.location(+);

exit;
