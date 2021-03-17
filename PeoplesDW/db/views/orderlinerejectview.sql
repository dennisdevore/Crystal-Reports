create or replace view orderlinerejectview
(
orderid,
shipid,
item,
lotnumber,
linenumber,
cancelreason,
uomcancel,
qtycancel
)
as
select
oh.orderid,
oh.shipid,
od.item,
od.lotnumber,
nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)),
nvl(od.cancelreason,oh.cancelreason),
decode(
mod(zcu.equiv_uom_qty(oh.custid,od.item,od.uom,nvl(ol.qty,od.qtyorder),od.uomentered),1),
0,od.uomentered,od.uom),
decode(
mod(zcu.equiv_uom_qty(oh.custid,od.item,od.uom,nvl(ol.qty,od.qtyorder),od.uomentered),1),
0,zcu.equiv_uom_qty(oh.custid,od.item,od.uom,nvl(ol.qty,od.qtyorder),od.uomentered),
nvl(ol.qty,od.qtyorder))
from orderdtlline ol, orderdtl od, orderhdr oh
where oh.orderid = od.orderid
and oh.shipid = od.shipid
and OD.orderid = OL.orderid(+)
and OD.shipid = OL.shipid(+)
and OD.item = OL.item(+)
and nvl(OL.xdock,'N') = 'N'
and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
and od.linestatus = 'X';

comment on table orderlinerejectview is '$Id$';

exit;

