CREATE OR REPLACE VIEW ALPS.ship_sumnonserial_hdr
(custid
,company
,warehouse
,orderid
,shipid
,reference
,trackingno
,rmatrackingno
,dateshipped
,commitdate
,shipviacode
,lbs
,kgs
,gms
,ozs
,shipticket
,height
,width
,length
,shiptoname
,shiptocontact
,shiptoaddr1
,shiptoaddr2
,shiptocity
,shiptostate
,shiptopostalcode
,shiptocountrycode
,shiptophone
,carrier
,carrierused
,cost
,packlistshipdate
,prono
,hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar07,
hdrpassthruchar08,
hdrpassthruchar09,
hdrpassthruchar10,
hdrpassthruchar11,
hdrpassthruchar12,
hdrpassthruchar13,
hdrpassthruchar14,
hdrpassthruchar15,
hdrpassthruchar16,
hdrpassthruchar17,
hdrpassthruchar18,
hdrpassthruchar19,
hdrpassthruchar20,
hdrpassthrunum01,
hdrpassthrunum02,
hdrpassthrunum03,
hdrpassthrunum04,
hdrpassthrunum05,
hdrpassthrunum06,
hdrpassthrunum07,
hdrpassthrunum08,
hdrpassthrunum09,
hdrpassthrunum10,
prono_or_trackingno
)
as
select
custid,
hdrpassthruchar05,
hdrpassthruchar06,
orderid,
shipid,
reference,
decode(nvl(ca.multiship,'N'),'Y',substr(zoe.max_trackingno(orderid,shipid),1,30),
  to_char(orderid) || '-' || to_char(shipid)),
decode(nvl(ca.multiship,'N'),'Y',substr(zim5.max_rmatrackingno(orderid,shipid),1,30),
  null),
oh.statusupdate,
shipdate,
nvl(deliveryservice,'OTHR'),
zoe.sum_shipping_weight(orderid,shipid),
zoe.sum_shipping_weight(orderid,shipid) / 2.2046,
zoe.sum_shipping_weight(orderid,shipid) / .0022046,
zoe.sum_shipping_weight(orderid,shipid) * 16,
substr(zoe.max_shipping_container(orderid,shipid),1,15),
zoe.cartontype_height(zoe.max_cartontype(orderid,shipid)),
zoe.cartontype_width(zoe.max_cartontype(orderid,shipid)),
zoe.cartontype_length(zoe.max_cartontype(orderid,shipid)),
shiptoname,
shiptocontact,
shiptoaddr1,
shiptoaddr2,
shiptocity,
shiptostate,
shiptopostalcode,
shiptocountrycode,
shiptophone,
oh.carrier,
substr(zoe.max_carrierused(orderid,shipid),1,10),
zoe.sum_shipping_cost(orderid,shipid),
packlistshipdate,
ld.prono,
hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar07,
hdrpassthruchar08,
hdrpassthruchar09,
hdrpassthruchar10,
hdrpassthruchar11,
hdrpassthruchar12,
hdrpassthruchar13,
hdrpassthruchar14,
hdrpassthruchar15,
hdrpassthruchar16,
hdrpassthruchar17,
hdrpassthruchar18,
hdrpassthruchar19,
hdrpassthruchar20,
hdrpassthrunum01,
hdrpassthrunum02,
hdrpassthrunum03,
hdrpassthrunum04,
hdrpassthrunum05,
hdrpassthrunum06,
hdrpassthrunum07,
hdrpassthrunum08,
hdrpassthrunum09,
hdrpassthrunum10,
decode(nvl(ca.multiship,'N'),'Y',substr(zoe.max_trackingno(orderid,shipid),1,30),
  nvl(oh.prono,ld.prono))
from carrier ca, loads ld, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = ld.loadno(+);

comment on table ship_sumnonserial_hdr is '$Id$';

create or replace view alps.ship_sumnonserial_items
(orderid
,shipid
,custid
,shipticket
,trackingno
,rmatrackingno
,carrier
,dateshipped
,servicecode
,lbs
,kgs
,gms
,ozs
,item
,itemdescr
,reference
,linenumber
,orderdate
,po
,qty
,uom
,lotnumber
,serialnumber
,linenumberstr
,packlistshipdate
,prono
,useritem1
,useritem2
,useritem3
,prono_or_trackingno
)
as
select
h.orderid,
h.shipid,
h.custid,
substr(zoe.min_nonserial_lpid(h.orderid,h.shipid),1,15),
to_char(h.orderid) || '-' || to_char(h.shipid),
d.rmatrackingno,
h.carrier,
h.statusupdate,
nvl(h.deliveryservice,'OTHR'),
d.weight,
d.weight / 2.2046,
d.weight / .0022046,
d.weight * 16,
d.item,
substr(zit.item_descr(d.custid,d.item),1,255),
h.reference,
zoe.line_number(d.orderid,d.shipid,d.orderitem,d.orderlot),
h.entrydate,
h.po,
d.quantity,
d.unitofmeasure,
d.lotnumber,
d.serialnumber,
substr(zoe.line_number_str(d.orderid,d.shipid,d.orderitem,d.orderlot),3,4),
h.packlistshipdate,
l.prono,
d.useritem1,
d.useritem2,
d.useritem3,
decode(nvl(c.multiship,'N'),'Y',d.trackingno,
  nvl(h.prono,l.prono))
from carrier c, loads l, shippingplate d, orderhdr h
where orderstatus = '9'
  and h.orderid = d.orderid
  and h.shipid = d.shipid
  and d.type in ('F','P')
  and d.status = 'SH'
  and h.carrier = c.carrier(+)
  and nvl(c.multiship,'N') = 'N'
  and h.loadno = l.loadno(+)
  and d.serialnumber is null;

