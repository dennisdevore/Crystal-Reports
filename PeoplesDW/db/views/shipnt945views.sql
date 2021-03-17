-- drop view ship_nt_945_man_sscc18;

CREATE OR REPLACE VIEW ALPS.ship_nt_945_hdr
(custid
,company
,warehouse
,loadno
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
,shiptoidcode
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
,carrier_name
,packlistshipdate
,routing
,shiptype
,shipterms
,reportingcode
,depositororder
,po
,deliverydate
,estdelivery
,billoflading
,prono
,masterbol
,splitshipno
,invoicedate
,effectivedate
,totalunits
,totalweight
,uomweight
,totalvolume
,uomvolume
,ladingqty
,uom
,warehouse_name
,warehouse_id
,depositor_name
,depositor_id
,HDRPASSTHRUCHAR01,
HDRPASSTHRUCHAR02,
HDRPASSTHRUCHAR03,
HDRPASSTHRUCHAR04,
HDRPASSTHRUCHAR05,
HDRPASSTHRUCHAR06,
HDRPASSTHRUCHAR07,
HDRPASSTHRUCHAR08,
HDRPASSTHRUCHAR09,
HDRPASSTHRUCHAR10,
HDRPASSTHRUCHAR11,
HDRPASSTHRUCHAR12,
HDRPASSTHRUCHAR13,
HDRPASSTHRUCHAR14,
HDRPASSTHRUCHAR15,
HDRPASSTHRUCHAR16,
HDRPASSTHRUCHAR17,
HDRPASSTHRUCHAR18,
HDRPASSTHRUCHAR19,
HDRPASSTHRUCHAR20,
HDRPASSTHRUNUM01,
HDRPASSTHRUNUM02,
HDRPASSTHRUNUM03,
HDRPASSTHRUNUM04,
HDRPASSTHRUNUM05,
HDRPASSTHRUNUM06,
HDRPASSTHRUNUM07,
HDRPASSTHRUNUM08,
HDRPASSTHRUNUM09,
HDRPASSTHRUNUM10
,HDRPASSTHRUDATE01
,HDRPASSTHRUDATE02
,HDRPASSTHRUDATE03
,HDRPASSTHRUDATE04
,HDRPASSTHRUDOLL01
,HDRPASSTHRUDOLL02
,trailer
,seal
,palletcount
,freightcost
,lateshipreason
,carrier_del_serv
,shippingcost
,prono_or_all_trackingnos,
shipfromaddr1,
shipfromcity,
shipfromstate,
shipfrompostalcode,
shipfromcountrycode,
customername,
customeraddr1,
customeraddr2,
customercity,
customerstate,
customerpostalcode,
customercountrycode,
totqtyshipped,
totqtyordered,
qtydifference,
cancelafter,
deliveryrequested,
requestedship,
shipnotbefore,
shipnolater,
cancelifnotdelivdby,
donotdeliverafter,
donotdeliverbefore,
cancelleddate,
vicsbol
)
as
select
oh.custid,
' ',
' ',
oh.loadno,
oh.orderid,
oh.shipid,
oh.reference,
decode(nvl(ca.multiship,'N'),'Y',substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),
  nvl(oh.prono,nvl(l.prono,to_char(oh.orderid) || '-' || to_char(oh.shipid)))),
