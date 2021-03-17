-- drop view ship_note_945_man_sscc18;

CREATE OR REPLACE VIEW ALPS.ship_note_945_hdr
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
,billtoidcode
,billtoname
,billtocontact
,billtoaddr1
,billtoaddr2
,billtocity
,billtostate
,billtopostalcode
,billtocountrycode
,billtophone
,billtofax
,billtoemail
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
,ship_plate_count
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
,sscccount
,shipment
,amtcod
,consignee
,custaddr1
,custaddr2
,custcity
,custstate
,custpostalcode
,entrydate
,CONSPASSTHRUCHAR01
,ldpassthruchar01
,ldpassthruchar02
,ldpassthruchar03
,ldpassthruchar04
,ldpassthruchar05
,ldpassthruchar06
,ldpassthruchar07
,ldpassthruchar08
,ldpassthruchar09
,ldpassthruchar10
,ldpassthruchar11
,ldpassthruchar12
,ldpassthruchar13
,ldpassthruchar14
,ldpassthruchar15
,ldpassthruchar16
,ldpassthruchar17
,ldpassthruchar18
,ldpassthruchar19
,ldpassthruchar20
,ldpassthruchar21
,ldpassthruchar22
,ldpassthruchar23
,ldpassthruchar24
,ldpassthruchar25
,ldpassthruchar26
,ldpassthruchar27
,ldpassthruchar28
,ldpassthruchar29
,ldpassthruchar30
,ldpassthruchar31
,ldpassthruchar32
,ldpassthruchar33
,ldpassthruchar34
,ldpassthruchar35
,ldpassthruchar36
,ldpassthruchar37
,ldpassthruchar38
,ldpassthruchar39
,ldpassthruchar40
,ldpassthrunum01
,ldpassthrunum02
,ldpassthrunum03
,ldpassthrunum04
,ldpassthrunum05
,ldpassthrunum06
,ldpassthrunum07
,ldpassthrunum08
,ldpassthrunum09
,ldpassthrunum10
,ldpassthrudate01
,ldpassthrudate02
,ldpassthrudate03
,ldpassthrudate04
,doorloc
,cheppallets
,shipfromcountrycode
,customername
,customercountrycode
,vicssubbolnumber
,totqtyshipped
,totqtyordered
,qtydifference
,cancelafter
,requestedship
,shipnotbefore
,shipnolater
,cancelifnotdelivdby
,donotdeliverafter
,donotdeliverbefore
,cancelleddate
,lsshipto
,conspassthruchar02
,conspassthruchar03
,conspassthruchar04
,conspassthruchar05
,conspassthruchar06
,conspassthruchar07
,conspassthruchar08
,conspassthruchar09
,conspassthruchar10
,interlinecarrier
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
OH.consignee,
decode(CB.consignee,null,billtoname,CB.name),
decode(CB.consignee,null,billtocontact,CB.contact),
decode(CB.consignee,null,billtoaddr1,CB.addr1),
decode(CB.consignee,null,billtoaddr2,CB.addr2),
decode(CB.consignee,null,billtocity,CB.city),
decode(CB.consignee,null,billtostate,CB.state),
decode(CB.consignee,null,billtopostalcode,CB.postalcode),
decode(CB.consignee,null,billtocountrycode,CB.countrycode),
decode(CB.consignee,null,billtophone,CB.phone),
billtofax,
billtoemail,
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
zim7.ship_plate_count(oh.orderid, oh.shipid),
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
0,
decode(nvl(oh.loadno,0),0,to_char(oh.orderid)||''-''||to_char(oh.shipid),to_char(oh.loadno)),
oh.amtcod,
oh.consignee,
C.addr1,
C.addr2,
C.city,
C.state,
C.postalcode,
oh.entrydate,
cn.conspassthruchar01,
L.ldpassthruchar01,
L.ldpassthruchar02,
L.ldpassthruchar03,
L.ldpassthruchar04,
L.ldpassthruchar05,
L.ldpassthruchar06,
L.ldpassthruchar07,
L.ldpassthruchar08,
L.ldpassthruchar09,
L.ldpassthruchar10,
L.ldpassthruchar11,
L.ldpassthruchar12,
L.ldpassthruchar13,
L.ldpassthruchar14,
L.ldpassthruchar15,
L.ldpassthruchar16,
L.ldpassthruchar17,
L.ldpassthruchar18,
L.ldpassthruchar19,
L.ldpassthruchar20,
L.ldpassthruchar21,
L.ldpassthruchar22,
L.ldpassthruchar23,
L.ldpassthruchar24,
L.ldpassthruchar25,
L.ldpassthruchar26,
L.ldpassthruchar27,
L.ldpassthruchar28,
L.ldpassthruchar29,
L.ldpassthruchar30,
L.ldpassthruchar31,
L.ldpassthruchar32,
L.ldpassthruchar33,
L.ldpassthruchar34,
L.ldpassthruchar35,
L.ldpassthruchar36,
L.ldpassthruchar37,
L.ldpassthruchar38,
L.ldpassthruchar39,
L.ldpassthruchar40,
L.ldpassthrunum01,
L.ldpassthrunum02,
L.ldpassthrunum03,
L.ldpassthrunum04,
L.ldpassthrunum05,
L.ldpassthrunum06,
L.ldpassthrunum07,
L.ldpassthrunum08,
L.ldpassthrunum09,
L.ldpassthrunum10,
L.ldpassthrudate01,
L.ldpassthrudate02,
L.ldpassthrudate03,
L.ldpassthrudate04,
L.doorloc,
oh.qtyship, -- cheppallets placeholder
F.countrycode,
C.name,
C.countrycode,
zim7.VICSsubbolNumber(oh.orderid, oh.shipid, oh.custid),
OH.qtyship,
OH.qtyorder,
OH.qtyorder - OH.qtyship,
OH.cancel_after,
OH.requested_ship,
OH.ship_not_before,
OH.ship_no_later,
OH.cancel_if_not_delivered_by,
OH.do_not_deliver_after,
OH.do_not_deliver_before,
OH.cancelled_date,
LS.shipto,
CN.conspassthruchar02,
CN.conspassthruchar03,
CN.conspassthruchar04,
CN.conspassthruchar05,
CN.conspassthruchar06,
CN.conspassthruchar07,
CN.conspassthruchar08,
CN.conspassthruchar09,
CN.conspassthruchar10,
OH.interlinecarrier
from consignee CN, consignee CB, customer C, facility F, loads L, loadstop LS, carrier ca, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = L.loadno(+)
  and oh.loadno = LS.loadno(+)
  and oh.stopno = LS.stopno(+)
  and oh.fromfacility = F.facility(+)
  and oh.custid = C.custid(+)
  and OH.shipto = CN.consignee(+)
  and OH.consignee = CB.consignee(+);

