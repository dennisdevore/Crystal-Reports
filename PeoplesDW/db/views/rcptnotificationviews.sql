-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zimp.begin_rcpt_note/zimp.end_rcpt_note
CREATE OR REPLACE VIEW ALPS.rcptnote_hdr
(custid
,company
,warehouse
,orderid
,shipid
,receiptdate
,vendor
,vendordesc
,billoflading
,carrier
,po
,ordertype
,HDRPASSTHRUCHAR01
,HDRPASSTHRUCHAR02
,HDRPASSTHRUCHAR03
,HDRPASSTHRUCHAR04
,HDRPASSTHRUCHAR05
,HDRPASSTHRUCHAR06
,HDRPASSTHRUCHAR07
,HDRPASSTHRUCHAR08
,HDRPASSTHRUCHAR09
,HDRPASSTHRUCHAR10
,HDRPASSTHRUCHAR11
,HDRPASSTHRUCHAR12
,HDRPASSTHRUCHAR13
,HDRPASSTHRUCHAR14
,HDRPASSTHRUCHAR15
,HDRPASSTHRUCHAR16
,HDRPASSTHRUCHAR17
,HDRPASSTHRUCHAR18
,HDRPASSTHRUCHAR19
,HDRPASSTHRUCHAR20
,HDRPASSTHRUNUM01
,HDRPASSTHRUNUM02
,HDRPASSTHRUNUM03
,HDRPASSTHRUNUM04
,HDRPASSTHRUNUM05
,HDRPASSTHRUNUM06
,HDRPASSTHRUNUM07
,HDRPASSTHRUNUM08
,HDRPASSTHRUNUM09
,HDRPASSTHRUNUM10
,HDRPASSTHRUDATE01
,HDRPASSTHRUDATE02
,HDRPASSTHRUDATE03
,HDRPASSTHRUDATE04
,HDRPASSTHRUDOLL01
,HDRPASSTHRUDOLL02
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
)
as
select
oh.custid,
rc.inventoryclass,
rc.inventoryclass,
oh.orderid,
oh.shipid,
oh.statusupdate,
oh.shipper,
sh.name,
oh.billoflading,
oh.carrier,
oh.po,
oh.ordertype,
oh.HDRPASSTHRUCHAR01
,oh.HDRPASSTHRUCHAR02
,oh.HDRPASSTHRUCHAR03
,oh.HDRPASSTHRUCHAR04
,oh.HDRPASSTHRUCHAR05
,oh.HDRPASSTHRUCHAR06
,oh.HDRPASSTHRUCHAR07
,oh.HDRPASSTHRUCHAR08
,oh.HDRPASSTHRUCHAR09
,oh.HDRPASSTHRUCHAR10
,oh.HDRPASSTHRUCHAR11
,oh.HDRPASSTHRUCHAR12
,oh.HDRPASSTHRUCHAR13
,oh.HDRPASSTHRUCHAR14
,oh.HDRPASSTHRUCHAR15
,oh.HDRPASSTHRUCHAR16
,oh.HDRPASSTHRUCHAR17
,oh.HDRPASSTHRUCHAR18
,oh.HDRPASSTHRUCHAR19
,oh.HDRPASSTHRUCHAR20
,oh.HDRPASSTHRUNUM01
,oh.HDRPASSTHRUNUM02
,oh.HDRPASSTHRUNUM03
,oh.HDRPASSTHRUNUM04
,oh.HDRPASSTHRUNUM05
,oh.HDRPASSTHRUNUM06
,oh.HDRPASSTHRUNUM07
,oh.HDRPASSTHRUNUM08
,oh.HDRPASSTHRUNUM09
,oh.HDRPASSTHRUNUM10
,oh.HDRPASSTHRUDATE01
,oh.HDRPASSTHRUDATE02
,oh.HDRPASSTHRUDATE03
,oh.HDRPASSTHRUDATE04
,oh.HDRPASSTHRUDOLL01
,oh.HDRPASSTHRUDOLL02,
sum(rc.qtyrcvd),
sum(rc.qtyrcvdgood),
sum(rc.qtyrcvddmgd)
from shipper sh, orderdtlrcpt rc, orderhdr oh
where oh.orderstatus = 'R'
  and oh.orderid = rc.orderid
  and oh.custid = 'HP'
  and oh.shipid = rc.shipid
  and oh.shipper = sh.shipper(+)
  and oh.statusupdate >= to_date('20001002000000','yyyymmddhh24miss')
  and oh.statusupdate <  to_date('20001003000000','yyyymmddhh24miss')