oh.statusupdate,
oh.shipdate,
nvl(deliveryservice,'OTHR'),
zoe.sum_shipping_weight(orderid,shipid),
zoe.sum_shipping_weight(orderid,shipid) / 2.2046,
zoe.sum_shipping_weight(orderid,shipid) / .0022046,
zoe.sum_shipping_weight(orderid,shipid) * 16,
substr(zoe.max_shipping_container(orderid,shipid),1,15),
zoe.cartontype_height(zoe.max_cartontype(orderid,shipid)),
zoe.cartontype_width(zoe.max_cartontype(orderid,shipid)),
zoe.cartontype_length(zoe.max_cartontype(orderid,shipid)),
oh.shipto,
decode(CN.consignee,null,shiptoname,CN.name),
decode(CN.consignee,null,shiptocontact,CN.contact),
decode(CN.consignee,null,shiptoaddr1,CN.addr1),
decode(CN.consignee,null,shiptoaddr2,CN.addr2),
decode(CN.consignee,null,shiptocity,CN.city),
decode(CN.consignee,null,shiptostate,CN.state),
decode(CN.consignee,null,shiptopostalcode,CN.postalcode),
decode(CN.consignee,null,shiptocountrycode,CN.countrycode),
decode(CN.consignee,null,shiptophone,CN.phone),
oh.carrier,
ca.name,
'  ', -- to_char(packlistshipdate,'YYYYMMDD'),
oh.hdrpassthruchar06,
oh.shiptype,
oh.shipterms,
'A',
oh.reference,
oh.po,
oh.hdrpassthruchar07,
to_char(oh.arrivaldate,'YYYYMMDD'),
to_char(oh.orderid)||'-'||to_char(oh.shipid),
L.prono,
decode(zim7.load_orders(L.loadno), 'Y',L.loadno,null),
decode(zim7.split_shipment(oh.custid, oh.reference),'Y',oh.reference,null),
to_char(oh.dateshipped,'YYYYMMDD'),
to_char(oh.dateshipped,'HHMISS'),
oh.qtyship,
zoe.sum_shipping_weight(orderid,shipid),
'LB',
oh.cubeship,
'CF',
0,
'CT',
F.name,
F.facility,
C.name,
' ',
oh.HDRPASSTHRUCHAR01,
oh.HDRPASSTHRUCHAR02,
oh.HDRPASSTHRUCHAR03,
oh.HDRPASSTHRUCHAR04,
oh.HDRPASSTHRUCHAR05,
oh.HDRPASSTHRUCHAR06,
oh.HDRPASSTHRUCHAR07,
oh.HDRPASSTHRUCHAR08,
oh.HDRPASSTHRUCHAR09,
oh.HDRPASSTHRUCHAR10,
oh.HDRPASSTHRUCHAR11,
oh.HDRPASSTHRUCHAR12,
oh.HDRPASSTHRUCHAR13,
oh.HDRPASSTHRUCHAR14,
oh.HDRPASSTHRUCHAR15,
oh.HDRPASSTHRUCHAR16,
oh.HDRPASSTHRUCHAR17,
oh.HDRPASSTHRUCHAR18,
oh.HDRPASSTHRUCHAR19,
oh.HDRPASSTHRUCHAR20,
oh.HDRPASSTHRUNUM01,
oh.HDRPASSTHRUNUM02,
oh.HDRPASSTHRUNUM03,
oh.HDRPASSTHRUNUM04,
oh.HDRPASSTHRUNUM05,
oh.HDRPASSTHRUNUM06,
oh.HDRPASSTHRUNUM07,
oh.HDRPASSTHRUNUM08,
oh.HDRPASSTHRUNUM09,
oh.HDRPASSTHRUNUM10,
oh.HDRPASSTHRUDATE01,
oh.HDRPASSTHRUDATE02,
oh.HDRPASSTHRUDATE03,
oh.HDRPASSTHRUDATE04,
oh.HDRPASSTHRUDOLL01,
oh.HDRPASSTHRUDOLL02,
l.trailer,
l.seal,
zim7.pallet_count(oh.loadno,oh.custid,oh.fromfacility,oh.orderid,oh.shipid),
0, -- zim14 call
' ', --L.lateshipreason,
oh.carrier||oh.deliveryservice,
0, -- shippingcost
--decode(nvl(ca.multiship,'N'),'Y',
--   substr(zoe.order_trackingnos(oh.orderid,oh.shipid),1,1000),
-- nvl(oh.prono,nvl(l.prono,to_char(oh.orderid) || '-' || to_char(oh.shipid)))),
' ',
F.addr1,
F.city,
F.state,
F.postalcode,
F.countrycode,
C.name,
C.addr1,
C.addr2,
C.city,
C.state,
C.postalcode,
C.countrycode,
oh.qtyship,
oh.qtyorder,
oh.qtyorder - oh.qtyship,
oh.cancel_after,
oh.delivery_requested,
oh.Requested_ship,
oh.ship_not_before,
oh.ship_no_later,
oh.cancel_if_not_delivered_by,
oh.do_not_deliver_after,
oh.do_not_deliver_before,
oh.Cancelled_date,
substr(nvl(substr(c.manufacturerucc,1,7), '0400000') ||
  lpad(nvl(substr(rtrim(oh.hdrpassthruchar09),1,4), ' ') ||
  L.loadno,9,'0'),1,17)
