create or replace view asncartondtlview
(orderid
,shipid
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
,inventoryclass
,uom
,qty
,trackingno
,custreference
,importfileid
,created
,lastuser
,lastupdate
,inventoryclassabbrev
,uomabbrev
,reference
,custid
,facility
,expdate
)
as
select
 ac.orderid
,ac.shipid
,ac.item
,ac.lotnumber
,ac.serialnumber
,ac.useritem1
,ac.useritem2
,ac.useritem3
,ac.inventoryclass
,ac.uom
,ac.qty
,ac.trackingno
,ac.custreference
,ac.importfileid
,ac.created
,ac.lastuser
,ac.lastupdate
,ic.abbrev
,um.abbrev
,oh.reference
,oh.custid
,oh.tofacility
,ac.expdate
from unitsofmeasure um, inventoryclass ic,
     orderhdr oh, asncartondtl ac
where ac.orderid = oh.orderid
  and ac.shipid = oh.shipid
  and ac.uom = um.code(+)
  and ac.inventoryclass = ic.code(+);
  
comment on table asncartondtlview is '$Id$';
  
--exit;
