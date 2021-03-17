-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zimsip.begin_sip_asn_856/zimsip.end_sip_asn_856
create or replace view sip_asn_856_hs
(custid
,loadno
,orderid
,shipid
,shipto
,sip_tradingpartnerid
,sip_shipment_identifier
,ship_date
,ship_time
,vendor    --hdrpassthruchar15
,ship_notice_date
,ship_notice_time
,asn_structure_code
,status_reason_code
,packing_code
,lading_quantity
,gross_weight_qualifier
,shipment_weight
,shipment_weight_uom
,equip_descr_code
,carrier_equip_initial
,carrier_equip_number
,carrier_alpha_code
,carrier_trans_method
,carrier_routing
,order_status
,bill_of_lading
,pro_number
,seal_number
,fob_pay_code
,fob_location_qualifier
,fob_location_descr
,fob_title_passage_code
,fob_title_passage_location
,appt_number
,pickup_number
,req_pickup_date
,req_pickup_time
,flex_field_1
,flex_field_2
,flex_field_3
,flex_field_4
,flex_field_5
,sched_ship_date
,sched_ship_time
,sched_delivery_date
,sched_delivery_time
)
as
select
oh.custid,
oh.loadno,
orderid,
shipid,
oh.shipto,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
oh.shipdate,
oh.statusupdate,
hdrpassthruchar15,
oh.apptdate,
oh.cancelled_date,
'bbbb',
'rrr',
'ccccc',
oh.qtyship,
'ee',
oh.qtyship,
'ff',
'gg',
'hhhh',
'iiiiiiiiii',
oh.carrier,
oh.shiptype,
deliveryservice,
'kk',
oh.billoflading,
oh.prono,
ld.seal,
'll',
'mm',
'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnn',
'oo',
'pppppppppppppppppppppppppppppp',
'qqqqqqqqqqqqqqqqqqqq',
'rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr',
oh.apptdate,
oh.entrydate,
hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar05,
oh.shipdate,
oh.shipdate,
oh.delivery_requested,
oh.delivery_requested
from loads ld, customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_asn_856_hs is '$Id$';

create or replace view sip_asn_856_ha
(custid
,loadno
,orderid
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
oh.custid,
oh.loadno,
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

comment on table sip_asn_856_ha is '$Id$';

create or replace view sip_asn_856_ho
(
custid,
loadno,
orderid,
shipid,
sip_tradingpartnerid,
sip_shipment_identifier,
po,
entrydate,
statusupdate,
reference,
orderstatus,
qtyship,
weightship,
cubeship,
pkgcount,
vendor,
prono,
packing_code,
apptdate
)
as
select
orderhdr.custid,
orderhdr.loadno,
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(orderhdr.orderid,orderhdr.shipid),1,9),
po,
orderhdr.entrydate,
orderhdr.statusupdate,
reference,
'xx',
orderhdr.qtyship,
orderhdr.weightship,
orderhdr.cubeship,
orderhdr.qtyorder,
orderhdr.hdrpassthruchar01,
orderhdr.prono,
'ccccc',
orderhdr.apptdate
from customer cu, loads, orderhdr
where ordertype = '0'
  and orderhdr.loadno = loads.loadno(+);

comment on table sip_asn_856_ho is '$Id$';