comment on table ship_sumnonserial_items is '$Id$';

create or replace view alps.ship_sumnonserial_container
(orderid
,shipid
,custid
,shipticket
,trackingno
,rmatrackingno
,carrier
,dateshipped
,servicecode
,lbs
,kgs
,gms
,ozs
,carrierused
,reason
,cost
,packlistshipdate
,prono
,prono_or_trackingno
)
as
select
h.orderid,
h.shipid,
h.custid,
d.lpid,
decode(nvl(c.multiship,'N'),'Y',d.trackingno,
  to_char(h.orderid) || '-' || to_char(h.shipid)),
decode(nvl(c.multiship,'N'),'Y',d.rmatrackingno,
  to_char(h.orderid) || '-' || to_char(h.shipid)),
h.carrier,
h.statusupdate,
nvl(h.deliveryservice,'OTHR'),
d.weight,
d.weight / 2.2046,
d.weight / .0022046,
d.weight * 16,
substr(zsp.carrierused(d.orderid,d.shipid,d.lpid),1,10),
substr(zsp.reason(d.orderid,d.shipid,d.lpid),1,100),
zsp.cost(d.orderid,d.shipid,d.lpid),
h.packlistshipdate,
l.prono,
decode(nvl(c.multiship,'N'),'Y',d.trackingno,
  nvl(h.prono,l.prono))
from carrier c, loads l, shippingplate d, orderhdr h
where orderstatus = '9'
  and h.orderid = d.orderid
  and h.shipid = d.shipid
  and d.parentlpid is null
  and d.status = 'SH'
  and h.loadno = l.loadno(+)
  and h.carrier = c.carrier(+)
  and ( (nvl(c.multiship,'N') = 'Y') or
        ( (d.type in ('F','P')) and (d.serialnumber is not null) ) or
        ( (d.type = 'M') and (exists
           (select * from shippingplate c
             where c.parentlpid = d.lpid
               and c.type in ('F','P')
               and c.status = 'SH'
               and c.serialnumber is not null)) )
      )
union all
select
 orderid
,shipid
,custid
,shipticket
,trackingno
,rmatrackingno
,carrier
,dateshipped
,servicecode
,sum(lbs)
,sum(kgs)
,sum(gms)
,sum(ozs)
,null
,null
,0
,packlistshipdate
,prono
,prono_or_trackingno
from ship_sumnonserial_items
group by orderid,shipid,custid,shipticket,trackingno,rmatrackingno,
carrier,dateshipped,servicecode,
null,null,0,packlistshipdate,prono,prono_or_trackingno;

comment on table ship_sumnonserial_container is '$Id$';

create or replace view alps.ship_sumnonserial_contents
(orderid
,shipid
,custid
,shipticket
,trackingno
,rmatrackingno
,carrier
,dateshipped
,servicecode
,lbs
,kgs
,gms
,ozs
,item
,itemdescr
,reference
,linenumber
,orderdate
,po
,qty
,uom
,lotnumber
,serialnumber
,linenumberstr
,packlistshipdate
,useritem1
,useritem2
,useritem3
,prono_or_trackingno
)
as
select
h.orderid,
h.shipid,
h.custid,
nvl(d.parentlpid,lpid),
decode(nvl(c.multiship,'N'),'Y',
  substr(zmp.shipplate_trackingno(nvl(d.parentlpid,lpid)),1,30),
  to_char(h.orderid) || '-' || to_char(h.shipid)),
decode(nvl(c.multiship,'N'),'Y',
  substr(zim5.shipplate_rmatrackingno(nvl(d.parentlpid,lpid)),1,30),
  null),
h.carrier,
h.statusupdate,
nvl(h.deliveryservice,'OTHR'),
d.weight,
d.weight / 2.2046,
d.weight / .0022046,
d.weight * 16,
d.item,
substr(zit.item_descr(d.custid,d.item),1,255),
h.reference,
zoe.line_number(d.orderid,d.shipid,d.orderitem,d.orderlot),
h.entrydate,
h.po,
d.quantity,
d.unitofmeasure,
d.lotnumber,
d.serialnumber,
substr(zoe.line_number_str(d.orderid,d.shipid,d.orderitem,d.orderlot),3,4),
h.packlistshipdate,
d.useritem1,
d.useritem2,
d.useritem3,
decode(nvl(c.multiship,'N'),'Y',d.trackingno,
  nvl(h.prono,l.prono))
from carrier c, loads l, shippingplate d, orderhdr h
where orderstatus = '9'
  and h.orderid = d.orderid
  and h.shipid = d.shipid
  and d.type in ('F','P')
  and d.status = 'SH'
  and h.loadno = l.loadno(+)
  and h.carrier = c.carrier(+)
  and ( (nvl(c.multiship,'N') = 'Y') or
        (d.serialnumber is not null)
      )
union all
select
 orderid
,shipid
,custid
,shipticket
,trackingno
,rmatrackingno
,carrier
,dateshipped
,servicecode
,sum(lbs)
,sum(kgs)
,sum(gms)
,sum(ozs)
,item
,itemdescr
,reference
,linenumber
,orderdate
,po
,sum(qty)
,uom
,lotnumber
,serialnumber
,linenumberstr
,packlistshipdate
,useritem1
,useritem2
,useritem3
,prono_or_trackingno
from ship_sumnonserial_items
group by orderid,shipid,custid,shipticket,trackingno,rmatrackingno,carrier,
dateshipped,servicecode,item,itemdescr,reference,linenumber,
orderdate,po,uom,lotnumber,serialnumber,linenumberstr,
packlistshipdate,useritem1,useritem2,useritem3,prono_or_trackingno;

comment on table ship_sumnonserial_contents is '$Id$';

exit;

