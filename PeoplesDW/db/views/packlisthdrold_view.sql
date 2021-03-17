create or replace view packlisthdrold
(
OH_ORDERID
,OH_SHIPID
,OH_ENTRYDATE
,OH_REFERENCE
,CN_NAME
,CN_ADDR1
,CN_ADDR2
,CN_CITY
,CN_STATE
,CN_POSTALCODE
,CN_COUNTRYCODE
,CN_PHONE
,OH_TAX
,OH_SHIPPING
,OH_TOTAL
,OH_HDRPASSTHRUCHAR15
,OH_HDRPASSTHRUCHAR16
,OH_HDRPASSTHRUCHAR17
,OH_HDRPASSTHRUCHAR18
,OH_HDRPASSTHRUCHAR19
,OH_LASTPICKLABEL
,OH_PACKLISTSHIPDATE
,MC_DELSERVICEDESCR
,LINENUMBER
,ORDERITEM
,ORDERLOTNUMBER
,CUSTID
,DESCRIPTION
,DTLPASSTHRUCHAR01
,QUANTITY
,UNITOFMEASURE
,UNITAMOUNT
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
,BASEUOM
,CASES
,EQUIVQTYSHIPPED
,QTYORDERED
,QTYSHIPPED
,QTYENTERED
)
as
select
OH.orderid,
OH.shipid,
OH.entrydate,
OH.reference,
decode(OH.shiptoname,null,CN.name,OH.shiptoname),
decode(OH.shiptoname,null,CN.addr1, OH.shiptoaddr1),
decode(OH.shiptoname,null,CN.addr2, OH.shiptoaddr2),
decode(OH.shiptoname,null,CN.city, OH.shiptocity),
decode(OH.shiptoname,null,CN.state, OH.shiptostate),
decode(OH.shiptoname,null,CN.postalcode, OH.shiptopostalcode),
decode(OH.shiptoname,null,CN.countrycode, OH.shiptocountrycode),
decode(OH.shiptoname,null,CN.phone, OH.shiptophone),
OH.hdrpassthruchar01,
OH.hdrpassthruchar02,
OH.hdrpassthruchar03,
OH.hdrpassthruchar15,
OH.hdrpassthruchar16,
OH.hdrpassthruchar17,
OH.hdrpassthruchar18,
OH.hdrpassthruchar19,
zoe.last_pick_label(OH.orderid,OH.shipid),
OH.packlistshipdate,
MC.descr,
nvl(OL.dtlpassthrunum10,OD.dtlpassthrunum10),
OD.item,
nvl(OD.lotnumber,'(none)'),
OD.custid,
nvl(CI.descr,OD.item),
nvl(OD.dtlpassthruchar01,nvl(CI.descr,OD.item)),
nvl(OL.qty,nvl(OD.qtyship,0)),
OD.uomentered,
nvl(OL.dtlpassthrunum01,nvl(OD.dtlpassthrunum01,0)),
OH.hdrpassthruchar04,
OH.hdrpassthruchar05,
OH.hdrpassthruchar06,
OH.hdrpassthruchar07,
OH.hdrpassthruchar08,
OH.hdrpassthruchar09,
OH.hdrpassthruchar10,
OH.hdrpassthruchar11,
OH.hdrpassthruchar12,
OH.hdrpassthruchar13,
OH.hdrpassthruchar14,
OH.hdrpassthruchar20,
OH.hdrpassthrunum01,
OH.hdrpassthrunum02,
OH.hdrpassthrunum03,
OH.hdrpassthrunum04,
OH.hdrpassthrunum05,
OH.hdrpassthrunum06,
OH.hdrpassthrunum07,
OH.hdrpassthrunum08,
OH.hdrpassthrunum09,
OH.hdrpassthrunum10,
OD.uom,
zcu.equiv_uom_qty(OD.custid,OD.item,OD.uom,nvl(OD.qtyship,0),'CS'),
zcu.equiv_uom_qty(OD.custid,OD.item,OD.uom,nvl(OD.qtyship,0),OD.uomentered),
OD.qtyorder,
OD.qtyship,
nvl(OD.qtyentered,nvl(OD.qtyship,0))
from consignee CN, multishiphdr MH, carrierservicecodes MC, custitem CI,
 orderdtl OD, orderdtlline OL, orderhdr OH
where OH.shipto = CN.consignee(+)
  and OH.orderid = MH.orderid(+)
  and OH.shipid = MH.shipid(+)
  and OH.carrier = MC.carrier(+)
  and OH.deliveryservice = MC.servicecode(+)
  and (OH.orderstatus = '8' or OH.orderstatus = '9')
  and OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,' ') = nvl(OL.lotnumber(+),' ')
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+)
  and OD.linestatus != 'X'

/
comment on table packlisthdrold is '$Id';
exit
