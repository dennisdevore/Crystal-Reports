create or replace view masterpalletview
(
mstrlpid,
mstrlpidlabel,
mstritem,
mstritemdesc,
mstrcustid,
mstrlocation,
mstrstatus,
mstrstatusabbrev,
LPID,
ITEM,
CUSTID,
FACILITY,
LOCATION,
STATUS,
UNITOFMEASURE,
QUANTITY,
TYPE,
SERIALNUMBER,
LOTNUMBER,
EXPIRATIONDATE,
EXPIRYACTION,
PO,
RECMETHOD,
CONDITION,
LASTOPERATOR,
LASTTASK,
FIFODATE,
PARENTLPID,
USERITEM1,
USERITEM2,
USERITEM3,
INVSTATUS,
INVENTORYCLASS,
statusabbrev,
unitofmeasureabbrev,
recmethodabbrev,
invstatusabbrev,
inventoryclassabbrev,
itemdescr,
platetypeabbrev,
hazardous,
conditionabbrev,
loadno,
orderid,
shipid,
weight,
plateorshipplate,
controlnumber,
fromlpid,
productgroup
)
as
select
substr(zmp.plate_mstrplt(plate.lpid),1,15),
substr(zmp.plate_mstrplt(plate.lpid),1,15),
substr(zmp.plate_item(zmp.plate_mstrplt(plate.lpid)),1,20),
substr(zit.item_descr(zmp.plate_custid(zmp.plate_mstrplt(plate.lpid)),zmp.plate_item(zmp.plate_mstrplt(plate.lpid))),1,255),
substr(zmp.plate_custid(zmp.plate_mstrplt(plate.lpid)),1,10),
substr(zmp.plate_location(zmp.plate_mstrplt(plate.lpid)),1,10),
substr(zmp.plate_status(zmp.plate_mstrplt(plate.lpid)),1,2),
substr(zlp.platestatus_abbrev(zmp.plate_status(zmp.plate_mstrplt(plate.lpid))),1,12),
plate.LPID,
plate.ITEM,
plate.CUSTID,
plate.FACILITY,
plate.LOCATION,
plate.STATUS,
plate.UNITOFMEASURE,
plate.QUANTITY,
plate.TYPE,
plate.SERIALNUMBER,
plate.LOTNUMBER,
plate.EXPIRATIONDATE,
plate.EXPIRYACTION,
plate.PO,
plate.RECMETHOD,
plate.CONDITION,
plate.LASTOPERATOR,
plate.LASTTASK,
plate.fifodate,
plate.PARENTLPID,
plate.USERITEM1,
plate.USERITEM2,
plate.USERITEM3,
plate.INVSTATUS,
plate.INVENTORYCLASS,
substr(zlp.platestatus_abbrev(plate.status),1,12),
substr(zit.uom_abbrev(plate.unitofmeasure),1,12),
substr(zlp.handlingtype_abbrev(plate.recmethod),1,12),
substr(zlp.invstatus_abbrev(plate.invstatus),1,12),
substr(zlp.inventoryclass_abbrev(plate.inventoryclass),1,12),
substr(zit.item_descr(plate.custid,plate.item),1,255),
substr(zlp.platetype_abbrev(plate.type),1,12),
substr(zci.hazardous_item(plate.custid,plate.item),1,1),
substr(zlp.condition_abbrev(plate.condition),1,12),
plate.loadno,
plate.orderid,
plate.shipid,
plate.weight,
'P',
plate.controlnumber,
null,
custitem.productgroup
from plate, custitem
where plate.custid = custitem.custid (+)
and plate.item = custitem.item (+)
and plate.status not in ('D','P')
and plate.type in 'PA'
union all
select
substr(zmp.shipplate_mstrplt(shippingplate.lpid),1,15),
substr(zmp.shipplate_mstrplt_label(shippingplate.lpid),1,15),
substr(zmp.shipplate_item(zmp.shipplate_mstrplt(shippingplate.lpid)),1,20),
substr(zit.item_descr(zmp.shipplate_custid(zmp.shipplate_mstrplt(shippingplate.lpid)),zmp.shipplate_item(zmp.shipplate_mstrplt(shippingplate.lpid))),1,255),
substr(zmp.shipplate_custid(zmp.shipplate_mstrplt(shippingplate.lpid)),1,10),
substr(zmp.shipplate_location(zmp.shipplate_mstrplt(shippingplate.lpid)),1,10),
substr(zmp.shipplate_status(zmp.shipplate_mstrplt(shippingplate.lpid)),1,2),
substr(zlp.shippingplatestatus_abbrev(zmp.shipplate_status(zmp.shipplate_mstrplt(shippingplate.lpid))),1,12),
shippingplate.LPID,
shippingplate.ITEM,
shippingplate.CUSTID,
shippingplate.FACILITY,
shippingplate.LOCATION,
shippingplate.STATUS,
shippingplate.UNITOFMEASURE,
shippingplate.QUANTITY,
shippingplate.TYPE,
shippingplate.SERIALNUMBER,
shippingplate.LOTNUMBER,
zap.expiration_date(shippingplate.fromlpid),
substr(zap.expiry_action(shippingplate.fromlpid),1,2),
substr(zap.po(shippingplate.fromlpid),1,20),
substr(zap.rec_method(shippingplate.fromlpid),1,2),
substr(zap.condition(shippingplate.fromlpid),1,2),
substr(zap.last_operator(shippingplate.fromlpid),1,12),
substr(zap.last_task(shippingplate.fromlpid),1,2),
zap.fifo_date(shippingplate.fromlpid),
shippingplate.PARENTLPID,
shippingplate.USERITEM1,
shippingplate.USERITEM2,
shippingplate.USERITEM3,
shippingplate.INVSTATUS,
shippingplate.INVENTORYCLASS,
substr(zlp.shippingplatestatus_abbrev(shippingplate.status),1,12),
substr(zit.uom_abbrev(shippingplate.unitofmeasure),1,12),
substr(zlp.handlingtype_abbrev(substr(zap.rec_method(shippingplate.fromlpid),1,2)),1,12),
substr(zlp.invstatus_abbrev(shippingplate.invstatus),1,12),
substr(zlp.inventoryclass_abbrev(shippingplate.inventoryclass),1,12),
substr(zit.item_descr(shippingplate.custid,shippingplate.item),1,255),
substr(zlp.shippingplatetype_abbrev(shippingplate.type),1,12),
substr(zci.hazardous_item(shippingplate.custid,shippingplate.item),1,1),
substr(zlp.condition_abbrev(zap.condition(shippingplate.fromlpid)),1,12),
shippingplate.loadno,
shippingplate.stopno,
shippingplate.shipno,
shippingplate.weight,
'S',
null,
shippingplate.fromlpid,
custitem.productgroup
from shippingplate, custitem
where shippingplate.custid = custitem.custid (+)
  and shippingplate.item = custitem.item (+)
  and shippingplate.status in ('P','S','L')
  and shippingplate.type in ('F','P');
  
comment on table masterpalletview is '$Id';
  
exit;
