/* these are static representation of view built dynamically at run time
by the zim7.begin_ship_notify packaged procedure--changes here should be relected
there
*/
CREATE OR REPLACE VIEW ALPS.ship_notify_hdr
(custid
,company
,warehouse
,orderid
,shipid
,reference
,trackingno
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
,pronumber
,outpallets
,po
,hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar05,
hdrpassthruchar06,
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
shipterms,
loadno,
order_count,
order_seq,
billoflading,
saturdaydelivery,
shiptype,
prono_or_trackingno,
shipunits,
shipweight,
shipcost
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
nvl(oh.prono,lo.prono),
zpt.sum_outpallets(oh.loadno,oh.orderid,oh.shipid),
po,
hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar05,
hdrpassthruchar06,
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
nvl(lo.shipterms,oh.shipterms),
oh.loadno,
zimsb.order_count_on_load(oh.loadno),
zimsb.order_seq_on_load(oh.loadno,oh.orderid,oh.shipid),
nvl(lo.billoflading,oh.billoflading),
oh.saturdaydelivery,
nvl(lo.shiptype,oh.shiptype),
nvl(substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),nvl(oh.prono,lo.prono)),
oh.qtyship,
oh.weightship,
wv.shipcost
from waves wv, carrier ca, loads lo, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = lo.loadno(+)
  and oh.wave = wv.wave(+);

comment on table ship_notify_hdr is '$Id$';

create or replace view alps.ship_notify_container
(orderid
,shipid
,custid
,shipticket
,ucc128
,trackingno
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
,qty
)
as
select
h.orderid,
h.shipid,
h.custid,
d.lpid,
zedi.get_sscc18_code(d.custid, '1', d.lpid),
decode(nvl(c.multiship,'N'),'Y',d.trackingno,
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
d.quantity
from carrier c, shippingplate d, orderhdr h
where orderstatus = '9'
  and h.orderid = d.orderid
  and h.shipid = d.shipid
  and d.parentlpid is null
  and d.status = 'SH'
  and h.carrier = c.carrier(+);

comment on table ship_notify_container is '$Id$';

create or replace view alps.ship_notify_contents
(orderid
,shipid
,custid
,shipticket
,trackingno
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
,qtyorder
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
zoe.line_qtyorder(d.orderid,d.shipid,d.orderitem,d.orderlot)
from carrier c, shippingplate d, orderhdr h
where orderstatus = '9'
  and h.orderid = d.orderid
  and h.shipid = d.shipid
  and d.type in ('F','P')
  and d.status = 'SH'
  and h.carrier = c.carrier(+);

comment on table ship_notify_contents is '$Id$';

create or replace view alps.ship_notify_items
(orderid
,shipid
,custid
,shipticket
,trackingno
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
,qtyorder
,qtyentered
,uomentered
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
zoe.line_qtyorder(d.orderid,d.shipid,d.orderitem,d.orderlot),
decode(
mod(zcu.equiv_uom_qty(h.custid,d.item,d.unitofmeasure,d.quantity,
substr(zim14.line_uomentered(d.orderid,d.shipid,d.orderitem,d.orderlot),1,4)),1),
0,zcu.equiv_uom_qty(h.custid,d.item,d.unitofmeasure,d.quantity,
substr(zim14.line_uomentered(d.orderid,d.shipid,d.orderitem,d.orderlot),1,4)),
d.quantity),
decode(
mod(zcu.equiv_uom_qty(h.custid,d.item,d.unitofmeasure,d.quantity,
substr(zim14.line_uomentered(d.orderid,d.shipid,d.orderitem,d.orderlot),1,4)),1),
0,substr(zim14.line_uomentered(d.orderid,d.shipid,d.orderitem,d.orderlot),1,4),
d.unitofmeasure)
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
,nvl(substr(zoe.max_trackingno(od.orderid,od.shipid,od.item,od.lotnumber),1,30),nvl(h.prono,lo.prono))
from loads lo, carrier c, shippingplate d, orderdtl od, orderhdr h
where orderstatus = '9'
  and h.orderid = d.orderid
  and h.shipid = d.shipid
  and d.type in ('F','P')
  and d.status = 'SH'
  and h.carrier = c.carrier(+)
  and d.orderid = od.orderid
  and d.shipid = od.shipid
  and d.orderitem = od.item
  and h.loadno = lo.loadno(+)
  and nvl(d.orderlot,'(none)') = nvl(od.lotnumber,'(none)');

comment on table ship_notify_items is '$Id$';

exit;