from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = L.loadno(+)
  and oh.fromfacility = F.facility(+)
  and oh.custid = C.custid(+)
  and OH.shipto = CN.consignee(+);

comment on table ship_nt_945_hdr is '$Id$';

create or replace view alps.ship_nt_945_lxd
(orderid
,shipid
,custid
,assignedid
)
as
select
oh.orderid,
oh.shipid,
oh.custid,
d.dtlpassthrunum10
from orderdtl d, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid;

comment on table ship_nt_945_lxd is '$Id$';

create or replace view alps.ship_nt_945_dtl
(orderid
,shipid
,custid
,assignedid
,shipticket
,trackingno
,servicecode
,lbs
,kgs
,gms
,ozs
,item
,lotnumber
,link_lotnumber
,inventoryclass
,statuscode
,reference
,linenumber
,orderdate
,po
,qtyorder
,qtyshipped
,qtydiff
,uom
,packlistshipdate
,weight
,weightquaifier
,weightunit
,description
,upc
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
,fromlpid
,smallpackagelbs
,deliveryservice
,entereduom
,qtyshippedEUOM
,masterbill
)
as
select
oh.orderid,
oh.shipid,
oh.custid,
d.dtlpassthrunum10,
substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15),
decode(nvl(ca.multiship,'N'),'Y',substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),
  nvl(oh.prono,to_char(oh.orderid) || '-' || to_char(oh.shipid))),
nvl(oh.deliveryservice,'OTHR'),
d.weightship,
d.weightship / 2.2046,
d.weightship / .0022046,
d.weightship * 16,
d.item,
d.lotnumber,
nvl(d.lotnumber,'(none)'),
d.inventoryclass,
decode(D.linestatus, 'X','CU',
    decode(nvl(d.qtyship,0), 0,'DS',
    decode(zim7.split_item(oh.custid, oh.reference, d.item), 'Y','SS','CC'))),
oh.reference,
nvl(d.dtlpassthruchar13,'000000'),
oh.entrydate,
oh.po,
d.qtyentered,
d.qtyship,
d.qtyship - d.qtyentered,
d.uom,
oh.packlistshipdate,
d.weightship,
'G',
'L',
nvl(d.dtlpassthruchar10, i.descr),
U.upc
,D.DTLPASSTHRUCHAR01
,D.DTLPASSTHRUCHAR02
,D.DTLPASSTHRUCHAR03
,D.DTLPASSTHRUCHAR04
,D.DTLPASSTHRUCHAR05
,D.DTLPASSTHRUCHAR06
,D.DTLPASSTHRUCHAR07
,D.DTLPASSTHRUCHAR08
,D.DTLPASSTHRUCHAR09
,D.DTLPASSTHRUCHAR10
,D.DTLPASSTHRUCHAR11
,D.DTLPASSTHRUCHAR12
,D.DTLPASSTHRUCHAR13
,D.DTLPASSTHRUCHAR14
,D.DTLPASSTHRUCHAR15
,D.DTLPASSTHRUCHAR16
,D.DTLPASSTHRUCHAR17
,D.DTLPASSTHRUCHAR18
,D.DTLPASSTHRUCHAR19
,D.DTLPASSTHRUCHAR20
,D.DTLPASSTHRUNUM01
,D.DTLPASSTHRUNUM02
,D.DTLPASSTHRUNUM03
,D.DTLPASSTHRUNUM04
,D.DTLPASSTHRUNUM05
,D.DTLPASSTHRUNUM06
,D.DTLPASSTHRUNUM07
,D.DTLPASSTHRUNUM08
,D.DTLPASSTHRUNUM09
,D.DTLPASSTHRUNUM10
,D.DTLPASSTHRUDATE01
,D.DTLPASSTHRUDATE02
,D.DTLPASSTHRUDATE03
,D.DTLPASSTHRUDATE04
,D.DTLPASSTHRUDOLL01
,D.DTLPASSTHRUDOLL02
,'123456789012345'
,0 -- zim14.freight_weight(d.orderid,d.shipid,d.item,d.lotnumber,'Y')
,' ' -- substr(zim14.delivery_service(d.orderid,d.shipid,d.item,d.lotnumber),1,10)
,D.uomentered
,zcu.equiv_uom_qty(D.custid,D.item,D.uom,D.qtyship,D.uomentered)
,decode(zim7.load_orders(L.loadno), 'Y',L.loadno,null)
from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh, loads L
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid
  and oh.loadno = L.loadno(+)
  and oh.carrier = ca.carrier(+)
  and d.custid = i.custid(+)
  and d.item = i.item(+)
  and D.custid = U.custid(+)
  and D.item = U.item(+);