group by oh.custid,rc.inventoryclass,
  rc.inventoryclass,
  oh.orderid,oh.shipid,statusupdate,
  oh.shipper,sh.name,oh.billoflading,oh.carrier,oh.po,oh.ordertype,
  oh.HDRPASSTHRUCHAR01,oh.HDRPASSTHRUCHAR02,
  oh.HDRPASSTHRUCHAR03,oh.HDRPASSTHRUCHAR04,oh.HDRPASSTHRUCHAR05,oh.HDRPASSTHRUCHAR06,
  oh.HDRPASSTHRUCHAR07,oh.HDRPASSTHRUCHAR08,oh.HDRPASSTHRUCHAR09,oh.HDRPASSTHRUCHAR10,
  oh.HDRPASSTHRUCHAR11,oh.HDRPASSTHRUCHAR12,oh.HDRPASSTHRUCHAR13,oh.HDRPASSTHRUCHAR14,
  oh.HDRPASSTHRUCHAR15,oh.HDRPASSTHRUCHAR16,oh.HDRPASSTHRUCHAR17,oh.HDRPASSTHRUCHAR18,
  oh.HDRPASSTHRUCHAR19,oh.HDRPASSTHRUCHAR20,oh.HDRPASSTHRUNUM01,oh.HDRPASSTHRUNUM02,
  oh.HDRPASSTHRUNUM03,oh.HDRPASSTHRUNUM04,oh.HDRPASSTHRUNUM05,oh.HDRPASSTHRUNUM06,
  oh.HDRPASSTHRUNUM07,oh.HDRPASSTHRUNUM08,oh.HDRPASSTHRUNUM09,oh.HDRPASSTHRUNUM10,
  oh.HDRPASSTHRUDATE01,oh.HDRPASSTHRUDATE02,
  oh.HDRPASSTHRUDATE03,oh.HDRPASSTHRUDATE04,oh.HDRPASSTHRUDOLL01,oh.HDRPASSTHRUDOLL02;

comment on table rcptnote_hdr is '$Id';

create or replace view alps.rcptnote_dtl
(custid
,company
,warehouse
,orderid
,shipid
,receiptdate
,linenumber
,linenumberstr
,item
,lotnumber
,uom
,qtyrcvd
,cubercvd
,qtyrcvdgood
,cubercvdgood
,qtyrcvddmgd
,cubercvddmgd
,qtyorder
)
as
select
oh.custid,
rc.inventoryclass,
rc.inventoryclass,
oh.orderid,
oh.shipid,
oh.receiptdate,
zoe.line_number(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot),
substr(zoe.line_number_str(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot),1,6),
rc.item,
rc.lotnumber,
rc.uom,
sum(rc.qtyrcvd),
sum(rc.qtyrcvd) * zci.item_cube(oh.custid,rc.item,rc.uom),
sum(rc.qtyrcvdgood),
sum(rc.qtyrcvdgood) * zci.item_cube(oh.custid,rc.item,rc.uom),
sum(rc.qtyrcvddmgd),
sum(rc.qtyrcvddmgd) * zci.item_cube(oh.custid,rc.item,rc.uom),
sum(rc.qtyrcvd)
from orderdtlrcpt rc, rcptnote_hdr oh
where oh.orderid = rc.orderid
  and oh.shipid = rc.shipid
group by oh.custid,rc.inventoryclass,rc.inventoryclass,
  oh.orderid,oh.shipid,oh.receiptdate,
  zoe.line_number(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot),
  substr(zoe.line_number_str(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot),1,6),
  rc.item,rc.lotnumber,rc.uom;

comment on table rcptnote_dtl is '$Id';

CREATE OR REPLACE VIEW ALPS.rcpt_notify_hdr
(custid
,company
,warehouse
,orderid
,shipid
,receiptdate
,vendor
,vendordesc
,billoflading
,carrier
,po
,ordertype
,trailernosetemp
,trailermiddletemp
,trailertailtemp
,tracktrailertemps
)
as
select
o.custid,
'CMP',
'WHSE',
orderid,
shipid,
statusupdate,
o.shipper,
s.name,
billoflading,
carrier,
po,
ordertype,
trailernosetemp,
trailermiddletemp,
trailertailtemp,
nvl(tracktrailertemps,'N')
from orderconfirmview o, shipper s, customer c
where orderstatus = 'R'
  and o.shipper = s.shipper(+)
  and nvl(qtyrcvd,0) != 0
  and o.custid = c.custid;

