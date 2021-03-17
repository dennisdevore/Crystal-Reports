create or replace view receiverdtlview
(
ORDERID,                      
SHIPID,                       
custid,
ITEM,                         
lotnumber,
lotnumbernull,
ITEMENTERED,                  
UOMENTERED,                   
UOMENTEREDdesc,                   
itemdesc,
QTYENTERED,                   
QTYORDER,
WEIGHTORDER,
CUBEORDER,                   
qtyrcvd,
weightrcvd,
cubercvd,
qtyrcvdgood,
weightrcvdgood,
cubercvdgood,
qtyrcvddmgd,
weightrcvddmgd,
cubercvddmgd,
orderdtlrowid
)
as
select
orderdtl.ORDERID,                      
orderdtl.SHIPID,                       
orderdtl.custid,
orderdtl.ITEM,                         
orderdtl.lotnumber,
nvl(orderdtl.lotnumber,'**NULL**'),
ITEMENTERED,
UOMENTERED,
unitsofmeasure.abbrev,                   
custitem.descr,
orderdtl.QTYENTERED,
orderdtl.QTYORDER,
orderdtl.WEIGHTORDER,
orderdtl.CUBEORDER,                   
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvd,orderdtl.uomentered),
weightrcvd,
cubercvd,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvdgood,orderdtl.uomentered),
weightrcvdgood,
cubercvdgood,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
  qtyrcvddmgd,orderdtl.uomentered),
weightrcvddmgd,
cubercvddmgd,
orderdtl.rowid
from orderdtl, unitsofmeasure, custitem
where orderdtl.uomentered = unitsofmeasure.code (+)
  and orderdtl.custid = custitem.custid (+)
  and orderdtl.item = custitem.item (+)
  and linestatus = 'A';

comment on table receiverdtlview is '$Id';
  
create or replace view pacam_receiverdtlview
(
ORDERID,                      
SHIPID,                       
custid,
ITEM,                         
lotnumber,
lotnumbernull,
ITEMENTERED,                  
UOMENTEREDdesc,                   
itemdesc,
QTYENTERED,                   
WEIGHTORDER,
qtyrcvd,
weightrcvd,
qtyrcvdgood,
weightrcvdgood,
qtyrcvddmgd,
weightrcvddmgd,
orderdtlrowid,
barcodeitem,
barcodelot
)
as
select
orderdtl.ORDERID,                      
orderdtl.SHIPID,                       
orderdtl.custid,
orderdtl.ITEM,                         
orderdtl.lotnumber,
nvl(orderdtl.lotnumber,'**NULL**'),
ITEMENTERED,                  
unitsofmeasure.abbrev,                   
custitem.descr,
orderdtl.QTYENTERED,                   
orderdtl.WEIGHTORDER,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvd,orderdtl.uomentered),
weightrcvd,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvdgood,orderdtl.uomentered),
weightrcvdgood,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
  qtyrcvddmgd,orderdtl.uomentered),
weightrcvddmgd,
orderdtl.rowid,
replace(orderdtl.ITEM,'/0','/'),
replace(orderdtl.lotnumber,'/0','/')
from orderdtl, unitsofmeasure, custitem
where orderdtl.uomentered = unitsofmeasure.code (+)
  and orderdtl.custid = custitem.custid (+)
  and orderdtl.item = custitem.item (+)
  and linestatus = 'A';

comment on table pacam_receiverdtlview is '$Id';
  
create or replace view pho_receiverdtlview
(
ORDERID,                      
SHIPID,                       
custid,
ITEM,                         
lotnumber,
lotnumbernull,
ITEMENTERED,                  
UOMENTERED,                   
UOMENTEREDdesc,                   
itemdesc,
QTYENTERED,                   
QTYORDER,
QTYORDERPCS,
QTYORDERCTN,
WEIGHTORDER,
CUBEORDER,                   
qtyrcvd,
qtyrcvdpcs,
qtyrcvdctn,
weightrcvd,
cubercvd,
qtyrcvdgood,
qtyrcvdgoodpcs,
qtyrcvdgoodctn,
weightrcvdgood,
cubercvdgood,
qtyrcvddmgd,
qtyrcvddmgdpcs,
qtyrcvddmgdctn,
weightrcvddmgd,
cubercvddmgd,
pcs_per_ctn,
orderdtlrowid
)
as
select
orderdtl.ORDERID,                      
orderdtl.SHIPID,                       
orderdtl.custid,
orderdtl.ITEM,                         
orderdtl.lotnumber,
nvl(orderdtl.lotnumber,'**NULL**'),
ITEMENTERED,
UOMENTERED,
unitsofmeasure.abbrev,                   
custitem.descr,
orderdtl.QTYENTERED,
orderdtl.QTYORDER,
zlbl.uom_qty_conv(orderdtl.custid,orderdtl.itementered,orderdtl.QTYORDER,orderdtl.uom,'PCS'),
zlbl.uom_qty_conv(orderdtl.custid,orderdtl.itementered,orderdtl.QTYORDER,orderdtl.uom,'CTN'),
orderdtl.WEIGHTORDER,
orderdtl.CUBEORDER,                   
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvd,orderdtl.uomentered),
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvd,'PCS'),
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvd,'CTN'),
weightrcvd,
cubercvd,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvdgood,orderdtl.uomentered),
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvdgood,'PCS'),
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
    qtyrcvdgood,'CTN'),
weightrcvdgood,
cubercvdgood,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
  qtyrcvddmgd,orderdtl.uomentered),
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
  qtyrcvddmgd,'PCS'),
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
  qtyrcvddmgd,'CTN'),
weightrcvddmgd,
cubercvddmgd,
zlbl.uom_qty_conv(orderdtl.custid,orderdtl.itementered,1,'CTN','PCS'),
orderdtl.rowid
from orderdtl, unitsofmeasure, custitem
where orderdtl.uomentered = unitsofmeasure.code (+)
  and orderdtl.custid = custitem.custid (+)
  and orderdtl.item = custitem.item (+)
  and linestatus = 'A';

comment on table pho_receiverdtlview is '$Id';
  
exit;