comment on table ship_note_945_hdr is '$Id$';
CREATE OR REPLACE VIEW ALPS.ship_note_856_hdr
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
,CONSPASSTHRUCHAR01
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
cn.CONSPASSTHRUCHAR01
from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = L.loadno(+)
  and oh.fromfacility = F.facility(+)
  and oh.custid = C.custid(+)
  and OH.shipto = CN.consignee(+);

comment on table ship_note_856_hdr is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_note_945_bol
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
,CONSPASSTHRUCHAR01
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
cn.CONSPASSTHRUCHAR01
from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = L.loadno(+)
  and oh.fromfacility = F.facility(+)
  and oh.custid = C.custid(+)
  and OH.shipto = CN.consignee(+);

comment on table ship_note_945_bol is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_note_856_bol
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
,CONSPASSTHRUCHAR01
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
cn.CONSPASSTHRUCHAR01
from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh
where orderstatus = '9'
  and oh.carrier = ca.carrier(+)
  and oh.loadno = L.loadno(+)
  and oh.fromfacility = F.facility(+)
  and oh.custid = C.custid(+)
  and OH.shipto = CN.consignee(+);

comment on table ship_note_856_bol is '$Id$';

create or replace view alps.ship_note_945_lxd
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

comment on table ship_note_945_lxd is '$Id$';

create or replace view alps.ship_note_945_dtl
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
,hazardous
,productgroup
,link_assignedid
,cancelreason
,shipshortreason
,consigneesku
,gtin
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
,i.hazardous
,i.productgroup
,d.dtlpassthrunum10
,d.cancelreason
,d.shipshortreason
,d.consigneesku
,d.item -- gtin placeholder
from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid
  and oh.carrier = ca.carrier(+)
  and d.custid = i.custid(+)
  and d.item = i.item(+)
  and D.custid = U.custid(+)
  and D.item = U.item(+);