comment on table rcpt_notify_hdr is '$Id';

create or replace view alps.rcpt_notify_dtl
(custid
,company
,warehouse
,orderid
,shipid
,receiptdate
,linenumber
,item
,lotnumber
,uom
,qtyrcvd
,cubercvd
,qtyorder
,linenumberstr
)
as
select
h.custid,
'CMP',
'WHSE',
h.orderid,
h.shipid,
zld.loads_rcvddate(h.loadno),
zoe.line_number(h.orderid,h.shipid,d.item,d.lotnumber),
d.item,
d.lotnumber,
d.uom,
nvl(d.qtyrcvdgood,0) + nvl(d.qtyrcvddmgd,0),
nvl(d.cubercvd,0),
nvl(d.qtyorder,0),
substr(zoe.line_number_str(h.orderid,h.shipid,d.item,d.lotnumber),1,6)
from orderconfirmview h, orderdtlview d
where orderstatus = 'R'
  and h.orderid = d.orderid
  and h.shipid = d.shipid
  and linestatus != 'X';

comment on table rcpt_notify_dtl is '$Id';

create or replace view alps.orderdtlrcptsumview
(orderid
,shipid
,custid
,item
,lotnumber
,orderitem
,orderlot
,serialnumber
,useritem1
,useritem2
,useritem3
,inventoryclass
,invstatus
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
)
as
select
 orderid
,shipid
,custid
,item
,lotnumber
,orderitem
,orderlot
,serialnumber
,useritem1
,useritem2
,useritem3
,inventoryclass
,invstatus
,sum(qtyrcvd)
,sum(qtyrcvdgood)
,sum(qtyrcvddmgd)
from orderdtlrcpt
where (serialnumber is null)
  and (useritem1 is null)
  and (useritem2 is null)
  and (useritem3 is null)
group by orderid,shipid,custid,item,lotnumber,orderitem,orderlot,serialnumber,
useritem1,useritem2,useritem3,inventoryclass,invstatus
union all
select
 orderid
,shipid
,custid
,item
,lotnumber
,orderitem
,orderlot
,serialnumber
,useritem1
,useritem2
,useritem3
,inventoryclass
,invstatus
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
from orderdtlrcpt
where ( (serialnumber is not null) or
        (useritem1 is not null) or
        (useritem2 is not null) or
        (useritem3 is not null) );

comment on table orderdtlrcptsumview is '$Id';

