CREATE OR REPLACE VIEW ld_tdr_204_hdr
(reference
,po
,carrier
,orderid_shipid
,status
,shiptype
,custid
,shipterms
,shipdate
,totalunits
,totalweight
,totalvolume
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
,HDRPASSTHRUCHAR21
,HDRPASSTHRUCHAR22
,HDRPASSTHRUCHAR23
,HDRPASSTHRUCHAR24
,HDRPASSTHRUCHAR25
,HDRPASSTHRUCHAR26
,HDRPASSTHRUCHAR27
,HDRPASSTHRUCHAR28
,HDRPASSTHRUCHAR29
,HDRPASSTHRUCHAR30
,HDRPASSTHRUCHAR31
,HDRPASSTHRUCHAR32
,HDRPASSTHRUCHAR33
,HDRPASSTHRUCHAR34
,HDRPASSTHRUCHAR35
,HDRPASSTHRUCHAR36
,HDRPASSTHRUCHAR37
,HDRPASSTHRUCHAR38
,HDRPASSTHRUCHAR39
,HDRPASSTHRUCHAR40
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
,orderid
,shipid
,loadno
,arrivaldate
,cancel_after
,ship_no_later
,delivery_requested
,cancel_if_not_delivered_by
,requested_ship
,do_not_deliver_after
,ship_not_before
,do_not_deliver_before
,comment1
,bolcomment
,total_estimated_pallet_count
)
as
select
oh.reference,
oh.po,
oh.carrier,
oh.orderid || '-' || oh.shipid,
oh.orderstatus,
oh.shiptype,
oh.custid,
oh.shipterms,
oh.shipdate,
oh.qtyship,
zoe.sum_shipping_weight(orderid,shipid),
oh.cubeship,
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
oh.HDRPASSTHRUCHAR21,
oh.HDRPASSTHRUCHAR22,
oh.HDRPASSTHRUCHAR23,
oh.HDRPASSTHRUCHAR24,
oh.HDRPASSTHRUCHAR25,
oh.HDRPASSTHRUCHAR26,
oh.HDRPASSTHRUCHAR27,
oh.HDRPASSTHRUCHAR28,
oh.HDRPASSTHRUCHAR29,
oh.HDRPASSTHRUCHAR30,
oh.HDRPASSTHRUCHAR31,
oh.HDRPASSTHRUCHAR32,
oh.HDRPASSTHRUCHAR33,
oh.HDRPASSTHRUCHAR34,
oh.HDRPASSTHRUCHAR35,
oh.HDRPASSTHRUCHAR36,
oh.HDRPASSTHRUCHAR37,
oh.HDRPASSTHRUCHAR38,
oh.HDRPASSTHRUCHAR39,
oh.HDRPASSTHRUCHAR40,
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
oh.orderid,
oh.shipid,
nvl(oh.loadno,0),
oh.arrivaldate,
oh.cancel_after,
oh.ship_no_later,
oh.delivery_requested,
oh.cancel_if_not_delivered_by,
oh.requested_ship,
oh.do_not_deliver_after,
oh.ship_not_before,
oh.do_not_deliver_before,
oh.comment1,
(select bolcomment from orderhdrbolcomments where orderid = oh.orderid and shipid = oh.shipid),
0 
from orderhdr oh;
comment on table ld_tdr_204_hdr is '$Id: ld_tdr_204.sql 7542 2011-11-14 19:09:56Z jeff $';

CREATE OR REPLACE VIEW ld_tdr_204_addr
(orderid
,shipid
,custid
,loadno
,qualifier
,code
,name
,contact
,addr1
,addr2
,city
,state
,postalcode
,countrycode
,phone
)
as
select
oh.orderid,
oh.shipid,
oh.custid,
nvl(oh.loadno,0),
'SH',
oh.shipto,
decode(CN.consignee,null,shiptoname,CN.name),
decode(CN.consignee,null,shiptocontact,CN.contact),
decode(CN.consignee,null,shiptoaddr1,CN.addr1),
decode(CN.consignee,null,shiptoaddr2,CN.addr2),
decode(CN.consignee,null,shiptocity,CN.city),
decode(CN.consignee,null,shiptostate,CN.state),
decode(CN.consignee,null,shiptopostalcode,CN.postalcode),
decode(CN.consignee,null,shiptocountrycode,CN.countrycode),
decode(CN.consignee,null,shiptophone,CN.phone)
from consignee CN, orderhdr oh
where OH.shipto = CN.consignee(+);

comment on table ld_tdr_204_addr is '$Id: ld_tdr_204.sql 7542 2011-11-14 19:09:56Z jeff $';

create or replace view alps.ld_tdr_204_dtl
(orderid
,shipid
,custid
,loadno
,assignedid
,servicecode
,lbs
,kgs
,gms
,ozs
,item
,lotnumber
,link_lotnumber
,reference
,linenumber
,orderdate
,po
,qtyordered
,qtyshipped
,qtydiff
,uom
,packlistshipdate
,weight
,weightqualifier
,weightunit
,description
,upc
,nmfc
,freightclass
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
,deliveryservice
,entereduom
,qtytotcommit
,palletcount
,totcases
)
as
select
oh.orderid,
oh.shipid,
oh.custid,
nvl(oh.loadno,0),
d.dtlpassthrunum10,
nvl(oh.deliveryservice,'OTHR'),
d.weightship,
d.weightship / 2.2046,
d.weightship / .0022046,
d.weightship * 16,
d.item,
d.lotnumber,
nvl(d.lotnumber,'(none)'),
oh.reference,
d.dtlpassthrunum10,
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
i.descr,
U.upc,
'          ',
'          '
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
,substr(zim14.delivery_service(d.orderid,d.shipid,d.item,d.lotnumber),1,10)
,D.uomentered
,D.qtytotcommit
,0
,zlbl.uom_qty_conv(d.custid, d.item, d.qtyorder, d.uom, 'CS') 
from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid
  and oh.carrier = ca.carrier(+)
  and d.custid = i.custid(+)
  and d.item = i.item(+)
  and D.custid = U.custid(+)
  and D.item = U.item(+);

comment on table ld_tdr_204_dtl is '$Id: ld_tdr_204.sql 7542 2011-11-14 19:09:56Z jeff $';

create or replace view load_tdr_204_nte
(orderid
,shipid
,custid
,comment1
,bolcomment
)
as
select
oh.orderid
,oh.shipid
,oh.custid
,oh.comment1
,(select bolcomment from orderhdrbolcomments where orderid = oh.orderid and shipid = oh.shipid)
from orderhdr oh
where oh.orderstatus = '9';

exit;

