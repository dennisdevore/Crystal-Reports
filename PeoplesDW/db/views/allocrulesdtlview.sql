create or replace view allocrulesdtlview
(facility
,allocrule
,priority
,invstatus
,inventoryclass
,uom
,qtymin
,qtymax
,pickingzone
,usefwdpick
,lifofifo
,datetype
,picktoclean
,lastuser
,lastupdate
,invstatusabbrev
,inventoryclassabbrev
,uomabbrev
,datetypeabbrev
,fifolifoabbrev
,zonedescription
)
as
select
allocrulesdtl.facility,
allocrulesdtl.allocrule,
allocrulesdtl.priority,
allocrulesdtl.invstatus,
allocrulesdtl.inventoryclass,
allocrulesdtl.uom,
allocrulesdtl.qtymin,
allocrulesdtl.qtymax,
allocrulesdtl.pickingzone,
allocrulesdtl.usefwdpick,
allocrulesdtl.lifofifo,
allocrulesdtl.datetype,
allocrulesdtl.picktoclean,
allocrulesdtl.lastuser,
allocrulesdtl.lastupdate,
nvl(inventorystatus.abbrev,'All'),
nvl(inventoryclass.abbrev,'All'),
unitsofmeasure.abbrev,
decode(nvl(datetype,'M'),'M','Manufacture',
  'E','Expiration','R','Receipt','L','Lot Number','?'),
decode(nvl(lifofifo,'F'),'F','Fifo','Lifo'),
zone.description
from allocrulesdtl, inventorystatus, inventoryclass,
     unitsofmeasure, zone
where allocrulesdtl.invstatus = inventorystatus.code(+)
and allocrulesdtl.inventoryclass = inventoryclass.code(+)
and allocrulesdtl.uom = unitsofmeasure.code(+)
and allocrulesdtl.facility = zone.facility(+)
and allocrulesdtl.pickingzone = zone.zoneid(+);

comment on table allocrulesdtlview is '$Id$';

exit;