CREATE OR REPLACE VIEW ALPS.rcptonly_hdr
(loadno
,custid
,facility
,company
,warehouse
,orderid
,shipid
,receiptdate
,vendor
,vendordesc
,billoflading
,carrier
,po
,reference
,ordertype
,HDRPASSTHRUCHAR01
,HDRPASSTHRUCHAR02
,HDRPASSTHRUCHAR03
,HDRPASSTHRUCHAR04
,HDRPASSTHRUCHAR05
,HDRPASSTHRUCHAR06
,HDRPASSTHRUCHAR07
,HDRPASSTHRUCHAR08
,HDRPASSTHRUCHAR09
,HDRPASSTHRUCHAR10
,HDRPASSTHRUCHAR11
,HDRPASSTHRUCHAR12
,HDRPASSTHRUCHAR13
,HDRPASSTHRUCHAR14
,HDRPASSTHRUCHAR15
,HDRPASSTHRUCHAR16
,HDRPASSTHRUCHAR17
,HDRPASSTHRUCHAR18
,HDRPASSTHRUCHAR19
,HDRPASSTHRUCHAR20
,HDRPASSTHRUNUM01
,HDRPASSTHRUNUM02
,HDRPASSTHRUNUM03
,HDRPASSTHRUNUM04
,HDRPASSTHRUNUM05
,HDRPASSTHRUNUM06
,HDRPASSTHRUNUM07
,HDRPASSTHRUNUM08
,HDRPASSTHRUNUM09
,HDRPASSTHRUNUM10
,HDRPASSTHRUDATE01
,HDRPASSTHRUDATE02
,HDRPASSTHRUDATE03
,HDRPASSTHRUDATE04
,HDRPASSTHRUDOLL01
,HDRPASSTHRUDOLL02
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
)
as
select
oh.loadno,
oh.custid,
oh.tofacility,
rc.inventoryclass,
rc.inventoryclass,
oh.orderid,
oh.shipid,
oh.statusupdate,
oh.shipper,
sh.name,
oh.billoflading,
oh.carrier,
oh.po,
oh.reference,
oh.ordertype,
oh.HDRPASSTHRUCHAR01
,oh.HDRPASSTHRUCHAR02
,oh.HDRPASSTHRUCHAR03
,oh.HDRPASSTHRUCHAR04
,oh.HDRPASSTHRUCHAR05
,oh.HDRPASSTHRUCHAR06
,oh.HDRPASSTHRUCHAR07
,oh.HDRPASSTHRUCHAR08
,oh.HDRPASSTHRUCHAR09
,oh.HDRPASSTHRUCHAR10
,oh.HDRPASSTHRUCHAR11
,oh.HDRPASSTHRUCHAR12
,oh.HDRPASSTHRUCHAR13
,oh.HDRPASSTHRUCHAR14
,oh.HDRPASSTHRUCHAR15
,oh.HDRPASSTHRUCHAR16
,oh.HDRPASSTHRUCHAR17
,oh.HDRPASSTHRUCHAR18
,oh.HDRPASSTHRUCHAR19
,oh.HDRPASSTHRUCHAR20
,oh.HDRPASSTHRUNUM01
,oh.HDRPASSTHRUNUM02
,oh.HDRPASSTHRUNUM03
,oh.HDRPASSTHRUNUM04
,oh.HDRPASSTHRUNUM05
,oh.HDRPASSTHRUNUM06
,oh.HDRPASSTHRUNUM07
,oh.HDRPASSTHRUNUM08
,oh.HDRPASSTHRUNUM09
,oh.HDRPASSTHRUNUM10
,oh.HDRPASSTHRUDATE01
,oh.HDRPASSTHRUDATE02
,oh.HDRPASSTHRUDATE03
,oh.HDRPASSTHRUDATE04
,oh.HDRPASSTHRUDOLL01
,oh.HDRPASSTHRUDOLL02,
sum(rc.qtyrcvd),
sum(rc.qtyrcvdgood),
sum(rc.qtyrcvddmgd)
from shipper sh, orderdtlrcptsumview rc, orderhdr oh
where oh.orderstatus = 'R'
  and oh.orderid = rc.orderid
  and oh.ordertype in ('R','C')
  and oh.shipid = rc.shipid
  and oh.shipper = sh.shipper(+)
  and oh.statusupdate >= to_date('20001002000000','yyyymmddhh24miss')
  and oh.statusupdate <  to_date('20001003000000','yyyymmddhh24miss')
  and oh.qtyrcvd <> 0
group by oh.loadno,oh.custid,oh.tofacility,rc.inventoryclass,
  rc.inventoryclass,
  oh.orderid,oh.shipid,statusupdate,
  oh.shipper,sh.name,oh.billoflading,oh.carrier,oh.po,
  oh.reference,oh.ordertype,
  oh.HDRPASSTHRUCHAR01,oh.HDRPASSTHRUCHAR02,
  oh.HDRPASSTHRUCHAR03,oh.HDRPASSTHRUCHAR04,oh.HDRPASSTHRUCHAR05,oh.HDRPASSTHRUCHAR06,
  oh.HDRPASSTHRUCHAR07,oh.HDRPASSTHRUCHAR08,oh.HDRPASSTHRUCHAR09,oh.HDRPASSTHRUCHAR10,
  oh.HDRPASSTHRUCHAR11,oh.HDRPASSTHRUCHAR12,oh.HDRPASSTHRUCHAR13,oh.HDRPASSTHRUCHAR14,
  oh.HDRPASSTHRUCHAR15,oh.HDRPASSTHRUCHAR16,oh.HDRPASSTHRUCHAR17,oh.HDRPASSTHRUCHAR18,
  oh.HDRPASSTHRUCHAR19,oh.HDRPASSTHRUCHAR20,oh.HDRPASSTHRUNUM01,oh.HDRPASSTHRUNUM02,
  oh.HDRPASSTHRUNUM03,oh.HDRPASSTHRUNUM04,oh.HDRPASSTHRUNUM05,oh.HDRPASSTHRUNUM06,
  oh.HDRPASSTHRUNUM07,oh.HDRPASSTHRUNUM08,oh.HDRPASSTHRUNUM09,oh.HDRPASSTHRUNUM10,
  oh.HDRPASSTHRUDATE01,oh.HDRPASSTHRUDATE02,
  oh.HDRPASSTHRUDATE03,oh.HDRPASSTHRUDATE04,oh.HDRPASSTHRUDOLL01,oh.HDRPASSTHRUDOLL02;

