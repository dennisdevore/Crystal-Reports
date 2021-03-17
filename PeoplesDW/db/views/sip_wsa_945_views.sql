-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zimsip.begin_sip_wsa_945/zimsip.end_sip_wsa_945
create or replace view sip_wsa_945_ho
(
custid,
loadno,
orderid,
shipid,
po,
statusupdate,
reference,
shiptoname,
shiptocontact,
shiptoaddr1,
shiptoaddr2,
shiptocity,
shiptostate,
shiptopostalcode,
shiptocountrycode,
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
orderstatus,
qtyship,
weightship,
cubeship,
carrier,
shipto,
trailer,
seal,
sip_consignee,
sip_tradingpartnerid,
sip_shipment_identifier
)
as
select
orderhdr.custid,
orderhdr.loadno,
orderid,
shipid,
po,
orderhdr.statusupdate,
reference,
shiptoname,
shiptocontact,
shiptoaddr1,
shiptoaddr2,
shiptocity,
shiptostate,
shiptopostalcode,
shiptocountrycode,
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
orderstatus,
orderhdr.qtyship,
orderhdr.weightship,
orderhdr.cubeship,
nvl(loads.carrier,orderhdr.carrier),
orderhdr.shipto,
loads.trailer,
loads.seal,
zimsip.sip_consignee_match(orderhdr.custid, orderhdr.orderid, orderhdr.shipid),
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(orderhdr.orderid,orderhdr.shipid),1,9)
from customer cu, loads, orderhdr
where ordertype = '0'
  and orderhdr.loadno = loads.loadno(+);

comment on table sip_wsa_945_ho is '$Id$';

create or replace view sip_wsa_945_rr
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,reference_qualifier
,reference_id
,reference_descr
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
'xxx',
oh.reference,
substr(oh.hdrpassthruchar01,1,45)
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_wsa_945_rr is '$Id$';

create or replace view sip_wsa_945_dr
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,date_qualifier
,date_value
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
'xxx',
oh.shipdate
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_wsa_945_dr is '$Id$';

create or replace view sip_wsa_945_hd
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,shiptype
,carrier
,carrier_routing
,shipterms
,oh_carrier
,orig_carrier
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
oh.shiptype,
nvl(ld.carrier,oh.carrier),
hdrpassthruchar10,
oh.shipterms,
oh.carrier,
hdrpassthruchar18
from loads ld, customer cu, orderhdr oh
where oh.custid = cu.custid(+)
  and oh.loadno = ld.loadno(+);

comment on table sip_wsa_945_hd is '$Id$';

create or replace view sip_wsa_945_hc
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,allowchrgtype
,allowchrgamt
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
'xxxx',
oh.hdrpassthrunum01
from loads ld, customer cu, orderhdr oh
where oh.custid = cu.custid(+)
  and oh.loadno = ld.loadno(+);

comment on table sip_wsa_945_hc is '$Id$';

create or replace view sip_wsa_945_ha
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,address_type
,location_qualifier
,location_number
,name
,addr1
,addr2
,city
,state
,postalcode
,countrycode
,contact
,phone
,fax
,email
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
'xx',
'yy',
hdrpassthruchar11,
shiptoname,
shiptoaddr1,
shiptoaddr2,
shiptocity,
shiptostate,
shiptopostalcode,
shiptocountrycode,
shiptocontact,
shiptophone,
shiptofax,
shiptoemail
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_wsa_945_ha is '$Id$';

CREATE OR REPLACE VIEW ALPS.SIP_WSA_945_LI
(
    ORDERID,
    SHIPID,
    SIP_TRADINGPARTNERID,
    SIP_SHIPMENT_IDENTIFIER,
    ITEM,
    LOTNUMBER,
    LINE_NUMBER,
    PART1_QUALIFIER,
    PART1_ITEM,
    PART2_QUALIFIER,
    PART2_ITEM,
    PART3_QUALIFIER,
    PART3_ITEM,
    PART4_QUALIFIER,
    PART4_ITEM,
    PART_DESCR1,
    PART_DESCR2,
    SHIPMENT_STATUS,
    QTYORDER,
    QTYSHIP,
    QTYDIFF,
    UOMSHIP,
    CASEUPC,
    WEIGHTSHIP,
    SHIPDATE,
    WEIGHT1_QUALIFIER,
    WEIGHT1_UNIT_CODE
)
AS
select
oh.orderid,
oh.shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
od.item,
od.lotnumber,
dtlpassthrunum10,
dtlpassthruchar01,
dtlpassthruchar02,
dtlpassthruchar03,
dtlpassthruchar04,
dtlpassthruchar05,
dtlpassthruchar06,
dtlpassthruchar07,
dtlpassthruchar08,
dtlpassthruchar09,
dtlpassthruchar10,
'xx',
od.qtyorder,
od.qtyship,
(od.qtyorder - od.qtyship),
od.uom,
cupc.upc,
od.weightship,
oh.statusupdate,
case when od.weightship is not null then 'G' else '' end,
case when od.weightship is not null then 'L' else '' end
from custitemupcview cupc, custitem ci, customer cu, orderhdr oh, orderdtl od
where oh.orderid = od.orderid
  and oh.shipid = od.shipid
  and oh.custid = cu.custid(+);

comment on table SIP_WSA_945_LI is '$Id$';

create or replace view sip_wsa_945_ad
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,item
,lotnumber
,expirationdate
,line_number
,qtyship
,ucc128
,trackingno
)
as
select
oh.orderid,
oh.shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
od.item,
od.lotnumber,
od.lastupdate,
dtlpassthrunum10,
od.qtyship,
case when oh.shiptype in ('A','P','S')
 then substr(zedi.get_sscc18_code(oh.custid,'0',sp.parentlpid),1,20)
 else substr(zedi.get_sscc18_code(oh.custid,'1',sp.parentlpid),1,20) end,
sp.trackingno
from orderdtl od, shippingplate sp, customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_wsa_945_ad is '$Id$';

create or replace view sip_wsa_945_lr
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,item
,lotnumber
,line_number
,reference_qualifier
,reference_id
,reference_descr
,ucc128
)
as
select
oh.orderid,
oh.shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
od.item,
od.lotnumber,
dtlpassthrunum10,
'xxx',
'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
case when oh.shiptype in ('A','P','S')
  then substr(zedi.get_sscc18_code(oh.custid,'0',sp.parentlpid),1,20)
  else substr(zedi.get_sscc18_code(oh.custid,'1',sp.parentlpid),1,20) end
from orderdtl od, shippingplate sp, customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_wsa_945_lr is '$Id$';

create or replace view sip_wsa_945_st
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,qtyship
,weightship
,weightuom
,cubeship
,cubeuom
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
qtyship,
weightship,
'LB',
cubeship,
'CF'
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_wsa_945_st is '$Id$';

exit;