create or replace view sip_asn_856_oa
(custid
,loadno
,orderid
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
oh.custid,
oh.loadno,
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

comment on table sip_asn_856_oa is '$Id$';

create or replace view sip_asn_856_po
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,pack_level_type
,outer_pack
,inner_pack
,inner_pack_uom
,qtytotal
,weighttotal
,weight_uom
,empty_pack_weight
,cubetotal
,cubeuom
,linear_uom
,length
,width
,height
,pkg_char_code
,pkg_descr_code
,pkg_descr
,marks_qualifier1
,marks_1
,marks_qualifier2
,marks_2
,addl_descr_1
,addl_descr_2
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
'aa',
qtycommit,
qtypick,
'bb',
qtyorder,
weightorder,
'cc',
weightcommit,
cubeorder,
'dd',
'ee',
weightpick,
weightship,
weightcommit,
'fffff',
'ggggggg',
substr(shipperfax,1,80),
'hh',
substr(hdrpassthruchar01,1,48),
'ii',
substr(hdrpassthruchar02,1,48),
substr(hdrpassthruchar03,1,80),
substr(hdrpassthruchar04,1,80)
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_asn_856_po is '$Id$';

create or replace view sip_asn_856_po2
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,pack_level_type
,outer_pack
,inner_pack
,inner_pack_uom
,qtytotal
,weighttotal
,weight_uom
,empty_pack_weight
,cubetotal
,cubeuom
,linear_uom
,length
,width
,height
,pkg_char_code
,pkg_descr_code
,pkg_descr
,marks_qualifier1
,marks_1
,marks_qualifier2
,marks_2
,addl_descr_1
,addl_descr_2
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
'aa',
qtycommit,
qtypick,
'bb',
qtyorder,
weightorder,
'cc',
weightcommit,
cubeorder,
'dd',
'ee',
weightpick,
weightship,
weightcommit,
'fffff',
'ggggggg',
substr(shipperfax,1,80),
'hh',
substr(hdrpassthruchar01,1,48),
'ii',
substr(hdrpassthruchar02,1,48),
substr(hdrpassthruchar03,1,80),
substr(hdrpassthruchar04,1,80)
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_asn_856_po2 is '$Id$';

create or replace view sip_asn_856_li
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,marks_1
,item
,lotnumber
,line_number
,part1_qualifier
,part1_item
,part2_qualifier
,part2_item
,part3_qualifier
,part3_item
,part4_qualifier
,part4_item
,part_descr1
,part_descr2
,qtyorder
,qtyorder_uom
,price
,price_basis
,retail_price
,outer_pack
,inner_pack
,pack_uom
,pack_weight
,pack_weight_uom
,pack_cube
,pack_cube_uom
,pack_length
,pack_width
,pack_height
,qtyship
,qtyship_uom
,shipdate
,qtyremain
,item_total
,product_size
,product_size_descr
,product_color
,product_color_descr
,product_fabric_code
,product_fabric_descr
,product_process_code
,product_process_desc
,dept
,class
,gender
,seller_date_code
,shipment_status
,flex_field_1
,flex_field_2
,flex_field_3
,flex_field_4
,flex_field_5
)
as
select
oh.orderid,
oh.shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
substr(shipperfax,1,80),
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
'aaaa',
zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber),
'yy',
useramt2,
oh.qtyship,
oh.qtycommit,
'bbbb',
oh.weightship,
'cccc',
oh.cubeship,
'dddd',
ci.length,
ci.width,
ci.height,
od.qtyship,
'eeee',
oh.statusupdate,
(od.qtyorder - od.qtyship),
(zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber) - ci.useramt2),
'ff',
substr(dtlpassthruchar20,1,45),
'gg',
substr(dtlpassthruchar19,1,45),
'hh',
substr(dtlpassthruchar18,1,45),
'ii',
substr(dtlpassthruchar17,1,45),
'jjjjjjjjjj',
'kkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
'llllllllllllllllllllllllllllll',
'mmmmmmmm',
'xx',
dtlpassthruchar01,
dtlpassthruchar02,
dtlpassthruchar03,
dtlpassthruchar04,
dtlpassthruchar05
from custitem ci, customer cu, orderhdr oh, orderdtl od
where oh.orderid = od.orderid
  and oh.shipid = od.shipid
  and oh.custid = cu.custid(+);

comment on table sip_asn_856_li is '$Id$';

