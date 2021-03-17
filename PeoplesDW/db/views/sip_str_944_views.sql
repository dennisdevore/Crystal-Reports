-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zimsip.begin_sip_str_944/zimsip.end_sip_str_944
create or replace view sip_str_944_ho
(
custid,
loadno,
orderid,
shipid,
po,
statusupdate,
reference,
shippername,
shippercontact,
shipperaddr1,
shipperaddr2,
shippercity,
shipperstate,
shipperpostalcode,
shippercountrycode,
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
qtyrcvd,
weightrcvd,
cubercvd,
carrier,
shipper,
trailer,
seal,
sip_tradingpartnerid,
sip_shipment_identifier,
reporting_code
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
orderhdr.qtyrcvd,
orderhdr.weightrcvd,
orderhdr.cubercvd,
nvl(loads.carrier,orderhdr.carrier),
orderhdr.shipto,
loads.trailer,
loads.seal,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(orderhdr.orderid,orderhdr.shipid),1,9),
'X'
from customer cu, loads, orderhdr
where ordertype in ('R','C')
  and orderhdr.loadno = loads.loadno(+);

comment on table sip_str_944_ho is '$Id$';

create or replace view sip_str_944_rr
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

comment on table sip_str_944_rr is '$Id$';

create or replace view sip_str_944_dr
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

comment on table sip_str_944_dr is '$Id$';

create or replace view sip_str_944_hd
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

comment on table sip_str_944_hd is '$Id$';

create or replace view sip_str_944_ha
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

comment on table sip_str_944_ha is '$Id$';

CREATE OR REPLACE VIEW ALPS.SIP_str_944_LI
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
    QTYORDER,
    qtyrcvd,
    QTYDIFF,
    UOMRCVD,
    CASEUPC,
    weightrcvd,
    RCVDDATE,
    uomdiff,
    condition_code,
    dmgreason
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
od.qtyorder,
od.qtyrcvd,
(od.qtyorder - od.qtyrcvd),
od.uom,
cupc.upc,
od.weightrcvd,
oh.statusupdate,
'yyyy',
'zzzz',
'rrrr'
from custitemupcview cupc, custitem ci, customer cu, orderhdr oh, orderdtl od
where oh.orderid = od.orderid
  and oh.shipid = od.shipid
  and oh.custid = cu.custid(+);

comment on table SIP_str_944_LI is '$Id$';

create or replace view sip_str_944_lr
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
'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
from orderdtl od, shippingplate sp, customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_str_944_lr is '$Id$';

create or replace view sip_str_944_st
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,qtyrcvd
,weightrcvd
,weightuom
,cubercvd
,cubeuom
,qtyrcvddmgd
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
qtyrcvd,
weightrcvd,
'LB',
cubercvd,
'CF',
qtyrcvd + 1
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_str_944_st is '$Id$';

exit;

