CREATE OR REPLACE VIEW ORDERHDRDTLSHIPVIEW ( ORDERID, 
SHIPID, CUSTID, PO, ORDERSTATUS, FACILITY, REFERENCE, IMPORTFILEID, 
STATUSUPDATE, DATESHIPPED, ITEM, LINESTATUS, LINENUMBER, 
BASEQTYORDER, BASEQTYSHIP, QTYORDER, QTYSHIP,
SHIP_COST, TRACKINGNOS
 ) AS select
h.orderid,
h.shipid,
h.custid,
h.po,
h.orderstatus,
h.fromfacility,
h.reference,
h.importfileid,
h.statusupdate,
h.dateshipped,
d.item,
d.linestatus,
d.dtlpassthrunum10,
nvl(d.qtyorder,0),
nvl(d.qtyship,0),
zcu.equiv_uom_qty(h.custid,d.item,zci.baseuom(h.custid,d.item),
  nvl(d.qtyorder,0),d.uomentered),
zcu.equiv_uom_qty(h.custid,d.item,zci.baseuom(h.custid,d.item),
  nvl(d.qtyship,0),d.uomentered),
  nvl(zoe.sum_shipping_cost(h.orderid, h.shipid),0),
  zoe.order_trackingnos(h.orderid, h.shipid)
from orderdtl d, orderhdr h
where h.orderid = d.orderid
  and h.shipid = d.shipid
  and h.orderstatus = '9';

comment on table ORDERHDRDTLSHIPVIEW is '$Id$';

exit;
