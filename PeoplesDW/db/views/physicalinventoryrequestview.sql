create or replace view physicalinventoryrequestview
(
    facility,
    location,
    status,
    statusabbrev,
    item,
    uom,
    lpid,
    quantity,
    lotnumber,
    custid,
    velocity,
    itemdescr,
    pickingzone
)
as
select
    L.facility,
    L.locid,
    L.locationstatus,
    L.locationstatusabbrev,
    V.item,
    V.unitofmeasure,
    V.lpid,
    V.quantity,
    V.lotnumber,
    V.custid,
    L.velocity,
    V.itemdescr,
    L.pickingzone
from locationview L, plateview V
where L.facility = V.facility (+)
  and L.locid = V.location (+)
  and L.loctype in ('STO','PF');

comment on table physicalinventoryrequestview is '$Id$';

exit;
