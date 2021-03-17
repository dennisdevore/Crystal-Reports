create or replace view packlisthdr
(
OH_orderid,
OH_shipid,
OH_entrydate,
OH_reference,
CN_name,
CN_contact,
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
dtlpassthruchar01,
quantity,
unitofmeasure,
unitamount,
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
baseUOM,
cases,
equivqtyshipped,
qtyordered,
qtyshipped,
qtyentered,
weightorder,
weightship,
od_consigneesku
)
as
select
OH.orderid,
OH.shipid,
OH.entrydate,
OH.reference,
decode(OH.shiptoname,null,CN.name,OH.shiptoname),
decode(OH.shiptoname,null,CN.contact,OH.shiptocontact),
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
nvl(OD.qtyentered,nvl(OD.qtyship,0)),
OD.weightorder,
OD.weightship,
OD.consigneesku
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
  and OD.linestatus != 'X';
--  and OD.item not like 'HANDL%';

comment on table packlisthdr is '$Id$';

create or replace view preship_packlisthdr
(
OH_orderid,
OH_shipid,
OH_entrydate,
OH_reference,
CN_name,
CN_contact,
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
dtlpassthruchar01,
quantity,
unitofmeasure,
unitamount,
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
baseUOM,
cases,
equivqtyshipped,
qtyordered,
qtyshipped,
qtyentered,
weightorder,
weightship,
od_consigneesku
)
as
select
OH.orderid,
OH.shipid,
OH.entrydate,
OH.reference,
decode(OH.shiptoname,null,CN.name,OH.shiptoname),
decode(OH.shiptoname,null,CN.contact,OH.shiptocontact),
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
nvl(OL.qty,nvl(OD.qtyship,OD.qtyorder)),
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
zcu.equiv_uom_qty(OD.custid,OD.item,OD.uom,nvl(OD.qtyship,OD.qtyorder),'CS'),
zcu.equiv_uom_qty(OD.custid,OD.item,OD.uom,nvl(OD.qtyship,OD.qtyorder),OD.uomentered),
OD.qtyorder,
nvl(OD.qtyship,OD.qtyorder),
nvl(OD.qtyentered,nvl(OD.qtyship,OD.qtyorder)),
OD.weightorder,
nvl(OD.weightship,OD.weightorder),
OD.consigneesku
from consignee CN, multishiphdr MH, carrierservicecodes MC, custitem CI,
 orderdtl OD, orderdtlline OL, orderhdr OH
where OH.shipto = CN.consignee(+)
  and OH.orderid = MH.orderid(+)
  and OH.shipid = MH.shipid(+)
  and OH.carrier = MC.carrier(+)
  and OH.deliveryservice = MC.servicecode(+)
--  and (OH.orderstatus = '8' or OH.orderstatus = '9')
  and OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,' ') = nvl(OL.lotnumber(+),' ')
  and nvl(OL.xdock,'N') = 'N'
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+)
  and OD.linestatus != 'X';

comment on table preship_packlisthdr is '$Id$';

