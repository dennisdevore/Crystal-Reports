create or replace view f_user_history as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.endtime Modification_Time,
  a.nameid as user_id,
  a.event as event,
  b.abbrev as event_desc,
  a.facility,
  a.custid as customer,
  a.equipment,
  c.abbrev as equipment_desc,
  a.begtime as begin_time,
  a.endtime as end_time,
  a.orderid,
  a.shipid,
  a.location,
  a.lpid,
  a.item,
  a.units as quantity,
  a.weight,
  a.uom as unit_of_measure,
  a.baseuom as base_unit_of_measure
from alps.userhistory a, alps.employeeactivities b, alps.equipmenttypes c
where a.event = b.code(+) and a.equipment = c.code(+)
  and a.endtime is not null;