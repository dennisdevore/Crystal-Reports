create or replace view hppacklist_order_line
(
orderid,
shipid,
linenumber,
orderitem,
orderlotnumber,
custid,
description,
quantity,
unitofmeasure,
unitamount
)
as
select
OD.orderid,
OD.shipid,
nvl(OL.dtlpassthrunum10,OD.dtlpassthrunum10),
OD.item,
nvl(OD.lotnumber,' '),
OD.custid,
nvl(CI.descr,OD.item),
nvl(OL.qty,nvl(OD.qtypick,0)),
OD.uomentered,
nvl(OL.dtlpassthrunum01,nvl(OD.dtlpassthrunum01,0))
from custitem CI, orderdtlline OL, orderdtl OD
where OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
  and nvl(OL.xdock,'N') = 'N'
  and OD.item = CI.item(+)
  and OD.item not like 'HANDL%';

comment on table hppacklist_order_line is '$Id$';

create or replace view hppacklist_order_line_items
(
orderid,
shipid,
orderitem,
orderlot,
unitofmeasure,
lotnumber,
serialnumber,
trackingno,
quantity
)
as
select
orderid,
shipid,
orderitem,
nvl(orderlot,' '),
unitofmeasure,
lotnumber,
serialnumber,
trackingno,
sum(nvl(quantity,0))
from shippingplate
where type in ('P','F')
group by orderid,shipid,orderitem,orderlot,unitofmeasure,
lotnumber,serialnumber,trackingno;

comment on table hppacklist_order_line_items is '$Id$';

exit;