comment on table rcptonly_hdr is '$Id';

create or replace view alps.rcptonly_dtl
(loadno
,custid
,facility
,company
,warehouse
,orderid
,shipid
,reference
,receiptdate
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
,invstatus
,trackingno
,custreference
,billoflading
,po
,qtyorder
,HDRPASSTHRUCHAR01
,HDRPASSTHRUCHAR02
,HDRPASSTHRUCHAR03
,HDRPASSTHRUCHAR04
,HDRPASSTHRUCHAR05
,HDRPASSTHRUCHAR06
,HDRPASSTHRUCHAR07
,HDRPASSTHRUCHAR08
,HDRPASSTHRUCHAR09
,HDRPASSTHRUCHAR10
,HDRPASSTHRUCHAR11
,HDRPASSTHRUCHAR12
,HDRPASSTHRUCHAR13
,HDRPASSTHRUCHAR14
,HDRPASSTHRUCHAR15
,HDRPASSTHRUCHAR16
,HDRPASSTHRUCHAR17
,HDRPASSTHRUCHAR18
,HDRPASSTHRUCHAR19
,HDRPASSTHRUCHAR20
,HDRPASSTHRUNUM01
,HDRPASSTHRUNUM02
,HDRPASSTHRUNUM03
,HDRPASSTHRUNUM04
,HDRPASSTHRUNUM05
,HDRPASSTHRUNUM06
,HDRPASSTHRUNUM07
,HDRPASSTHRUNUM08
,HDRPASSTHRUNUM09
,HDRPASSTHRUNUM10
,HDRPASSTHRUDATE01
,HDRPASSTHRUDATE02
,HDRPASSTHRUDATE03
,HDRPASSTHRUDATE04
,HDRPASSTHRUDOLL01
,HDRPASSTHRUDOLL02
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
,DTLPASSTHRUCHAR01
,DTLPASSTHRUCHAR02
,DTLPASSTHRUCHAR03
,DTLPASSTHRUCHAR04
,DTLPASSTHRUCHAR05
,DTLPASSTHRUCHAR06
,DTLPASSTHRUCHAR07
,DTLPASSTHRUCHAR08
,DTLPASSTHRUCHAR09
,DTLPASSTHRUCHAR10
,DTLPASSTHRUCHAR11
,DTLPASSTHRUCHAR12
,DTLPASSTHRUCHAR13
,DTLPASSTHRUCHAR14
,DTLPASSTHRUCHAR15
,DTLPASSTHRUCHAR16
,DTLPASSTHRUCHAR17
,DTLPASSTHRUCHAR18
,DTLPASSTHRUCHAR19
,DTLPASSTHRUCHAR20
,DTLPASSTHRUNUM01
,DTLPASSTHRUNUM02
,DTLPASSTHRUNUM03
,DTLPASSTHRUNUM04
,DTLPASSTHRUNUM05
,DTLPASSTHRUNUM06
,DTLPASSTHRUNUM07
,DTLPASSTHRUNUM08
,DTLPASSTHRUNUM09
,DTLPASSTHRUNUM10
,DTLPASSTHRUDATE01
,DTLPASSTHRUDATE02
,DTLPASSTHRUDATE03
,DTLPASSTHRUDATE04
,DTLPASSTHRUDOLL01
,DTLPASSTHRUDOLL02
)
as
select
oh.loadno,
oh.custid,
oh.facility,
rc.inventoryclass,
rc.inventoryclass,
oh.orderid,
oh.shipid,
oh.reference,
oh.receiptdate,
rc.item,
rc.lotnumber,
rc.serialnumber,
rc.useritem1,
rc.useritem2,
rc.useritem3,
rc.invstatus,
asn.trackingno,
asn.custreference,
oh.billoflading,
oh.po,
nvl(asn.qty,0),
oh.HDRPASSTHRUCHAR01
,oh.HDRPASSTHRUCHAR02
,oh.HDRPASSTHRUCHAR03
,oh.HDRPASSTHRUCHAR04
,oh.HDRPASSTHRUCHAR05
,oh.HDRPASSTHRUCHAR06
,oh.HDRPASSTHRUCHAR07
,oh.HDRPASSTHRUCHAR08
,oh.HDRPASSTHRUCHAR09
,oh.HDRPASSTHRUCHAR10
,oh.HDRPASSTHRUCHAR11
,oh.HDRPASSTHRUCHAR12
,oh.HDRPASSTHRUCHAR13
,oh.HDRPASSTHRUCHAR14
,oh.HDRPASSTHRUCHAR15
,oh.HDRPASSTHRUCHAR16
,oh.HDRPASSTHRUCHAR17
,oh.HDRPASSTHRUCHAR18
,oh.HDRPASSTHRUCHAR19
,oh.HDRPASSTHRUCHAR20
,oh.HDRPASSTHRUNUM01
,oh.HDRPASSTHRUNUM02
,oh.HDRPASSTHRUNUM03
,oh.HDRPASSTHRUNUM04
,oh.HDRPASSTHRUNUM05
,oh.HDRPASSTHRUNUM06
,oh.HDRPASSTHRUNUM07
,oh.HDRPASSTHRUNUM08
,oh.HDRPASSTHRUNUM09
,oh.HDRPASSTHRUNUM10
,oh.HDRPASSTHRUDATE01
,oh.HDRPASSTHRUDATE02
,oh.HDRPASSTHRUDATE03
,oh.HDRPASSTHRUDATE04
,oh.HDRPASSTHRUDOLL01
,oh.HDRPASSTHRUDOLL02,
sum(rc.qtyrcvd),
sum(rc.qtyrcvdgood),
sum(rc.qtyrcvddmgd)
,od.DTLPASSTHRUCHAR01
,od.DTLPASSTHRUCHAR02
,od.DTLPASSTHRUCHAR03
,od.DTLPASSTHRUCHAR04
,od.DTLPASSTHRUCHAR05
,od.DTLPASSTHRUCHAR06
,od.DTLPASSTHRUCHAR07
,od.DTLPASSTHRUCHAR08
,od.DTLPASSTHRUCHAR09
,od.DTLPASSTHRUCHAR10
,od.DTLPASSTHRUCHAR11
,od.DTLPASSTHRUCHAR12
,od.DTLPASSTHRUCHAR13
,od.DTLPASSTHRUCHAR14
,od.DTLPASSTHRUCHAR15
,od.DTLPASSTHRUCHAR16
,od.DTLPASSTHRUCHAR17
,od.DTLPASSTHRUCHAR18
,od.DTLPASSTHRUCHAR19
,od.DTLPASSTHRUCHAR20
,od.DTLPASSTHRUNUM01
,od.DTLPASSTHRUNUM02
,od.DTLPASSTHRUNUM03
,od.DTLPASSTHRUNUM04
,od.DTLPASSTHRUNUM05
,od.DTLPASSTHRUNUM06
,od.DTLPASSTHRUNUM07
,od.DTLPASSTHRUNUM08
,od.DTLPASSTHRUNUM09
,od.DTLPASSTHRUNUM10
,od.DTLPASSTHRUDATE01
,od.DTLPASSTHRUDATE02
,od.DTLPASSTHRUDATE03
,od.DTLPASSTHRUDATE04
,od.DTLPASSTHRUDOLL01
,od.DTLPASSTHRUDOLL02
from orderdtl od, asncartondtl asn, orderdtlrcptsumview rc, rcptonly_hdr oh
where oh.orderid = rc.orderid
  and oh.shipid = rc.shipid
  and rc.orderid = asn.orderid (+)
  and rc.shipid = asn.shipid (+)
  and rc.item = asn.item (+)
  and rc.qtyrcvd <> 0
  and nvl(rc.lotnumber,'x') = nvl(asn.lotnumber(+),'x')
  and nvl(rc.serialnumber,'x') = nvl(asn.serialnumber(+),'x')
  and nvl(rc.useritem1,'x') = nvl(asn.useritem1(+),'x')
  and nvl(rc.useritem2,'x') = nvl(asn.useritem2(+),'x')
  and nvl(rc.useritem3,'x') = nvl(asn.useritem3(+),'x')
  and rc.orderid = od.orderid(+)
  and rc.shipid = od.shipid(+)
  and rc.orderitem = od.item(+)
  and rc.orderlot = od.lotnumber(+)
