create or replace view orderhdrdtlview
(
orderid,
shipid,
custid,
po,
orderstatus,
statusupdate,
item,
linestatus,
linenumber,
baseqtyorder,
baseqtyship,
qtyorder,
qtyship
)
as
select
h.orderid,
h.shipid,
h.custid,
h.po,
h.orderstatus,
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
  and h.shipid = d.shipid
  and h.orderstatus = '9'
  and ( (d.linestatus = 'X') or
        (nvl(d.qtyship,0) < nvl(d.qtyorder,0)) );
        
comment on table orderhdrdtlview is '$Id$';
        
--exit;
