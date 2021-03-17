create or replace view laborstandardsview
(
FACILITY,
CUSTID,
CATEGORY,
ZONEID,
UOM,
qtyperhour,
LASTUSER,
LASTUPDATE,
CATEGORYABBREV,
ZONEIDABBREV,
UOMABBREV
)
as
select
laborstandards.facility,
laborstandards.custid,
laborstandards.category,
laborstandards.zoneid,
laborstandards.uom,
laborstandards.qtyperhour,
laborstandards.lastuser,
laborstandards.lastupdate,
employeeactivities.abbrev,
zone.abbrev,
unitsofmeasure.abbrev
from laborstandards, zone, employeeactivities, unitsofmeasure
where laborstandards.facility = zone.facility (+)
  and laborstandards.zoneid = zone.zoneid (+)
  and laborstandards.category = employeeactivities.code (+)
  and laborstandards.uom = unitsofmeasure.code (+);
  
comment on table laborstandardsview is '$Id';
  
exit;