group by oh.loadno,oh.custid,
  oh.facility,
  rc.inventoryclass,
  rc.inventoryclass,
  oh.orderid,oh.shipid,oh.reference,oh.receiptdate,
  rc.item,rc.lotnumber,rc.serialnumber,
  rc.useritem1,rc.useritem2,rc.useritem3,rc.invstatus,
  asn.trackingno,asn.custreference,oh.billoflading,oh.po,nvl(asn.qty,0),
  oh.HDRPASSTHRUCHAR01,oh.HDRPASSTHRUCHAR02,
  oh.HDRPASSTHRUCHAR03,oh.HDRPASSTHRUCHAR04,oh.HDRPASSTHRUCHAR05,oh.HDRPASSTHRUCHAR06,
  oh.HDRPASSTHRUCHAR07,oh.HDRPASSTHRUCHAR08,oh.HDRPASSTHRUCHAR09,oh.HDRPASSTHRUCHAR10,
  oh.HDRPASSTHRUCHAR11,oh.HDRPASSTHRUCHAR12,oh.HDRPASSTHRUCHAR13,oh.HDRPASSTHRUCHAR14,
  oh.HDRPASSTHRUCHAR15,oh.HDRPASSTHRUCHAR16,oh.HDRPASSTHRUCHAR17,oh.HDRPASSTHRUCHAR18,
  oh.HDRPASSTHRUCHAR19,oh.HDRPASSTHRUCHAR20,oh.HDRPASSTHRUNUM01,oh.HDRPASSTHRUNUM02,
  oh.HDRPASSTHRUNUM03,oh.HDRPASSTHRUNUM04,oh.HDRPASSTHRUNUM05,oh.HDRPASSTHRUNUM06,
  oh.HDRPASSTHRUNUM07,oh.HDRPASSTHRUNUM08,oh.HDRPASSTHRUNUM09,oh.HDRPASSTHRUNUM10,
  oh.HDRPASSTHRUDATE01,oh.HDRPASSTHRUDATE02,
  oh.HDRPASSTHRUDATE03,oh.HDRPASSTHRUDATE04,oh.HDRPASSTHRUDOLL01,oh.HDRPASSTHRUDOLL02,
  od.DTLPASSTHRUCHAR01,od.DTLPASSTHRUCHAR02,
  od.DTLPASSTHRUCHAR03,od.DTLPASSTHRUCHAR04,od.DTLPASSTHRUCHAR05,od.DTLPASSTHRUCHAR06,
  od.DTLPASSTHRUCHAR07,od.DTLPASSTHRUCHAR08,od.DTLPASSTHRUCHAR09,od.DTLPASSTHRUCHAR10,
  od.DTLPASSTHRUCHAR11,od.DTLPASSTHRUCHAR12,od.DTLPASSTHRUCHAR13,od.DTLPASSTHRUCHAR14,
  od.DTLPASSTHRUCHAR15,od.DTLPASSTHRUCHAR16,od.DTLPASSTHRUCHAR17,od.DTLPASSTHRUCHAR18,
  od.DTLPASSTHRUCHAR19,od.DTLPASSTHRUCHAR20,od.DTLPASSTHRUNUM01,od.DTLPASSTHRUNUM02,
  od.DTLPASSTHRUNUM03,od.DTLPASSTHRUNUM04,od.DTLPASSTHRUNUM05,od.DTLPASSTHRUNUM06,
  od.DTLPASSTHRUNUM07,od.DTLPASSTHRUNUM08,od.DTLPASSTHRUNUM09,od.DTLPASSTHRUNUM10,
  od.DTLPASSTHRUDATE01,od.DTLPASSTHRUDATE02,
  od.DTLPASSTHRUDATE03,od.DTLPASSTHRUDATE04,od.DTLPASSTHRUDOLL01,od.DTLPASSTHRUDOLL02;

