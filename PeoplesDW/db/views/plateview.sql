create or replace view plateview
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
weight_kgs,
anvdate,
cube,
lotnumbernotnull
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
plate.FIFODATE,
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
zwt.from_lbs_to_kgs(plate.custid,plate.weight),
plate.anvdate,
decode(plate.type,'PA',plate.quantity * zci.item_cube(plate.custid,plate.item,plate.unitofmeasure),
       'MP',(select sum(nvl(pp.quantity * zci.item_cube(pp.custid,pp.item,pp.unitofmeasure),0))
                     from plate pp
                     where type = 'PA'
                     start with pp.lpid = plate.lpid
                     connect by prior lpid = parentlpid),0),
nvl(plate.lotnumber,'(none)')
from plate, custitem
where plate.custid = custitem.custid (+)
and plate.item = custitem.item (+);

comment on table plateview is '$Id$';

create or replace view pho_plateview
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
weight_kgs,
cube,
quantitypcs,
quantityctn,
rcvddate
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
plate.FIFODATE,                     
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
zwt.from_lbs_to_kgs(plate.custid,plate.weight),
nvl(zlbl.uom_qty_conv(custitem.custid, custitem.item, nvl(plate.QUANTITY,0), plate.UNITOFMEASURE, custitem.baseuom),0) * custitem.cube,
nvl(zlbl.uom_qty_conv(custitem.custid, custitem.item, nvl(plate.QUANTITY,0), plate.UNITOFMEASURE, 'PCS'),0),
nvl(zlbl.uom_qty_conv(custitem.custid, custitem.item, nvl(plate.QUANTITY,0), plate.UNITOFMEASURE, 'CTN'),0),
(select max(asofinventorydtl.effdate)
   from asofinventorydtl
  where asofinventorydtl.facility = plate.facility
    and asofinventorydtl.custid = plate.custid
    and asofinventorydtl.item = plate.item
    and nvl(asofinventorydtl.lotnumber,'(none)') = nvl(plate.lotnumber,'(none)')
    and asofinventorydtl.uom = plate.unitofmeasure
    and nvl(asofinventorydtl.inventoryclass,'(none)') = nvl(plate.inventoryclass,'(none)')
    and nvl(asofinventorydtl.invstatus,'(none)') = nvl(plate.invstatus,'(none)')
    and asofinventorydtl.lpid = plate.lpid
    and asofinventorydtl.trantype = 'RC')
from plate, custitem
where plate.custid = custitem.custid (+)
and plate.item = custitem.item (+);

comment on table pho_plateview is '$Id$';

exit;
