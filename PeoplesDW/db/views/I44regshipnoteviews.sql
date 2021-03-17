-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim5.begin_I44_ship_note/zim5.end_I44_ship_note
create or replace view I44_ship_note_lot
(
orderid,
shipid,
item,
linenumber,
sequence,
lotnumber,
qty
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
,equiv_uom
,equiv_qty
,uom
,useritem1
,useritem2
,useritem3
)
as
select
orderid,
shipid,
item,
linenumber,
dtlpassthrunum10,
lotnumber,
qty
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
,'XXXX'
,qty
,'XXXX'
,dtlpassthruchar01
,dtlpassthruchar02
,dtlpassthruchar03
from orderdtlline;

comment on table I44_ship_note_lot is '$Id';

create or replace view I44_ship_note_dtl
(
orderid,
shipid,
linenumber,
item,
serialnumber,
trackingno,
qty
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
,itemdescr
,lotcount
,uom
,equiv_uom
,equiv_qty
,useritem1
,useritem2
,useritem3
,qtyorder
,prono_or_trackingno
,rmatrackingno
,ucc128
,line_uom
,line_qty
)
as
select
OD.orderid,
OD.shipid,
OD.dtlpassthrunum10,
OD.item,
nvl(sp.serialnumber,'000000000000000000000000000000'),
nvl(sp.trackingno,'000000000000000000000000000000'),
OD.qtyship
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
,itm.descr
,od.qtyorder
,od.uom
,'XXXX'
,qtyship
,sp.useritem1
,sp.useritem2
,sp.useritem3
,od.qtyorder
,od.dtlpassthruchar01
,sp.rmatrackingno
,substr(dtlpassthruchar01,1,20)
,'XXXX'
,qtyship
from custitem itm, shippingplate sp, orderdtl od
where OD.orderid = sp.orderid(+)
  and OD.shipid = sp.shipid(+)
  and OD.item = sp.orderitem(+)
  and OD.custid = itm.custid(+)
  and OD.itementered = itm.item(+);

comment on table I44_ship_note_dtl is '$Id';

create or replace view I44_ship_note_hdr
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
chepcount,
whitecount,
totpalletcount,
billoflading,
ordertype,
prono,
trackingno,
 DELIVERY_REQUESTED,
 REQUESTED_SHIP,
 SHIP_NOT_BEFORE,
 SHIP_NO_LATER,
 CANCEL_IF_NOT_DELIVERED_BY,
 DO_NOT_DELIVER_AFTER,
 DO_NOT_DELIVER_BEFORE,
 HDRPASSTHRUDATE01,
 HDRPASSTHRUDATE02,
 HDRPASSTHRUDATE03,
 HDRPASSTHRUDATE04,
 HDRPASSTHRUDOLL01,
 HDRPASSTHRUDOLL02,
 fromfacility,
 deliveryservice,
 shiptofax,
 shiptoemail,
 shiptophone,
 prono_or_trackingno,
 shiptype,
 custombol
)
as
select
custid,
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
orderhdr.qtyorder,
orderhdr.qtypick,
orderhdr.qtycommit,
nvl(loads.billoflading,orderhdr.billoflading),
ordertype,
nvl(orderhdr.prono,loads.prono),
substr(zoe.max_trackingno(orderhdr.orderid,orderhdr.shipid),1,30),
 DELIVERY_REQUESTED,
 REQUESTED_SHIP,
 SHIP_NOT_BEFORE,
 SHIP_NO_LATER,
 CANCEL_IF_NOT_DELIVERED_BY,
 DO_NOT_DELIVER_AFTER,
 DO_NOT_DELIVER_BEFORE,
 HDRPASSTHRUDATE01,
 HDRPASSTHRUDATE02,
 HDRPASSTHRUDATE03,
 HDRPASSTHRUDATE04,
 HDRPASSTHRUDOLL01,
 HDRPASSTHRUDOLL02,
 fromfacility,
substr(zim14.delivery_service(orderhdr.orderid,orderhdr.shipid,null,null),1,10),
decode(CN.consignee,null,shiptofax,CN.fax),
decode(CN.consignee,null,shiptoemail,CN.email),
decode(CN.consignee,null,shiptophone,CN.phone),
hdrpassthruchar01,
nvl(loads.shiptype,orderhdr.shiptype),
zedi.get_custom_bol(orderhdr.orderid, orderhdr.shipid)
from loads, orderhdr, consignee CN
where ordertype = '0'
  and orderhdr.loadno = loads.loadno(+)
  and orderhdr.shipto = CN.consignee(+);

comment on table I44_ship_note_hdr is '$Id';

exit;