comment on table rcptonly_dtl is '$Id';

CREATE OR REPLACE VIEW ALPS.rtrnonly_hdr
(custid
,company
,warehouse
,orderid
,shipid
,receiptdate
,vendor
,vendordesc
,billoflading
,carrier
,po
,reference
,ordertype
,origorderid
,origshipid
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
,shiptoaddr1
)
as
select
oh.custid,
rc.inventoryclass,
rc.inventoryclass,
oh.orderid,
oh.shipid,
oh.statusupdate,
oh.shipper,
sh.name,
oh.billoflading,
oh.carrier,
oh.po,
oh.reference,
oh.ordertype,
oh.origorderid,
oh.origshipid,
sum(rc.qtyrcvd),
sum(rc.qtyrcvdgood),
sum(rc.qtyrcvddmgd),
oh.shiptoaddr1
from shipper sh, orderdtlrcptsumview rc, orderhdr oh
where oh.orderstatus = 'R'
  and oh.orderid = rc.orderid
  and oh.ordertype = 'Q'
  and oh.shipid = rc.shipid
  and oh.shipper = sh.shipper(+)
  and oh.qtyrcvd <> 0
  and oh.statusupdate >= to_date('20001002000000','yyyymmddhh24miss')
  and oh.statusupdate <  to_date('20001003000000','yyyymmddhh24miss')