comment on table ship_note_945_dtl is '$Id$';

create or replace view alps.ship_note_945_dll -- dtl and lot should have same columns as _dtl
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
,qtyshippedUOM
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
,zim14.freight_weight(d.orderid,d.shipid,d.item,d.lotnumber,'Y')
,substr(zim14.delivery_service(d.orderid,d.shipid,d.item,d.lotnumber),1,10)
,D.uomentered
,zcu.equiv_uom_qty(D.custid,D.item,D.uom,D.qtyship,D.uomentered)
from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid
  and oh.carrier = ca.carrier(+)
  and d.custid = i.custid(+)
  and d.item = i.item(+)
  and D.custid = U.custid(+)
  and D.item = U.item(+);

comment on table ship_note_945_dll is '$Id$';

create or replace view alps.ship_note_945_lot
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
,weightshipped
,link_assignedid
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
d.qtyorder - d.qtyship,
d.weightorder,
d.dtlpassthrunum10
from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh
where oh.orderstatus = '9'
  and oh.orderid = d.orderid
  and oh.shipid = d.shipid
  and oh.carrier = ca.carrier(+)
  and d.custid = i.custid(+)
  and d.item = i.item(+)
  and D.custid = U.custid(+)
  and D.item = U.item(+);

comment on table ship_note_945_lot is '$Id$';

create or replace view alps.ship_note_945_man
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
,fromlpid
,lpid
,trackingno
,shippingcost
,weight
,quantity
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
d.dtlpassthruchar01,
s.lpid,
s.fromlpid,
s.trackingno,
s.shippingcost,
s.weight,
s.quantity
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

comment on table ship_note_945_man is '$Id$';

create or replace view alps.ship_note_945_s18
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

comment on table ship_note_945_s18 is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_note_945_hd
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
,qtydiff
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
,qtyordered
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
from ship_note_945_dtl dtl, ship_note_945_hdr hdr
where hdr.orderid = dtl.orderid
  and hdr.shipid = dtl.shipid;

comment on table ship_note_945_hd is '$Id$';

create or replace view alps.ship_note_945_rtv
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

comment on table ship_note_945_rtv is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_note_945_trl
(
    orderid,
    shipid,
    custid,
    hdr_count,
    dtl_count,
    lot_count,
    lxd_count,
    man_count,
    s18_count,
    loadno
)
as
select
    orderid,
    shipid,
    custid,
    (select count(1) from ship_note_945_hdr),
    (select count(1) from ship_note_945_dtl),
    (select count(1) from ship_note_945_lot),
    (select count(1) from ship_note_945_lxd),
    (select count(1) from ship_note_945_man),
    (select count(1) from ship_note_945_s18),
    loadno
 from dual, orderhdr;

comment on table ship_note_945_trl is '$Id$';

create or replace view ship_note_945_pal
(
   custid,
   orderid,
   shipid,
   loadno,
   pallettype,
   inpallets,
   outpallets
)
as
select
    custid,
    orderid,
    shipid,
    loadno,
    pallettype,
    inpallets,
    outpallets
  from pallethistory;


comment on table ship_note_945_pal is '$Id';



create or replace view alps.ship_note_945_dtlt
(orderid,
shipid,
custid,
qtyship,
uom,
item,
weightship,
trackingno,
freightcost) as
select orderid
,shipid
,custid
,qtyship
,uom
,item
,weightship
,' '
,zim14.freight_cost(orderdtl.orderid, orderdtl.shipid, orderdtl.item)
from orderdtl;

COMMENT ON TABLE ALPS.SHIP_NOTE_945_DTLT IS '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_note_945_fhd -- file header
(
    custid,
    orderid,
    shipid,
    loadno,
    file_sequence
)
as
select
    custid,
    orderid,
    shipid,
    loadno,
    '00000000'
 from orderhdr;

comment on table ship_note_945_fhd is '$Id$';

