create or replace view alps.orderdtlrcptview
(orderid
,shipid
,orderitem
,orderlot
,orderlotnull
,facility
,custid
,item
,lotnumber
,uom
,inventoryclass
,invstatus
,lpid
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
,serialnumber
,useritem1
,useritem2
,useritem3
,lastuser
,lastupdate
,inventoryclassabbrev
,invstatusabbrev
,uomabbrev
,reference
,po
,ordertype
)
as
select
 rc.orderid
,rc.shipid
,rc.orderitem
,rc.orderlot
,nvl(rc.orderlot,'**NULL**')
,rc.facility
,rc.custid
,rc.item
,rc.lotnumber
,rc.uom
,rc.inventoryclass
,rc.invstatus
,rc.lpid
,rc.qtyrcvd
,rc.qtyrcvdgood
,rc.qtyrcvddmgd
,rc.serialnumber
,rc.useritem1
,rc.useritem2
,rc.useritem3
,rc.lastuser
,rc.lastupdate
,ic.abbrev
,st.abbrev
,um.abbrev
,oh.reference
,oh.po
,oh.ordertype
from unitsofmeasure um, inventorystatus st, inventoryclass ic,
     orderhdr oh, orderdtlrcpt rc
where rc.orderid = oh.orderid
  and rc.shipid = oh.shipid
  and rc.invstatus = st.code(+)
  and rc.inventoryclass = ic.code(+)
  and rc.uom = um.code(+);

comment on table orderdtlrcptview is '$Id$';

exit;