group by oh.custid,rc.inventoryclass,
  rc.inventoryclass,
  oh.orderid,oh.shipid,statusupdate,
  oh.shipper,sh.name,oh.billoflading,oh.carrier,oh.po,
  oh.reference,oh.ordertype,oh.origorderid,oh.origshipid,oh.shiptoaddr1;

comment on table rtrnonly_hdr is '$Id';

create or replace view alps.rtrnonly_dtl
(custid
,company
,warehouse
,orderid
,shipid
,reference
,receiptdate
,item
,lotnumber
,serialnumber
,useritem1
,useritem2
,useritem3
,trackingno
,custreference
,origreference
,origtrackingno
,reasoncode
,billoflading
,qtyorder
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
,uom
,useramt1
,useramt2
,shiptoaddr1
)
as
select
oh.custid,
rc.inventoryclass,
rc.inventoryclass,
oh.orderid,
oh.shipid,
oh.reference,
oh.receiptdate,
rc.item,
rc.lotnumber,
rc.serialnumber,
rc.useritem1,
rc.useritem2,
rc.useritem3,
asn.trackingno,
asn.custreference,
zoe.order_reference(oh.origorderid,oh.origshipid),
zoe.outbound_trackingno(oh.origorderid,oh.origshipid,rc.item,
  rc.lotnumber,rc.serialnumber,
  rc.useritem1,rc.useritem2,rc.useritem3),
zoe.inbound_condition(oh.orderid,oh.shipid,rc.item,
  rc.lotnumber,rc.serialnumber,
  rc.useritem1,rc.useritem2,rc.useritem3),
oh.billoflading,
nvl(asn.qty,0),
sum(rc.qtyrcvd),
sum(rc.qtyrcvdgood),
sum(rc.qtyrcvddmgd),
ci.baseuom,
ci.useramt1,
ci.useramt2,
oh.shiptoaddr1
from custitem ci, asncartondtl asn, orderdtlrcptsumview rc, rtrnonly_hdr oh
where oh.orderid = rc.orderid
  and oh.shipid = rc.shipid
  and rc.orderid = asn.orderid (+)
  and rc.shipid = asn.shipid (+)
  and rc.item = asn.item (+)
  and rc.qtyrcvd <> 0
  and nvl(rc.lotnumber,'x') = nvl(asn.lotnumber(+),'x')
  and nvl(rc.serialnumber,'x') = nvl(asn.serialnumber(+),'x')
  and nvl(rc.useritem1,'x') = nvl(asn.useritem1(+),'x')
  and nvl(rc.useritem2,'x') = nvl(asn.useritem2(+),'x')
  and nvl(rc.useritem3,'x') = nvl(asn.useritem3(+),'x')
  and rc.custid = ci.custid(+)
  and rc.item = ci.item(+)
group by oh.custid,
  rc.inventoryclass,
  rc.inventoryclass,
  oh.orderid,oh.shipid,oh.reference,oh.receiptdate,
  rc.item,rc.lotnumber,rc.serialnumber,
  rc.useritem1,rc.useritem2,rc.useritem3,
  oh.origorderid,oh.origshipid,
  asn.trackingno,asn.custreference,
  zoe.order_reference(oh.origorderid,oh.origshipid),
  zoe.outbound_trackingno(oh.origorderid,oh.origshipid,rc.item,
    rc.lotnumber,rc.serialnumber,
    rc.useritem1,rc.useritem2,rc.useritem3),
  zoe.inbound_condition(oh.orderid,oh.shipid,rc.item,
    rc.lotnumber,rc.serialnumber,
    rc.useritem1,rc.useritem2,rc.useritem3),
  oh.billoflading,
  nvl(asn.qty,0),
  ci.baseuom,
  ci.useramt1,
  ci.useramt2,
  oh.shiptoaddr1;

comment on table rtrnonly_dtl is '$Id$';

exit;