create or replace view ship_note_945_sn
(orderid
 ,shipid
 ,custid
 ,reference
 ,po
 ,item
 ,lotnumber
 ,quantity
 ,unitofmeasure
 ,lbs
 ,serialnumber
 ,fromlpid
 ,useritem1
 ,useritem2
 ,useritem3
 ,linenumber
 ,dtlpassthrunum10
)
as
select
   s.orderid,
   s.shipid,
   s.custid,
   oh.reference,
   oh.po,
   s.item,
   s.lotnumber,
   s.quantity,
   s.unitofmeasure,
   zci.item_weight(s.custid,s.item,s.unitofmeasure) * s.quantity,
   s.serialnumber,
   s.fromlpid,
   p.useritem1,
   p.useritem2,
   p.useritem3,
   0, -- placeholder for linenumber
   od.dtlpassthrunum10
from shippingplate s, orderhdr oh, plate p, orderdtl od
where oh.orderstatus = '9'
  and oh.orderid = s.orderid
   and oh.shipid = s.shipid
   and s.status = 'SH'
   and s.serialnumber is not null
   and p.custid = s.custid
   and p.item = s.item
   and p.lpid = s.fromlpid
   and oh.orderid = od.orderid
   and oh.shipid = od.shipid
   and od.item = s.item;

comment on table ship_note_945_sn is '$Id$';

create or replace view ship_note_945_sah
(orderid
 ,shipid
 ,sac01
 ,sac02
 ,sac03
 ,sac04
 ,sac05
 ,sac06
 ,sac07
 ,sac08
 ,sac09
 ,sac10
 ,sac11
 ,sac12
 ,sac13
 ,sac14
 ,sac15
)
as
select
   orderid,
   shipid,
   sac01,
   sac02,
   sac03,
   sac04,
   sac05,
   sac06,
   sac07,
   sac08,
   sac09,
   sac10,
   sac11,
   sac12,
   sac13,
   sac14,
   sac15
from orderhdrsac;

create or replace view ship_note_945_sad
(orderid
 ,shipid
 ,item
 ,lotnumber
 ,sac01
 ,sac02
 ,sac03
 ,sac04
 ,sac05
 ,sac06
 ,sac07
 ,sac08
 ,sac09
 ,sac10
 ,sac11
 ,sac12
 ,sac13
 ,sac14
 ,sac15
 ,dtlpassthruchar01
 ,dtlpassthruchar02
 ,dtlpassthruchar03
 ,dtlpassthruchar04
 ,dtlpassthruchar05
 ,dtlpassthruchar06
 ,dtlpassthruchar07
 ,dtlpassthruchar08
 ,dtlpassthruchar09
 ,dtlpassthruchar10
 ,dtlpassthruchar11
)
as
select
   os.orderid,
   os.shipid,
   os.item,
   os.lotnumber,
   os.sac01,
   os.sac02,
   os.sac03,
   os.sac04,
   os.sac05,
   os.sac06,
   os.sac07,
   os.sac08,
   os.sac09,
   os.sac10,
   os.sac11,
   os.sac12,
   os.sac13,
   os.sac14,
   os.sac15,
   od.dtlpassthruchar01,
   od.dtlpassthruchar02,
   od.dtlpassthruchar03,
   od.dtlpassthruchar04,
   od.dtlpassthruchar05,
   od.dtlpassthruchar06,
   od.dtlpassthruchar07,
   od.dtlpassthruchar08,
   od.dtlpassthruchar09,
   od.dtlpassthruchar10,
   od.dtlpassthruchar11
from orderdtlsac os, orderdtl od
where os.orderid = od.orderid
  and os.shipid = od.shipid
  and os.item = od.item
  and nvl(os.lotnumber,'(none)') = nvl(od.lotnumber,'(none)');

create or replace view ship_note_945_ohi
(custid
 ,orderid
 ,shipid
 ,reference
 ,po
 ,seq
 ,comment1
)
as
select
   custid,
   orderid,
   shipid,
   reference,
   po,
   1,
   null
from orderhdr;

CREATE OR REPLACE VIEW ship_note_945_ihr
(
    partneredicode,
    datetimecreated,
    custid,
    senderedicode,
    applicationsendercode
)
as
select
    null,
    null,
    custid,
    null,
    null
  from customer;

comment on table ship_note_945_ihr is '$Id$';

