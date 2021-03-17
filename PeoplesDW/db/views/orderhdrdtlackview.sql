CREATE OR REPLACE VIEW ORDERHDRDTLACKVIEW ( ORDERID, 
SHIPID, CUSTID, PO, ORDERSTATUS, FACILITY, REFERENCE, IMPORTFILEID, 
STATUSUPDATE, ITEM, LINESTATUS, LINENUMBER, 
BASEQTYORDER, BASEQTYSHIP, QTYORDER, QTYSHIP
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
d.item,
d.linestatus,
d.dtlpassthrunum10,
nvl(d.qtyorder,0),
nvl(d.qtyship,0),
zcu.equiv_uom_qty(h.custid,d.item,zci.baseuom(h.custid,d.item),
  nvl(d.qtyorder,0),d.uomentered),
zcu.equiv_uom_qty(h.custid,d.item,zci.baseuom(h.custid,d.item),
  nvl(d.qtyship,0),d.uomentered)
from orderdtl d, orderhdr h
where h.orderid = d.orderid
  and h.shipid = d.shipid;

comment on table ORDERHDRDTLACKVIEW is '$Id$';

exit;
