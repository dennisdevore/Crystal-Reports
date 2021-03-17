
CREATE OR REPLACE VIEW ALPS.ord_stat_870_hdr
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
,HDRPASSTHRUCHAR41
,HDRPASSTHRUCHAR42
,HDRPASSTHRUCHAR43
,HDRPASSTHRUCHAR44
,HDRPASSTHRUCHAR45
,HDRPASSTHRUCHAR46
,HDRPASSTHRUCHAR47
,HDRPASSTHRUCHAR48
,HDRPASSTHRUCHAR49
,HDRPASSTHRUCHAR50
,HDRPASSTHRUCHAR51
,HDRPASSTHRUCHAR52
,HDRPASSTHRUCHAR53
,HDRPASSTHRUCHAR54
,HDRPASSTHRUCHAR55
,HDRPASSTHRUCHAR56
,HDRPASSTHRUCHAR57
,HDRPASSTHRUCHAR58
,HDRPASSTHRUCHAR59
,HDRPASSTHRUCHAR60
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
,lateshipreason
,carrier_del_serv
,shippingcost
,prono_or_all_trackingnos
,shipfrom_addr1
,shipfrom_addr2
,shipfrom_city
,shipfrom_state
,shipfrom_postalcode
,invoicenumber810
,invoiceamount810
,vicsbolnumber
,scac
,authorizationnbr
,link_shipment
,link_aux_shipment
,delivery_requested
,orderstatus
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
oh.HDRPASSTHRUCHAR41,
oh.HDRPASSTHRUCHAR42,
oh.HDRPASSTHRUCHAR43,
oh.HDRPASSTHRUCHAR44,
oh.HDRPASSTHRUCHAR45,
oh.HDRPASSTHRUCHAR46,
oh.HDRPASSTHRUCHAR47,
oh.HDRPASSTHRUCHAR48,
oh.HDRPASSTHRUCHAR49,
oh.HDRPASSTHRUCHAR50,
oh.HDRPASSTHRUCHAR51,
oh.HDRPASSTHRUCHAR52,
oh.HDRPASSTHRUCHAR53,
oh.HDRPASSTHRUCHAR54,
oh.HDRPASSTHRUCHAR55,
oh.HDRPASSTHRUCHAR56,
oh.HDRPASSTHRUCHAR57,
oh.HDRPASSTHRUCHAR58,
oh.HDRPASSTHRUCHAR59,
oh.HDRPASSTHRUCHAR60,
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
zim14.freight_total(oh.orderid,oh.shipid,null,null),
L.lateshipreason,
oh.carrier||oh.deliveryservice,
OH.shippingcost,
decode(nvl(ca.multiship,'N'),'Y',
    substr(zoe.order_trackingnos(oh.orderid,oh.shipid),1,1000),
  nvl(oh.prono,nvl(l.prono,to_char(oh.orderid) || '-' || to_char(oh.shipid)))),
F.addr1,
F.addr2,
F.city,
F.state,
F.postalcode,
oh.invoicenumber810,
oh.invoiceamount810,
oh.billoflading,
ca.scac,
L.ldpassthruchar01,
to_char(oh.orderid) || to_char(oh.shipid),
to_char(oh.orderid) || to_char(oh.shipid),
oh.delivery_requested,
oh.orderstatus
from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = L.loadno(+)
  and oh.fromfacility = F.facility(+)
  and oh.custid = C.custid(+)
  and OH.shipto = CN.consignee(+);

comment on table ord_stat_870_hdr is '$Id: ord_stat_870_veiws.sql 7256 2011-09-20 12:50:56Z jeff $';

create or replace view alps.ord_stat_870_dtl
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
,qtyordered
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
,DTLPASSTHRUCHAR21
,DTLPASSTHRUCHAR22
,DTLPASSTHRUCHAR23
,DTLPASSTHRUCHAR24
,DTLPASSTHRUCHAR25
,DTLPASSTHRUCHAR26
,DTLPASSTHRUCHAR27
,DTLPASSTHRUCHAR28
,DTLPASSTHRUCHAR29
,DTLPASSTHRUCHAR30
,DTLPASSTHRUCHAR31
,DTLPASSTHRUCHAR32
,DTLPASSTHRUCHAR33
,DTLPASSTHRUCHAR34
,DTLPASSTHRUCHAR35
,DTLPASSTHRUCHAR36
,DTLPASSTHRUCHAR37
,DTLPASSTHRUCHAR38
,DTLPASSTHRUCHAR39
,DTLPASSTHRUCHAR40
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
,DTLPASSTHRUNUM11
,DTLPASSTHRUNUM12
,DTLPASSTHRUNUM13
,DTLPASSTHRUNUM14
,DTLPASSTHRUNUM15
,DTLPASSTHRUNUM16
,DTLPASSTHRUNUM17
,DTLPASSTHRUNUM18
,DTLPASSTHRUNUM19
,DTLPASSTHRUNUM20
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
,QTYTOTCOMMIT
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
,D.DTLPASSTHRUCHAR21
,D.DTLPASSTHRUCHAR22
,D.DTLPASSTHRUCHAR23
,D.DTLPASSTHRUCHAR24
,D.DTLPASSTHRUCHAR25
,D.DTLPASSTHRUCHAR26
,D.DTLPASSTHRUCHAR27
,D.DTLPASSTHRUCHAR28
,D.DTLPASSTHRUCHAR29
,D.DTLPASSTHRUCHAR30
,D.DTLPASSTHRUCHAR31
,D.DTLPASSTHRUCHAR32
,D.DTLPASSTHRUCHAR33
,D.DTLPASSTHRUCHAR34
,D.DTLPASSTHRUCHAR35
,D.DTLPASSTHRUCHAR36
,D.DTLPASSTHRUCHAR37
,D.DTLPASSTHRUCHAR38
,D.DTLPASSTHRUCHAR39
,D.DTLPASSTHRUCHAR40
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
,D.DTLPASSTHRUNUM11
,D.DTLPASSTHRUNUM12
,D.DTLPASSTHRUNUM13
,D.DTLPASSTHRUNUM14
,D.DTLPASSTHRUNUM15
,D.DTLPASSTHRUNUM16
,D.DTLPASSTHRUNUM17
,D.DTLPASSTHRUNUM18
,D.DTLPASSTHRUNUM19
,D.DTLPASSTHRUNUM20
,D.DTLPASSTHRUDATE01
,D.DTLPASSTHRUDATE02
,D.DTLPASSTHRUDATE03
,D.DTLPASSTHRUDATE04
,D.DTLPASSTHRUDOLL01
,D.DTLPASSTHRUDOLL02
,'123456789012345'
,zim14.freight_weight(d.orderid,d.shipid,d.item,d.lotnumber,'Y')
,substr(zim14.delivery_service(d.orderid,d.shipid,d.item,d.lotnumber),1,10)
,D.uomentered
,zcu.equiv_uom_qty(D.custid,D.item,D.uom,D.qtyship,D.uomentered)
,D.QTYTOTCOMMIT
from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid
  and oh.carrier = ca.carrier(+)
  and d.custid = i.custid(+)
  and d.item = i.item(+)
  and D.custid = U.custid(+)
  and D.item = U.item(+);

comment on table ord_stat_870_dtl is '$Id: ord_stat_870_veiws.sql 7256 2011-09-20 12:50:56Z jeff $';

exit;
