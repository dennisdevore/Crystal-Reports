create or replace view userhistoryview
(
NAMEID,
begtime,
event,
endtime,
facility,
custid,
equipment,
units,
etc,
equipmentabbrev,
eventabbrev,
orderid,
shipid,
location,
lpid,
item,
uom,
baseuom,
baseunits,
cube,
weight,
employeecost,
equipmentcost
)
as
select
NAMEID,
begtime,
event,
endtime,
facility,
custid,
equipment,
units,
etc,
equipmenttypes.abbrev,
employeeactivities.abbrev,
orderid,
shipid,
location,
lpid,
substr(decode(zci.item_code(custid, item),'Unknown',item,zci.item_code(custid,item)),1,20),
uom,
baseuom,
baseunits,
cube,
weight,
employeecost,
equipmentcost
from userhistory,
     equipmenttypes,
     employeeactivities
where userhistory.equipment = equipmenttypes.code(+)
and userhistory.event = employeeactivities.code(+);

comment on table userhistoryview is '$Id$';

create or replace view userhistoryactivityview
(
nameid,
begtime,
event,
endtime,
facility,
custid,
equipment,
units,
etc,
equipmentabbrev,
eventabbrev,
orderid,
shipid,
location,
lpid,
item,
uom,
baseuom,
baseunits,
cube,
weight,
employeecost,
equipmentcost
)
as
select
nameid,
begtime,
decode(event,'1LIP','1STP','ALIP','ASNR','LPLD','DKLD','LPUL','DKUL','PICK',nvl(etc,'PICK'),event),
endtime,
facility,
custid,
equipment,
units,
etc,
equipmentabbrev,
ea.abbrev,
orderid,
shipid,
location,
lpid,
item,
uom,
baseuom,
baseunits,
cube,
weight,
employeecost,
equipmentcost
from userhistoryview uhv,
     employeeactivities ea
where event not in ('1STP', 'ASNR', 'BADT', 'BAPK', 'CLIP', 'CLPK', 'CSPK', 'DKLD', 'DKUL', 'MIPK', 'RPPK', 'SOPK', 'STPK', 'SYPK')
and decode(event,'1LIP','1STP','ALIP','ASNR','LPLD','DKLD','LPUL','DKUL','PICK',nvl(etc,'PICK'),event) = ea.code (+)
and (event <> '1LIP'
or orderid <> 0);

comment on table userhistoryactivityview is '$Id$';

exit;
