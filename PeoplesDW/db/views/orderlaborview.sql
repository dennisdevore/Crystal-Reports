create or replace view orderlaborview
(
WAVE,
ORDERID,
SHIPID,
ITEM,
LOTNUMBER,
CATEGORY,
ZONEID,
UOM,
QTY,
categoryabbrev,
custid,
staffhours,
facility
)
as
select
orderlabor.WAVE,
orderlabor.ORDERID,
orderlabor.SHIPID,
orderlabor.ITEM,
orderlabor.LOTNUMBER,
orderlabor.CATEGORY,
orderlabor.ZONEID,
orderlabor.UOM,
orderlabor.QTY,
employeeactivities.abbrev,
orderlabor.custid,
orderlabor.staffhrs,
orderlabor.facility
from orderlabor, employeeactivities
where orderlabor.category = employeeactivities.code(+)
;

comment on table orderlaborview is '$Id$';

exit;