create or replace view SHIP_NOTE_945_FS
(custid
,loadno
,orderid
,shipid
,transaction_date
,transaction_time
,item
,itemdescr
,reference
,billoflading
,shipment_date
,shipment_time
,arrivaldate
,carriername
,manufacturedate
,assignedid
,qty
,uom
,shiptoidcode
,shiptoname
,shiptoaddr1
,shiptoaddr2
,shiptocity
,shiptostate
,shiptopostalcode
,shiptocountrycode
,lpid
,fromlpid
,lotnumber
,total_lines
,total_shipped
,weight )
as
select
   o.custid,
   o.loadno,
   o.orderid,
   o.shipid,
   to_char(sysdate,'mmddyyyy'),
   to_char(sysdate,'hh24mi'),
   c.item,
   c.itemdescr,
   o.reference,
   o.billoflading,
   to_char(o.dateshipped,'MMDDYYYY'),
   to_char(o.dateshipped,'HH24MI'),
   substr(o.deliverydate,7,2) || substr(o.deliverydate,5,2) || substr(o.deliverydate,1,4),
   o.carrier_name,
   to_char(c.manufacturedate,'MMDDYYYY'),
   c.assignedid,
   c.qty,
   c.uom,
   o.shiptoidcode,
   o.shiptoname,
   o.shiptoaddr1,
   o.shiptoaddr2,
   o.shiptocity,
   o.shiptostate,
   o.shiptopostalcode,
   o.shiptocountrycode,
   c.lpid,
   c.fromlpid,
   c.lotnumber,
   (select count(1) from SHIP_NOTE_945_CNT where orderid = c.orderid
  and shipid = c.shipid),
   (select sum(qty) from SHIP_NOTE_945_CNT where orderid = c.orderid and shipid = c.shipid),
   c.weight
   from ship_note_945_cnt c,ship_note_945_hdr o
      where c.orderid = o.orderid
        and c.shipid = o.shipid;

comment on table ship_note_945_fs is '$Id$';

create or replace view ship_note_945_spk
(custid
,orderid
,shipid
,orderdate
,dateshipped
,reference
,shiptoname
,lineitemscnt
,trackingno
,prono
,freightcost
,weight
,carrier
,qtyshipcnt
,loadno
)
as
select
hdr.custid,
hdr.orderid,
hdr.shipid,
hdr.entrydate,
hdr.dateshipped,
hdr.reference,
hdr.shiptoname,
zim14.cnt_lineitems(hdr.orderid, hdr.shipid),
hdr.trackingno,
hdr.prono,
decode (hdr.shiptype, 'S', zim14.freight_cost(hdr.orderid, hdr.shipid), null),
zim14.sum_weightship(hdr.orderid, hdr.shipid, hdr.shiptype),
decode(hdr.shiptype, 'S', zim14.get_carrier_name(hdr.carrier, hdr.shipviacode), zim14.get_carrier_name(hdr.carrier, hdr.hdrpassthruchar20)),
zim14.cnt_qtyship(hdr.orderid, hdr.shipid, hdr.shiptype),
hdr.loadno
from ship_note_945_hdr hdr;

  comment on table ship_note_945_spk is '$Id$';
create or replace view ship_note_945_cfsh
(facility
,custid
,loadno
--,orderid
--,shipid
,carrier
,authorizationnbr
,dateshipped)
as
select
 warehouse_id
,custid
,loadno
--,orderid
--,shipid
,carrier
,authorizationnbr
,dateshipped
from ship_note_945_hdr
group by warehouse_id, custid, loadno, carrier, authorizationnbr, dateshipped;

comment on table ship_note_945_cfsh is '$Id$';
 
create or replace view ship_note_945_cfsd
(loadno
,orderid
,shipid
,custid
,reference
,lotnumber
,qtyshipped)
as
select
 h.loadno
,h.orderid
,h.shipid
,h.custid
,h.reference
,nvl(d.lotnumber,'none') as lotnumber
,sum(d.qtyshipped) as qtyshipped
from ship_note_945_hdr h,
     ship_note_945_dtl d
where h.orderid = d.orderid
  and d.shipid = d.shipid
group by h.loadno, h.orderid, h.shipid, h.custid, h.reference, nvl(d.lotnumber,'none');
comment on table ship_note_945_cfsd is '$Id$';

exit;

