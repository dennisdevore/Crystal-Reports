create or replace view replenishreqview
(
FACILITY,
PICKFRONT,
STATUS,
STATUSABBREV,
CUSTID,
ITEM,
pickingzone,
aisle,
section,
locbasebal,
taskbasebal,
topoffbaseqty
)
as
select
i.FACILITY,
i.pickfront,
l.LOCATIONSTATUS,
l.LOCATIONSTATUSABBREV,
i.custid,
i.ITEM,
l.pickingzone,
l.aisle,
l.section,
zrpl.loc_balance(i.facility,i.custid,i.item,i.pickfront),
zrpl.task_balance(i.facility,i.custid,i.item,i.pickfront),
zci.item_base_qty(i.custid,i.item,i.topoffuom,i.topoffqty)
from itempickfronts i, locationview l
where i.facility = l.facility (+)
and i.pickfront = l.locid (+)
and l.locationstatus != 'O'
and nvl(i.dynamic,'N') = 'N';

comment on table replenishreqview is '$Id';

exit;
