create or replace view whutilizationrptview
(
Facility,
LocID,
LocType,
Status,
LPCount,
UnitOFStorage,
Section,
Aisle,
PickingZone,
PutawayZone,
StackHeight,
WeightLimit,
DropCount,
PickCount,
location_footprint,
location_hazmat,
location_tempcontrolled
)
as
select
Location.Facility,
Location.LocID, 
Location.LocType,
Location.Status,
Location.LPCount,
Location.UnitOFStorage,   
Location.Section,   
Location.Aisle,
Location.PickingZone,
Location.PutawayZone,   
Location.StackHeight,
Location.WeightLimit,
Location.DropCount,
Location.PickCount,
Whutilizationrptpkg.location_footprint(Location.Facility, Location.LocID),
Whutilizationrptpkg.location_hazmat(Location.Facility, Location.LocID),
Whutilizationrptpkg.location_tempcontrolled(Location.Facility, Location.LocID)
from Location
where Location.Loctype in ('STO', 'PF')
and Location.Status <> 'O';

comment on table whutilizationrptview is '$Id: whutilizationrptview.sql 4600 2015-03-18 12:37:15Z ayuan $';
                 
exit;
