CREATE OR REPLACE VIEW ZEN_RPT_RECEIVERDTLVIEW
(ORDERID, SHIPID, CUSTID, ITEM, LOTNUMBER, 
 ITEMENTERED, UOMENTEREDDESC, ITEMDESC, QTYENTERED, WEIGHTORDER, 
 QTYRCVD, WEIGHTRCVD, QTYRCVDGOOD, WEIGHTRCVDGOOD, QTYRCVDDMGD, 
 WEIGHTRCVDDMGD, ORDERDTLROWID, BASEQTY, BASEUOMDESC)
AS 
select
orderdtl.ORDERID,
orderdtl.SHIPID,
orderdtl.custid,
orderdtl.ITEM,
orderdtl.lotnumber,
ITEMENTERED,
uom1.abbrev,
custitem.descr,
orderdtl.QTYENTERED,
orderdtl.WEIGHTORDER,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,qtyrcvd,orderdtl.uomentered),
weightrcvd,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,qtyrcvdgood,orderdtl.uomentered),
weightrcvdgood,
zcu.equiv_uom_qty(orderdtl.custid,orderdtl.item,orderdtl.uom,qtyrcvddmgd,orderdtl.uomentered),
weightrcvddmgd,
orderdtl.rowid,
zlbl.uom_qty_conv(orderdtl.custid,orderdtl.item,orderdtl.qtyentered,orderdtl.uomentered,custitem.baseuom), 
uom2.abbrev
from orderdtl, unitsofmeasure uom1, custitem, unitsofmeasure uom2
where orderdtl.uomentered = uom1.code (+)
  and orderdtl.custid = custitem.custid (+)
  and orderdtl.item = custitem.item (+)
  and custitem.baseuom = uom2.code (+)
  and linestatus = 'A';

comment on table zen_rpt_receiverdtlview is '$Id$';        

exit;