create or replace view packlist_tracking
(
orderid,
shipid,
orderitem,
orderlot,
unitofmeasure,
lotnumber,
serialnumber,
useritem1,
useritem2,
useritem3,
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
SP.serialnumber,
SP.useritem1,
SP.useritem2,
SP.useritem3,
SP.trackingno,
sum(nvl(SP.quantity,0))
from shippingplate SP
where SP.type in ('P','F')
  and SP.status = 'SH'
group by SP.orderid,SP.shipid,SP.orderitem,SP.orderlot,SP.unitofmeasure,
SP.lotnumber,SP.serialnumber,SP.useritem1,SP.useritem2,SP.useritem3,
SP.trackingno;

comment on table packlist_tracking is '$Id$';

CREATE OR REPLACE VIEW PACKLISTHDR_SHIPLOT
(OH_ORDERID,
 OH_SHIPID,
 OH_ENTRYDATE,
 OH_REFERENCE,
 CN_NAME,
 CN_CONTACT, 
 CN_ADDR1,
 CN_ADDR2,
 CN_CITY,
 CN_STATE,
 CN_POSTALCODE, 
 CN_PHONE,
 OH_HDRPASSTHRUCHAR15,
 OH_HDRPASSTHRUCHAR16,
 OH_HDRPASSTHRUCHAR17,
 OH_HDRPASSTHRUCHAR18,
 OH_HDRPASSTHRUCHAR19, 
 MC_DELSERVICEDESCR,
 LINENUMBER,
 ORDERITEM, 
 ORDERLOTNUMBER,
 CUSTID,
 DESCRIPTION,
 QUANTITY, 
 UNITOFMEASURE,
 WEIGHTSHIP,
 OD_CONSIGNEESKU)
AS 
select
OH.orderid,
OH.shipid,
OH.entrydate,
OH.reference,
decode(OH.shiptoname,null,CN.name,OH.shiptoname),
decode(OH.shiptoname,null,CN.contact,OH.shiptocontact),
decode(OH.shiptoname,null,CN.addr1, OH.shiptoaddr1),
decode(OH.shiptoname,null,CN.addr2, OH.shiptoaddr2),
decode(OH.shiptoname,null,CN.city, OH.shiptocity),
decode(OH.shiptoname,null,CN.state, OH.shiptostate),
decode(OH.shiptoname,null,CN.postalcode, OH.shiptopostalcode),
decode(OH.shiptoname,null,CN.phone, OH.shiptophone),
OH.hdrpassthruchar15,
OH.hdrpassthruchar16,
OH.hdrpassthruchar17,
OH.hdrpassthruchar18,
OH.hdrpassthruchar19,
MC.descr,
nvl(OL.dtlpassthrunum10,OD.dtlpassthrunum10),
OD.item,
SP.lotnumber,
OD.custid,
nvl(CI.descr,OD.item),
nvl(sum(SP.quantity),0),
OD.uomentered,
nvl(sum(SP.weight),0),
OD.consigneesku
from consignee CN, multishiphdr MH, carrierservicecodes MC, custitem CI,
 orderdtl OD, orderdtlline OL, orderhdr OH, shippingplate SP
where OH.shipto = CN.consignee(+)
  and OH.orderid = MH.orderid(+)
  and OH.shipid = MH.shipid(+)
  and OH.carrier = MC.carrier(+)
  and OH.deliveryservice = MC.servicecode(+)
  and OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,' ') = nvl(OL.lotnumber(+),' ')
  and nvl(OL.xdock,'N') = 'N'
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+)
  and OD.linestatus != 'X'
  and SP.orderid = OD.orderid
  and SP.shipid = OD.shipid
  and SP.item = OD.item
  and nvl(SP.orderlot,'xxx') = nvl(OD.lotnumber,'xxx')
  and SP.type in ('F','P')
group by OH.orderid,
OH.shipid,
OH.entrydate,
OH.reference,
decode(OH.shiptoname,null,CN.name,OH.shiptoname),
decode(OH.shiptoname,null,CN.contact,OH.shiptocontact),
decode(OH.shiptoname,null,CN.addr1, OH.shiptoaddr1),
decode(OH.shiptoname,null,CN.addr2, OH.shiptoaddr2),
decode(OH.shiptoname,null,CN.city, OH.shiptocity),
decode(OH.shiptoname,null,CN.state, OH.shiptostate),
decode(OH.shiptoname,null,CN.postalcode, OH.shiptopostalcode),
decode(OH.shiptoname,null,CN.phone, OH.shiptophone),
OH.hdrpassthruchar15,
OH.hdrpassthruchar16,
OH.hdrpassthruchar17,
OH.hdrpassthruchar18,
OH.hdrpassthruchar19,
MC.descr,
nvl(OL.dtlpassthrunum10,OD.dtlpassthrunum10),
OD.item,
SP.lotnumber,
OD.custid,
nvl(CI.descr,OD.item),
OD.uomentered,
OD.consigneesku;

comment on table PACKLISTHDR_SHIPLOT is '$Id$';


exit;

