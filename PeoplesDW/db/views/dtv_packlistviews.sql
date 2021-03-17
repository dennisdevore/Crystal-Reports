create or replace view dtpacklisthdr
(
OH_orderid,
OH_shipid,
OH_entrydate,
OH_reference,
CN_name,
CN_addr1,
CN_addr2,
CN_city,
CN_state,
CN_postalcode,
CN_countrycode,
CN_phone,
OH_tax,
OH_shipping,
OH_total,
OH_hdrpassthruchar15,
OH_hdrpassthruchar16,
OH_hdrpassthruchar17,
OH_hdrpassthruchar18,
OH_hdrpassthruchar19,
OH_lastpicklabel,
OH_packlistshipdate,
MC_delservicedescr,
linenumber,
orderitem,
orderlotnumber,
custid,
description,
quantity,
unitofmeasure,
unitamount
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
nvl(OL.qty,nvl(OD.qtypick,0)),
OD.uomentered,
nvl(OL.dtlpassthrunum01,nvl(OD.dtlpassthrunum01,0))
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
  and nvl(OL.xdock,'N') = 'N'
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+)
  and OD.item not like 'HANDL%';

comment on table dtpacklisthdr is '$Id$';

create or replace view dtpacklist_tracking
(
orderid,
shipid,
orderitem,
orderlot,
unitofmeasure,
lotnumber,
serialnumber,
trackingno,
quantity
)
as
select
SP.orderid,
SP.shipid,
SP.orderitem,
nvl(SP.orderlot,'(none)'),
SP.unitofmeasure,
SP.lotnumber,
decode(zwv.single_shipping_units_only(SP.orderid,SP.ShipId),
       'Y',SP.serialnumber,null),
SP.trackingno,
sum(nvl(SP.quantity,0))
from shippingplate SP
where SP.type in ('P','F')
group by SP.orderid,SP.shipid,SP.orderitem,SP.orderlot,SP.unitofmeasure,
SP.lotnumber,decode(zwv.single_shipping_units_only(SP.orderid,SP.ShipId),
'Y',SP.serialnumber,null),SP.trackingno;

comment on table dtpacklist_tracking is '$Id$';

exit;

