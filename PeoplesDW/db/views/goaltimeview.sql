create or replace view goaltimeview
(
FACILITY,
CUSTID,
CATEGORY,
CATEGORYABBREV,
MEASURE,
QTYPERHOUR,
UOM,
UOMABBREV,
LASTUSER,
LASTUPDATE
)
as
select
goaltime.facility,
goaltime.custid,
goaltime.category,
employeeactivities.abbrev,
goaltime.measure,
goaltime.qtyperhour,
goaltime.uom,
unitsofmeasure.abbrev,
goaltime.lastuser,
goaltime.lastupdate
from goaltime, employeeactivities, unitsofmeasure
where goaltime.category = employeeactivities.code (+)
  and goaltime.uom = unitsofmeasure.code (+);
  
comment on table goaltimeview is '$Id$';
  
exit;