create or replace view sip_asn_856_li2
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,marks_1
,marks_2
,item
,lotnumber
,line_number
,part1_qualifier
,part1_item
,part2_qualifier
,part2_item
,part3_qualifier
,part3_item
,part4_qualifier
,part4_item
,part_descr1
,part_descr2
,qtyorder
,qtyorder_uom
,price
,price_basis
,retail_price
,outer_pack
,inner_pack
,pack_uom
,pack_weight
,pack_weight_uom
,pack_cube
,pack_cube_uom
,pack_length
,pack_width
,pack_height
,qtyship
,qtyship_uom
,shipdate
,qtyremain
,item_total
,product_size
,product_size_descr
,product_color
,product_color_descr
,product_fabric_code
,product_fabric_descr
,product_process_code
,product_process_desc
,dept
,class
,gender
,seller_date_code
,shipment_status
,flex_field_1
,flex_field_2
,flex_field_3
,flex_field_4
,flex_field_5
)
as
select
oh.orderid,
oh.shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
substr(shipperfax,1,80),
substr(shipperfax,1,80),
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
'aaaa',
zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber),
'yy',
useramt2,
oh.qtyship,
oh.qtycommit,
'bbbb',
oh.weightship,
'cccc',
oh.cubeship,
'dddd',
ci.length,
ci.width,
ci.height,
od.qtyship,
'eeee',
oh.statusupdate,
(od.qtyorder - od.qtyship),
(zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber) - ci.useramt2),
'ff',
substr(dtlpassthruchar20,1,45),
'gg',
substr(dtlpassthruchar19,1,45),
'hh',
substr(dtlpassthruchar18,1,45),
'ii',
substr(dtlpassthruchar17,1,45),
'jjjjjjjjjj',
'kkkkkkkkkkkkkkkkkkkkkkkkkkkkkk',
'llllllllllllllllllllllllllllll',
'mmmmmmmm',
'xx',
dtlpassthruchar01,
dtlpassthruchar02,
dtlpassthruchar03,
dtlpassthruchar04,
dtlpassthruchar05
from custitem ci, customer cu, orderhdr oh, orderdtl od
where oh.orderid = od.orderid
  and oh.shipid = od.shipid
  and oh.custid = cu.custid(+);

comment on table sip_asn_856_li2 is '$Id$';

create or replace view sip_asn_856_dl
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,marks_1
,item
,lotnumber
,line_number
,cancel_after,
do_not_deliver_before,
do_not_deliver_after,
requested_delivery,
requested_pickup,
requested_ship,
ship_no_later,
ship_not_before,
promo_start,
promo_end,
addl_date1_qualifier,
addl_date1,
addl_date2_qualifier,
addl_date2,
addl_date3_qualifier,
addl_date3
)
as
select
oh.orderid,
oh.shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
substr(shipperfax,1,80),
od.item,
od.lotnumber,
dtlpassthrunum10,
cancel_after,
do_not_deliver_before,
do_not_deliver_after,
delivery_requested,
oh.statusupdate,
shipdate,
ship_no_later,
ship_not_before,
oh.lastupdate,
cancelled_date,
'aaa',
cancel_if_not_delivered_by,
'bbb',
transapptdate,
'ccc',
packlistshipdate
from orderdtl od, shippingplate sp, customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_asn_856_dl is '$Id$';

create or replace view sip_asn_856_lk
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,marks_1
,item
,lotnumber
,line_number
,part1_qualifier
,part1_item
,part2_qualifier
,part2_item
,part3_qualifier
,part3_item
,part4_qualifier
,part4_item
,part_descr1
,part_descr2
,product_size
,product_size_descr
,product_color
,product_color_descr
,product_fabric_code
,product_fabric_descr
,product_process_code
,product_process_desc
,qty_per
,qty_per_uom
,unit_price
,unit_price_basis
,serialnumber
,warranty_date
,effective_date
,lot_expiration_date
)
as
select
oh.orderid,
oh.shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
substr(shipperfax,1,80),
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
'fff',
substr(dtlpassthruchar20,1,45),
'ggg',
substr(dtlpassthruchar19,1,45),
'hhh',
substr(dtlpassthruchar18,1,45),
'iii',
substr(dtlpassthruchar17,1,45),
oh.qtyorder,
oh.qtycommit,
zci.item_amt(od.custid,od.orderid,od.shipid,od.item,od.lotnumber),
'jj',
sp.serialnumber,
oh.shipdate,
oh.entrydate,
sp.lastupdate
from shippingplate sp, custitem ci, customer cu, orderhdr oh, orderdtl od
where oh.orderid = od.orderid
  and oh.shipid = od.shipid
  and oh.custid = cu.custid(+);

comment on table sip_asn_856_lk is '$Id$';

create or replace view sip_asn_856_st
(orderid
,shipid
,sip_tradingpartnerid
,sip_shipment_identifier
,qtyorders
,qtylines
,qtyship
,weightship
,flex_field_1
,flex_field_2
,flex_field_3
,flex_field_4
,flex_field_5
)
as
select
orderid,
shipid,
cu.sip_tradingpartnerid,
substr(zimsip.shipment_identifier(oh.orderid,oh.shipid),1,9),
qtyorder,
qtycommit,
qtyship,
weightship,
hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar05
from customer cu, orderhdr oh
where oh.custid = cu.custid(+);

comment on table sip_asn_856_st is '$Id$';

exit;
