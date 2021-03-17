--
-- $Id$
--
create or replace view asofinvdtlview
(custid
,facility
,effdate
,trantype
,reason
,orderid
,shipid
,item
,lotnumber
,invstatus
,inventoryclass
,qty
)
as
select
ao.custid,
ao.facility,
ao.effdate,
ao.trantype,
ao.reason,
sp.orderid,
sp.shipid,
sp.item,
sp.lotnumber,
sp.invstatus,
sp.inventoryclass,
nvl(sp.quantity,0) * -1
from shippingplate sp, orderhdr oh, asofinventorydtl ao
where ao.trantype = 'SH'
and ao.effdate = trunc(oh.statusupdate)
and ao.facility = oh.fromfacility
and ao.custid = oh.custid
and oh.orderid = sp.orderid
and oh.shipid = sp.shipid
and sp.item = ao.item
and nvl(sp.lotnumber,'x') = nvl(ao.lotnumber,'x')
and sp.invstatus = ao.invstatus
and sp.inventoryclass = ao.inventoryclass
and sp.type in ('F','P');
--exit;