comment on table ship_nt_945_dtl is '$Id$';

create or replace view alps.ship_nt_945_lot
(orderid
,shipid
,custid
,assignedid
,item
,lotnumber
,link_lotnumber
,qtyshipped
,qtyordered
,qtydiff
)
as
select
oh.orderid,
oh.shipid,
oh.custid,
d.dtlpassthrunum10,
d.item,
d.lotnumber,
nvl(d.lotnumber,'(none)'),
d.qtyship,
d.qtyorder,
d.qtyorder - d.qtyship
from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid
  and oh.carrier = ca.carrier(+)
  and d.custid = i.custid(+)
  and d.item = i.item(+)
  and D.custid = U.custid(+)
  and D.item = U.item(+);

comment on table ship_nt_945_lot is '$Id$';

create or replace view alps.ship_nt_945_man
(orderid
,shipid
,custid
,assignedid
,item
,lotnumber
,lp_scanout
,lp_scanin
,useritem1
,useritem2
,useritem3
,link_lotnumber
,serialnumber
,dtlpassthruchar01
)
as
select
s.orderid,
s.shipid,
s.custid,
d.dtlpassthrunum10,
s.item,
s.lotnumber,
s.lastupdate,
dp.creationdate,
dp.useritem1,
dp.useritem2,
dp.useritem3,
nvl(s.lotnumber,'(none)'),
s.serialnumber,
d.dtlpassthruchar01
from shippingplate s, orderhdr oh, orderdtl d, deletedplate dp
where oh.orderstatus = '9'
  and oh.orderid = s.orderid
  and oh.shipid = s.shipid
  and s.fromlpid = dp.lpid
  and d.orderid = oh.orderid
  and d.shipid = oh.shipid
  and d.item = s.item
  and nvl(d.lotnumber,'(none)') = nvl(s.lotnumber,'(none)')
  and s.status||'' = 'SH'
  and s.serialnumber is not null;

comment on table ship_nt_945_man is '$Id$';

create or replace view alps.ship_nt_945_s18
(orderid
,shipid
,custid
,item
,lotnumber
,link_lotnumber
,sscc18
)
as
select
s.orderid,
s.shipid,
s.custid,
s.item,
s.lotnumber,
nvl(s.lotnumber,'(none)'),
s.barcode
from caselabels s, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = s.orderid
  and oh.shipid = s.shipid
  and s.barcode is not null;

