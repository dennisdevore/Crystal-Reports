create or replace view asofinvhdrbegview
(custid
,facility
,effdate
,item
,itemdesc
,invstatus
,inventoryclass
,beg_bal
,truelink
,lotnumber
)
as
select
ao.custid,
ao.facility,
ao.effdate,
ao.item,
nvl(ci.descr,ao.item),
ao.invstatus,
ao.inventoryclass,
sum(ao.previousqty),
1,
ao.lotnumber
from custitem ci, asofinventory ao
where ao.custid = ci.custid(+)
  and ao.item = ci.item(+)
group by ao.custid,ao.facility,ao.effdate,ao.item,nvl(ci.descr,ao.item),
         ao.invstatus,ao.inventoryclass,ao.lotnumber;

comment on table asofinvhdrbegview is '$Id$';


create or replace view asofinvhdrendview
(custid
,facility
,effdate
,item
,itemdesc
,invstatus
,inventoryclass
,end_bal
,lotnumber
)
as
select
ao.custid,
ao.facility,
ao.effdate,
ao.item,
nvl(ci.descr,ao.item),
ao.invstatus,
ao.inventoryclass,
sum(ao.currentqty),
ao.lotnumber
from custitem ci, asofinventory ao
where ao.custid = ci.custid(+)
  and ao.item = ci.item(+)
group by ao.custid,ao.facility,ao.effdate,ao.item,nvl(ci.descr,ao.item),
         ao.invstatus,ao.inventoryclass,ao.lotnumber;

comment on table asofinvhdrendview is '$Id$';

create or replace view asofinvdtlview
(custid
,facility
,effdate
,trantype
,reason
,consignee_or_supplier
,consignee_or_supplier_name
,orderid
,shipid
,item
,invstatus
,inventoryclass
,qty
,lotnumber
)
as
select
ao.custid,
ao.facility,
ao.effdate,
ao.trantype,
ao.reason,
oh.consignee,
nvl(cn.name,oh.shiptoname),
sp.orderid,
sp.shipid,
sp.item,
sp.invstatus,
sp.inventoryclass,
sum(nvl(sp.quantity,0) * -1),
ao.lotnumber
from consignee cn, shippingplate sp, orderhdr oh, asofinventorydtl ao
where ao.trantype = 'SH'
and ao.effdate = trunc(oh.statusupdate)
and ao.facility = oh.fromfacility
and ao.custid = oh.custid
and oh.orderid = sp.orderid
and oh.shipid = sp.shipid
and ao.item = sp.item
and nvl(ao.lotnumber,'x') = nvl(sp.lotnumber,'x')
and ao.invstatus = sp.invstatus
and ao.inventoryclass = sp.inventoryclass
and sp.type in ('F','P')
and oh.consignee = cn.consignee(+)
group by ao.custid, ao.facility, ao.effdate, ao.trantype,
         ao.reason,oh.consignee,nvl(cn.name,oh.shiptoname),
         sp.orderid,sp.shipid,
         sp.item,sp.invstatus,sp.inventoryclass,ao.lotnumber
union
select
ao.custid,
ao.facility,
ao.effdate,
ao.trantype,
ao.reason,
oh.shipper,
nvl(sh.name,oh.shippername),
rc.orderid,
rc.shipid,
rc.item,
rc.invstatus,
rc.inventoryclass,
sum(rc.qtyrcvd),
ao.lotnumber
from shipper sh, loads ld, orderdtlrcpt rc, orderhdr oh, asofinventorydtl ao
where ao.trantype = 'RC'
and ao.effdate = trunc(ld.rcvddate)
and ao.facility = oh.tofacility
and ao.custid = oh.custid
and oh.loadno = ld.loadno
and ld.loadtype in ('INC','INT')
and oh.orderid = rc.orderid
and oh.shipid = rc.shipid
and ao.item = rc.item
and nvl(ao.lotnumber,'x') = nvl(rc.lotnumber,'x')
and oh.shipper = sh.shipper(+)
group by ao.custid, ao.facility, ao.effdate, ao.trantype,
         ao.reason, oh.shipper, nvl(sh.name,oh.shippername),
         rc.orderid, rc.shipid,
         rc.item, rc.invstatus, rc.inventoryclass, ao.lotnumber
union
select
ao.custid,
ao.facility,
ao.effdate,
ao.trantype,
ao.reason,
null,
null,
0,
0,
ia.item,
ia.invstatus,
ia.inventoryclass,
sum(ia.adjqty),
ia.lotnumber
from invadjactivity ia, asofinventorydtl ao
where ao.trantype = 'AD'
  and ao.effdate = trunc(ia.whenoccurred)
  and ao.facility = ia.facility
  and ao.custid = ia.custid
  and ao.item = ia.item
  and nvl(ao.lotnumber,'x') = nvl(ia.lotnumber,'x')
group by ao.custid, ao.facility, ao.effdate, ao.trantype,
         ao.reason, null, null, 0, 0,
         ia.item, ia.invstatus, ia.inventoryclass, ia.lotnumber;
         
comment on table asofinvdtlview is '$Id$';
         
exit;
