create or replace view itempickfrontsview
(CUSTID,
ITEM,
FACILITY,
PICKFRONT,
PICKUOM,
REPLENISHQTY,
REPLENISHUOM,
MAXQTY,
MAXUOM,
REPLENISHWITHUOM,
LASTUSER,
LASTUPDATE,
pickuomabbrev,
replenishuomabbrev,
maxuomabbrev,
replenishwithuomabbrev,
facilityname,
locationstatus,
topoffqty,
topoffuom,
topoffuomabbrev,
pickingzone,
dynamic,
inventoryclass
)
as
select
itempickfronts.CUSTID,
itempickfronts.ITEM,
itempickfronts.FACILITY,
itempickfronts.PICKFRONT,
itempickfronts.PICKUOM,
itempickfronts.REPLENISHQTY,
itempickfronts.REPLENISHUOM,
itempickfronts.MAXQTY,
itempickfronts.MAXUOM,
itempickfronts.REPLENISHWITHUOM,
itempickfronts.LASTUSER,
itempickfronts.LASTUPDATE,
substr(zit.uom_abbrev(itempickfronts.pickuom),1,12),
substr(zit.uom_abbrev(itempickfronts.replenishuom),1,12),
substr(zit.uom_abbrev(itempickfronts.maxuom),1,12),
substr(zit.uom_abbrev(itempickfronts.replenishwithuom),1,12),
facility.name,
location.status,
nvl(itempickfronts.topoffQTY,0),
itempickfronts.topoffUOM,
substr(zit.uom_abbrev(itempickfronts.topoffuom),1,12),
location.pickingzone,
itempickfronts.dynamic,
itempickfronts.inventoryclass
from facility, location, itempickfronts
where itempickfronts.facility = facility.facility (+)
  and itempickfronts.facility = location.facility (+)
  and itempickfronts.pickfront = location.locid (+);

comment on table itempickfrontsview is '$Id$';

exit;