comment on table ship_nt_945_s18 is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_nt_945_hd
(custid
,company
,warehouse
,loadno
,orderid
,shipid
,reference
,hdr_trackingno
,dateshipped
,commitdate
,shipviacode
,hdr_lbs
,hdr_kgs
,hdr_gms
,hdr_ozs
,hdr_shipticket
,height
,width
,length
,shiptoidcode
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
,carrier_name
,packlistshipdate
,routing
,shiptype
,shipterms
,reportingcode
,depositororder
,po
,deliverydate
,estdelivery
,billoflading
,prono
,masterbol
,splitshipno
,invoicedate
,effectivedate
,totalunits
,totalweight
,uomweight
,totalvolume
,uomvolume
,ladingqty
,hdr_uom
,warehouse_name
,warehouse_id
,depositor_name
,depositor_id
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
,trailer
,seal
,palletcount
,freightcost
,assignedid
,shipticket
,trackingno
,servicecode
,lbs
,kgs
,gms
,ozs
,item
,lotnumber
,link_lotnumber
,statuscode
,linenumber
,orderdate
,qtyordered
,qtyshipped
,qtydifference
,uom
,weight
,weightquaifier
,weightunit
,description
,upc
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
,fromlpid
,smallpackagelbs
,deliveryservice
)
as
select
hdr.custid
,company
,warehouse
,loadno
,hdr.orderid
,hdr.shipid
,hdr.reference
,hdr.trackingno
,dateshipped
,commitdate
,shipviacode
,hdr.lbs
,hdr.kgs
,hdr.gms
,hdr.ozs
,hdr.shipticket
,height
,width
,length
,shiptoidcode
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
,carrier_name
,hdr.packlistshipdate
,routing
,shiptype
,shipterms
,reportingcode
,depositororder
,hdr.po
,deliverydate
,estdelivery
,billoflading
,prono
,masterbol
,splitshipno
,invoicedate
,effectivedate
,totalunits
,totalweight
,uomweight
,totalvolume
,uomvolume
,ladingqty
,hdr.uom
,warehouse_name
,warehouse_id
,depositor_name
,depositor_id
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
,trailer
,seal
,palletcount
,freightcost
,assignedid
,dtl.shipticket
,dtl.trackingno
,servicecode
,dtl.lbs
,dtl.kgs
,dtl.gms
,dtl.ozs
,item
,lotnumber
,link_lotnumber
,statuscode
,linenumber
,orderdate
,qtyorder
,qtyshipped
,qtydiff
,dtl.uom
,weight
,weightquaifier
,weightunit
,description
,upc
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
,fromlpid
,smallpackagelbs
,deliveryservice
from ship_nt_945_dtl dtl, ship_nt_945_hdr hdr
where hdr.orderid = dtl.orderid
  and hdr.shipid = dtl.shipid;

comment on table ship_nt_945_hd is '$Id$';

create or replace view alps.ship_nt_945_rtv
(orderid
,shipid
,custid
,item
,lotnumber
,lp_scanout
,lp_scanin
,useritem1
,useritem2
,useritem3
,link_lotnumber
,serialnumber
,reference
)
as
select
s.orderid,
s.shipid,
s.custid,
s.item,
s.lotnumber,
s.lastupdate,
dp.creationdate,
dp.useritem1,
dp.useritem2,
dp.useritem3,
nvl(s.lotnumber,'(none)'),
s.serialnumber,
oh.reference
from shippingplate s, orderhdr oh, orderdtl d, deletedplate dp
where oh.orderstatus = '9'
  and oh.orderid = s.orderid
  and oh.shipid = s.shipid
  and s.fromlpid = dp.lpid
  and d.orderid = oh.orderid
  and d.shipid = oh.shipid
  and d.item = s.item
  and s.status||'' = 'SH'
  and s.serialnumber is not null;

comment on table ship_nt_945_rtv is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_nt_945_trl
(
    orderid,
    shipid,
    custid,
    hdr_count,
    dtl_count,
    lot_count,
    lxd_count,
    man_count,
    s18_count
)
as
select
    orderid,
    shipid,
    custid,
    (select count(1) from ship_nt_945_hdr),
    (select count(1) from ship_nt_945_dtl),
    (select count(1) from ship_nt_945_lot),
    (select count(1) from ship_nt_945_lxd),
    (select count(1) from ship_nt_945_man),
    (select count(1) from ship_nt_945_s18)
 from dual, orderhdr;

comment on table ship_nt_945_trl is '$Id$';

exit;

