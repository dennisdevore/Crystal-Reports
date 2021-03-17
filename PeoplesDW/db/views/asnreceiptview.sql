create or replace view asnreceiptview
(orderid
,shipid
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
,qtyrcvd
,asntrackingno
,asncustreference
,asnqtyorder
)
as
select
rc.orderid,
rc.shipid,
rc.item,
rc.lotnumber,
rc.serialnumber,
rc.useritem1,
rc.useritem2,
rc.useritem3,
rc.qtyrcvd,
asn.trackingno,
asn.custreference,
nvl(asn.qty,0)
from asncartondtl asn, orderdtlrcptsumview rc
where rc.orderid = asn.orderid (+)
  and rc.shipid = asn.shipid (+)
  and rc.item = asn.item (+)
  and nvl(rc.lotnumber,'x') = nvl(asn.lotnumber(+),'x')
  and nvl(rc.serialnumber,'x') = nvl(asn.serialnumber(+),'x')
  and nvl(rc.useritem1,'x') = nvl(asn.useritem1(+),'x')
  and nvl(rc.useritem2,'x') = nvl(asn.useritem2(+),'x')
  and nvl(rc.useritem3,'x') = nvl(asn.useritem3(+),'x');

comment on table asnreceiptview is '$Id$';

exit;
