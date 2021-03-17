create or replace view inventorylipview
(
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
masterlpidlabel,
masterlpid,
trackingno,
productgroup,
lastuser,
lastupdate
)
as
select
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
plate.fromlpid,
substr(zmp.plate_mstrplt(plate.lpid),1,15),
substr(zmp.plate_mstrplt(plate.lpid),1,15),
null,
custitem.productgroup,
plate.lastuser,
plate.lastupdate
from plate, custitem
where plate.custid = custitem.custid (+)
and plate.item = custitem.item (+)
and plate.status not in ('D','P','I')
and plate.type = 'PA'
union all
select
shippingplate.fromLPID,
shippingplate.ITEM,
shippingplate.CUSTID,
shippingplate.openFACILITY,
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
0,
0,
0,
shippingplate.weight,
'S',
null,
shippingplate.fromlpid,
substr(zmp.shipplate_mstrplt_label(shippingplate.lpid),1,15),
substr(zmp.shipplate_mstrplt(shippingplate.lpid),1,15),
trackingno,
custitem.productgroup,
shippingplate.lastuser,
shippingplate.lastupdate
from facility, custitem, shippingplate
where shippingplate.custid = custitem.custid (+)
  and shippingplate.item = custitem.item (+)
  and shippingplate.status in ('P','S','L','FA')
  and shippingplate.type in ('F','P')
  and shippingplate.openfacility = facility.facility;
  
comment on table inventorylipview is '$Id: inventorylipview.sql 1 2007-05-16 12:20:03Z  $';
  
exit;