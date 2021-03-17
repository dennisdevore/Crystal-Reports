CREATE OR REPLACE VIEW DRE_RECEIVERDTLVIEW
(ORDERID, SHIPID, CUSTID, ITEM, LOTNUMBER, 
 ITEMENTERED, UOMENTEREDDESC, ITEMDESC, QTYENTERED, WEIGHTORDER, 
 QTYRCVD, WEIGHTRCVD, QTYRCVDGOOD, WEIGHTRCVDGOOD, QTYRCVDDMGD, 
 WEIGHTRCVDDMGD, ORDERDTLROWID, MFG_DATE, EXP_DATE, USERITEM1, 
 BASEUOMENTEREDDESC, BASEQTYENTERED, BASEQTYRCVDGOOD, BASEQTYRCVDDMGD, PLTQTYENTERED, 
 PLTQTYRCVDGOOD, PLTQTYRCVDDMGD, GWEIGHTRCVD, LINEORDER)
AS 
select
orderdtl.ORDERID,
orderdtl.SHIPID,
orderdtl.custid,
orderdtl.ITEM,
orderdtl.lotnumber,
orderdtl.ITEMENTERED,
uom1.abbrev,
custitem.descr,
nvl(orderdtl.QTYENTERED,0),
orderdtl.WEIGHTORDER,
nvl(zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
orderdtl.qtyrcvd,orderdtl.uomentered),0),
weightrcvd,
nvl(zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
qtyrcvdgood,orderdtl.uomentered),0),
weightrcvdgood,
nvl(zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,
qtyrcvddmgd,orderdtl.uomentered),0),
weightrcvddmgd,
orderdtl.rowid,
dre_asofinvactlotPKG.get_mfgdate(orderdtl.custid,orderdtl.item,orderdtl.lotnumber),
dre_asofinvactlotPKG.get_expdate(orderdtl.custid,orderdtl.item,orderdtl.lotnumber),
dre_asofinvactlotPKG.get_useritem(orderdtl.custid,orderdtl.item,orderdtl.lotnumber),
uom2.abbrev,
nvl(zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyentered,orderdtl.uomentered,custitem.baseuom),0),
nvl(zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyrcvdgood,orderdtl.uomentered,custitem.baseuom),0),
nvl(zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyrcvddmgd,orderdtl.uomentered,custitem.baseuom),0),
nvl(zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyentered,orderdtl.uomentered,'PLT'),0),
nvl(zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyrcvdgood,orderdtl.uomentered,'PLT'),0),
nvl(zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyrcvddmgd,orderdtl.uomentered,'PLT'),0),
weightrcvd + (zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyrcvd,orderdtl.uom,custitem.baseuom) * nvl(custitem.tareweight,0)),
orderdtl.lineorder
from orderdtl, unitsofmeasure uom1, unitsofmeasure uom2, custitem
where orderdtl.uomentered = uom1.code (+)
and custitem.baseuom = uom2.code (+)
and orderdtl.custid = custitem.custid (+)
and orderdtl.item = custitem.item (+)
and linestatus = 'A';
exit;
/
