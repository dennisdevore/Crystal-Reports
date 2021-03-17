create or replace view orderhdrview
(
BILLOFLADING,
PRIORITY,
WEIGHTCOMMIT,
CUBECOMMIT,
AMTCOMMIT,
QTYSHIP,
WEIGHTSHIP,
CUBESHIP,
AMTSHIP,
QTYTOTCOMMIT,
WEIGHTTOTCOMMIT,
CUBETOTCOMMIT,
AMTTOTCOMMIT,
QTYRCVD,
WEIGHTRCVD,
CUBERCVD,
AMTRCVD,
COMMENT1,
STATUSUSER,
STATUSUPDATE,
LASTUSER,
LASTUPDATE,
ORDERID,
SHIPID,
CUSTID,
ORDERTYPE,
ordertypeabbrev,
ENTRYDATE,
APPTDATE,
SHIPDATE,
PO,
RMA,
ORDERSTATUS,
orderstatusabbrev,
COMMITSTATUS,
FROMFACILITY,
TOFACILITY,
LOADNO,
STOPNO,
SHIPNO,
SHIPTO,
DELAREA,
QTYORDER,
WEIGHTORDER,
CUBEORDER,
AMTORDER,
QTYCOMMIT,
arrivaldate,
consignee,
shiptype,
carrier,
orderhdrcarrier,
reference,
shipterms,
shiptypeabbrev,
shiptermsabbrev,
priorityabbrev,
hazardous,
stageloc,
QTY2sort,
WEIGHT2sort,
CUBE2sort,
AMT2sort,
QTY2pack,
WEIGHT2pack,
CUBE2pack,
AMT2pack,
QTY2check,
WEIGHT2check,
CUBE2check,
AMT2check,
staffhrs,
wave,
unknownlipcount,
dateshipped,
deliveryservice,
saturdaydelivery,
specialservice1,
specialservice2,
specialservice3,
specialservice4,
cod,
amtcod,
asnvariance,
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
QTYpick,
WEIGHtpick,
CUBEpick,
AMTpick,
FTZ216Authorization,
componenttemplate
,cancel_after
,delivery_requested
,requested_ship
,ship_not_before
,ship_no_later
,cancel_if_not_delivered_by
,do_not_deliver_after
,do_not_deliver_before,
hdrpassthrudate01,
hdrpassthrudate02,
hdrpassthrudate03,
hdrpassthrudate04,
hdrpassthrudoll01,
hdrpassthrudoll02,
TMS_Shipment_id,
TMS_release_id,
prono,
recent_order_id,
shiptoname,
shippingcost,
xdockprocessing,
xdockorderid,
xdockshipid,
hdrpassthruchar21,
hdrpassthruchar22,
hdrpassthruchar23,
hdrpassthruchar24,
hdrpassthruchar25,
hdrpassthruchar26,
hdrpassthruchar27,
hdrpassthruchar28,
hdrpassthruchar29,
hdrpassthruchar30,
hdrpassthruchar31,
hdrpassthruchar32,
hdrpassthruchar33,
hdrpassthruchar34,
hdrpassthruchar35,
hdrpassthruchar36,
hdrpassthruchar37,
hdrpassthruchar38,
hdrpassthruchar39,
hdrpassthruchar40,
weightcommit_kgs,
weightship_kgs,
weighttotcommit_kgs,
weightrcvd_kgs,
weightorder_kgs,
weight2sort_kgs,
weight2pack_kgs,
weight2check_kgs,
weightpick_kgs,
weight_entered_lbs,
weight_entered_kgs,
parentorderid,
parentshipid,
hascomment,
hasbolcomment,
hdrpassthruchar41,
hdrpassthruchar42,
hdrpassthruchar43,
hdrpassthruchar44,
hdrpassthruchar45,
hdrpassthruchar46,
hdrpassthruchar47,
hdrpassthruchar48,
hdrpassthruchar49,
hdrpassthruchar50,
hdrpassthruchar51,
hdrpassthruchar52,
hdrpassthruchar53,
hdrpassthruchar54,
hdrpassthruchar55,
hdrpassthruchar56,
hdrpassthruchar57,
hdrpassthruchar58,
hdrpassthruchar59,
hdrpassthruchar60,
shipper,
shipto_master,
oh_rowid,
shipshort,
shiptocountrycode,
original_wave_before_combine
)
as
select
orderhdr.BILLOFLADING,
orderhdr.PRIORITY,
orderhdr.WEIGHTCOMMIT,
orderhdr.CUBECOMMIT,
orderhdr.AMTCOMMIT,
orderhdr.QTYSHIP,
orderhdr.WEIGHTSHIP,
orderhdr.CUBESHIP,
orderhdr.AMTSHIP,
orderhdr.QTYTOTCOMMIT,
orderhdr.WEIGHTTOTCOMMIT,
orderhdr.CUBETOTCOMMIT,
orderhdr.AMTTOTCOMMIT,
orderhdr.QTYRCVD,
orderhdr.WEIGHTRCVD,
orderhdr.CUBERCVD,
orderhdr.AMTRCVD,
orderhdr.COMMENT1,
orderhdr.STATUSUSER,
orderhdr.STATUSUPDATE,
orderhdr.LASTUSER,
orderhdr.LASTUPDATE,
orderhdr.ORDERID,
orderhdr.SHIPID,
orderhdr.CUSTID,
ORDERTYPE,
ordertypes.abbrev,
orderhdr.ENTRYDATE,
nvl(orderhdr.APPTDATE,loads.apptdate),
SHIPDATE,
orderhdr.PO,
orderhdr.RMA,
orderhdr.ORDERSTATUS,
orderstatus.abbrev,
orderhdr.COMMITSTATUS,
orderhdr.FROMFACILITY,
orderhdr.TOFACILITY,
orderhdr.LOADNO,
orderhdr.STOPNO,
orderhdr.SHIPNO,
orderhdr.SHIPTO,
orderhdr.DELAREA,
orderhdr.QTYORDER,
orderhdr.WEIGHTORDER,
orderhdr.CUBEORDER,
orderhdr.AMTORDER,
orderhdr.QTYCOMMIT,
orderhdr.arrivaldate,
orderhdr.consignee,
orderhdr.shiptype,
nvl(loads.carrier,orderhdr.carrier),
nvl(orderhdr.carrier, ''),
orderhdr.reference,
orderhdr.shipterms,
shipmenttypes.abbrev,
shipmentterms.abbrev,
orderpriority.abbrev,
substr(zci.hazardous_item_on_order(orderhdr.orderid,orderhdr.shipid),1,1),
nvl(orderhdr.stageloc,nvl(loadstop.stageloc,loads.stageloc)),
orderhdr.QTY2sort,
orderhdr.WEIGHT2sort,
orderhdr.CUBE2sort,
orderhdr.AMT2sort,
orderhdr.QTY2pack,
orderhdr.WEIGHT2pack,
orderhdr.CUBE2pack,
orderhdr.AMT2pack,
orderhdr.QTY2check,
orderhdr.WEIGHT2check,
orderhdr.CUBE2check,
orderhdr.AMT2check,
nvl(orderhdr.staffhrs,0),
wave,
zoe.unknown_lip_count(orderhdr.orderid,orderhdr.shipid),
orderhdr.dateshipped,
orderhdr.deliveryservice,
orderhdr.saturdaydelivery,
orderhdr.specialservice1,
orderhdr.specialservice2,
orderhdr.specialservice3,
orderhdr.specialservice4,
orderhdr.cod,
orderhdr.amtcod,
nvl(orderhdr.asnvariance,'N'),
orderhdr.hdrpassthruchar01,
orderhdr.hdrpassthruchar02,
orderhdr.hdrpassthruchar03,
orderhdr.hdrpassthruchar04,
orderhdr.hdrpassthruchar05,
orderhdr.hdrpassthruchar06,
orderhdr.hdrpassthruchar07,
orderhdr.hdrpassthruchar08,
orderhdr.hdrpassthruchar09,
orderhdr.hdrpassthruchar10,
orderhdr.hdrpassthruchar11,
orderhdr.hdrpassthruchar12,
orderhdr.hdrpassthruchar13,
orderhdr.hdrpassthruchar14,
orderhdr.hdrpassthruchar15,
orderhdr.hdrpassthruchar16,
orderhdr.hdrpassthruchar17,
orderhdr.hdrpassthruchar18,
orderhdr.hdrpassthruchar19,
orderhdr.hdrpassthruchar20,
orderhdr.hdrpassthrunum01,
orderhdr.hdrpassthrunum02,
orderhdr.hdrpassthrunum03,
orderhdr.hdrpassthrunum04,
orderhdr.hdrpassthrunum05,
orderhdr.hdrpassthrunum06,
orderhdr.hdrpassthrunum07,
orderhdr.hdrpassthrunum08,
orderhdr.hdrpassthrunum09,
orderhdr.hdrpassthrunum10,
orderhdr.qtypick,
orderhdr.WEIGHTpick,
orderhdr.CUBEpick,
orderhdr.AMTpick,
orderhdr.FTZ216Authorization,
orderhdr.componenttemplate,
orderhdr.cancel_after,
orderhdr.delivery_requested,
orderhdr.requested_ship,
orderhdr.ship_not_before,
orderhdr.ship_no_later,
orderhdr.cancel_if_not_delivered_by,
orderhdr.do_not_deliver_after,
orderhdr.do_not_deliver_before,
orderhdr.hdrpassthrudate01,
orderhdr.hdrpassthrudate02,
orderhdr.hdrpassthrudate03,
orderhdr.hdrpassthrudate04,
orderhdr.hdrpassthrudoll01,
orderhdr.hdrpassthrudoll02,
orderhdr.TMS_Shipment_id,
orderhdr.TMS_release_id,
orderhdr.prono,
orderhdr.recent_order_id,
decode(orderhdr.shiptoname, null, consignee.name, orderhdr.shiptoname),
orderhdr.shippingcost,
orderhdr.xdockprocessing,
orderhdr.xdockorderid,
orderhdr.xdockshipid,
orderhdr.hdrpassthruchar21,
orderhdr.hdrpassthruchar22,
orderhdr.hdrpassthruchar23,
orderhdr.hdrpassthruchar24,
orderhdr.hdrpassthruchar25,
orderhdr.hdrpassthruchar26,
orderhdr.hdrpassthruchar27,
orderhdr.hdrpassthruchar28,
orderhdr.hdrpassthruchar29,
orderhdr.hdrpassthruchar30,
orderhdr.hdrpassthruchar31,
orderhdr.hdrpassthruchar32,
orderhdr.hdrpassthruchar33,
orderhdr.hdrpassthruchar34,
orderhdr.hdrpassthruchar35,
orderhdr.hdrpassthruchar36,
orderhdr.hdrpassthruchar37,
orderhdr.hdrpassthruchar38,
orderhdr.hdrpassthruchar39,
orderhdr.hdrpassthruchar40,
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightcommit),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightship),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weighttotcommit),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightrcvd),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightorder),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2sort),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2pack),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2check),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightpick),
nvl(orderhdr.weight_entered_lbs,0),
nvl(orderhdr.weight_entered_kgs,0),
orderhdr.parentorderid,
orderhdr.parentshipid,
decode(length(orderhdr.comment1), null, 'N','Y'),
decode(length(orderhdrbolcomments.bolcomment), null, 'N','Y'),
orderhdr.hdrpassthruchar41,
orderhdr.hdrpassthruchar42,
orderhdr.hdrpassthruchar43,
orderhdr.hdrpassthruchar44,
orderhdr.hdrpassthruchar45,
orderhdr.hdrpassthruchar46,
orderhdr.hdrpassthruchar47,
orderhdr.hdrpassthruchar48,
orderhdr.hdrpassthruchar49,
orderhdr.hdrpassthruchar50,
orderhdr.hdrpassthruchar51,
orderhdr.hdrpassthruchar52,
orderhdr.hdrpassthruchar53,
orderhdr.hdrpassthruchar54,
orderhdr.hdrpassthruchar55,
orderhdr.hdrpassthruchar56,
orderhdr.hdrpassthruchar57,
orderhdr.hdrpassthruchar58,
orderhdr.hdrpassthruchar59,
orderhdr.hdrpassthruchar60,
orderhdr.shipper,
orderhdr.shipto_master,
orderhdr.rowid,
orderhdr.shipshort,
nvl(orderhdr.shiptocountrycode,''),
orderhdr.original_wave_before_combine
from orderhdrbolcomments, orderstatus, ordertypes, shipmenttypes, shipmentterms,
     orderpriority, loads, loadstop, orderhdr, consignee
where orderhdr.orderstatus = orderstatus.code (+)
  and orderhdr.ordertype = ordertypes.code (+)
  and orderhdr.shiptype = shipmenttypes.code(+)
  and orderhdr.shipterms = shipmentterms.code(+)
  and orderhdr.priority = orderpriority.code(+)
  and orderhdr.loadno = loads.loadno(+)
  and orderhdr.loadno = loadstop.loadno(+)
  and orderhdr.stopno = loadstop.stopno(+)
    and orderhdr.shipto = consignee.consignee(+)
  and orderhdr.orderid = orderhdrbolcomments.orderid(+)
  and orderhdr.shipid = orderhdrbolcomments.shipid(+);

comment on table orderhdrview is '$Id$';

create or replace view pho_orderhdrview
(
BILLOFLADING,
PRIORITY,
WEIGHTCOMMIT,
CUBECOMMIT,
AMTCOMMIT,
QTYSHIP,
WEIGHTSHIP,
CUBESHIP,
AMTSHIP,
QTYTOTCOMMIT,
WEIGHTTOTCOMMIT,
CUBETOTCOMMIT,
AMTTOTCOMMIT,
QTYRCVD,
WEIGHTRCVD,
CUBERCVD,
AMTRCVD,
COMMENT1,
STATUSUSER,
STATUSUPDATE,
LASTUSER,
LASTUPDATE,
ORDERID,
SHIPID,
CUSTID,
ORDERTYPE,
ordertypeabbrev,
ENTRYDATE,
APPTDATE,
SHIPDATE,
PO,
RMA,
ORDERSTATUS,
orderstatusabbrev,
COMMITSTATUS,
FROMFACILITY,
TOFACILITY,
LOADNO,
STOPNO,
SHIPNO,
SHIPTO,
DELAREA,
QTYORDER,
WEIGHTORDER,
CUBEORDER,
AMTORDER,
QTYCOMMIT,
arrivaldate,
consignee,
shiptype,
carrier,
reference,
shipterms,
shiptypeabbrev,
shiptermsabbrev,
priorityabbrev,
hazardous,
stageloc,
QTY2sort,
WEIGHT2sort,
CUBE2sort,
AMT2sort,
QTY2pack,
WEIGHT2pack,
CUBE2pack,
AMT2pack,
QTY2check,
WEIGHT2check,
CUBE2check,
AMT2check,
staffhrs,
wave,
unknownlipcount,
dateshipped,
deliveryservice,
saturdaydelivery,
specialservice1,
specialservice2,
specialservice3,
specialservice4,
cod,
amtcod,
asnvariance,
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
QTYpick,
WEIGHtpick,
CUBEpick,
AMTpick,
FTZ216Authorization,
componenttemplate
,cancel_after
,delivery_requested
,requested_ship
,ship_not_before
,ship_no_later
,cancel_if_not_delivered_by
,do_not_deliver_after
,do_not_deliver_before,
hdrpassthrudate01,
hdrpassthrudate02,
hdrpassthrudate03,
hdrpassthrudate04,
hdrpassthrudoll01,
hdrpassthrudoll02,
TMS_Shipment_id,
TMS_release_id,
prono,
recent_order_id,
shiptoname,
shippingcost,
xdockprocessing,
xdockorderid,
xdockshipid,
hdrpassthruchar21,
hdrpassthruchar22,
hdrpassthruchar23,
hdrpassthruchar24,
hdrpassthruchar25,
hdrpassthruchar26,
hdrpassthruchar27,
hdrpassthruchar28,
hdrpassthruchar29,
hdrpassthruchar30,
hdrpassthruchar31,
hdrpassthruchar32,
hdrpassthruchar33,
hdrpassthruchar34,
hdrpassthruchar35,
hdrpassthruchar36,
hdrpassthruchar37,
hdrpassthruchar38,
hdrpassthruchar39,
hdrpassthruchar40,
weightcommit_kgs,
weightship_kgs,
weighttotcommit_kgs,
weightrcvd_kgs,
weightorder_kgs,
weight2sort_kgs,
weight2pack_kgs,
weight2check_kgs,
weightpick_kgs,
weight_entered_lbs,
weight_entered_kgs,
parentorderid,
parentshipid,
CANCELLED_DATE,
QTYORDERPCS,
QTYORDERCTN
)
as
select
orderhdr.BILLOFLADING,
orderhdr.PRIORITY,
orderhdr.WEIGHTCOMMIT,
orderhdr.CUBECOMMIT,
orderhdr.AMTCOMMIT,
orderhdr.QTYSHIP,
orderhdr.WEIGHTSHIP,
orderhdr.CUBESHIP,
orderhdr.AMTSHIP,
orderhdr.QTYTOTCOMMIT,
orderhdr.WEIGHTTOTCOMMIT,
orderhdr.CUBETOTCOMMIT,
orderhdr.AMTTOTCOMMIT,
orderhdr.QTYRCVD,
orderhdr.WEIGHTRCVD,
orderhdr.CUBERCVD,
orderhdr.AMTRCVD,
orderhdr.COMMENT1,
orderhdr.STATUSUSER,
orderhdr.STATUSUPDATE,
orderhdr.LASTUSER,
orderhdr.LASTUPDATE,
orderhdr.ORDERID,
orderhdr.SHIPID,
orderhdr.CUSTID,
ORDERTYPE,
ordertypes.abbrev,
orderhdr.ENTRYDATE,
nvl(orderhdr.APPTDATE,loads.apptdate),
SHIPDATE,
orderhdr.PO,
orderhdr.RMA,
orderhdr.ORDERSTATUS,
orderstatus.abbrev,
orderhdr.COMMITSTATUS,
orderhdr.FROMFACILITY,
orderhdr.TOFACILITY,
orderhdr.LOADNO,
orderhdr.STOPNO,
orderhdr.SHIPNO,
orderhdr.SHIPTO,
orderhdr.DELAREA,
orderhdr.QTYORDER,
orderhdr.WEIGHTORDER,
orderhdr.CUBEORDER,
orderhdr.AMTORDER,
orderhdr.QTYCOMMIT,
orderhdr.arrivaldate,
orderhdr.consignee,
orderhdr.shiptype,
nvl(loads.carrier,orderhdr.carrier),
orderhdr.reference,
orderhdr.shipterms,
shipmenttypes.abbrev,
shipmentterms.abbrev,
orderpriority.abbrev,
substr(zci.hazardous_item_on_order(orderhdr.orderid,orderhdr.shipid),1,1),
nvl(orderhdr.stageloc,nvl(loadstop.stageloc,loads.stageloc)),
orderhdr.QTY2sort,
orderhdr.WEIGHT2sort,
orderhdr.CUBE2sort,
orderhdr.AMT2sort,
orderhdr.QTY2pack,
orderhdr.WEIGHT2pack,
orderhdr.CUBE2pack,
orderhdr.AMT2pack,
orderhdr.QTY2check,
orderhdr.WEIGHT2check,
orderhdr.CUBE2check,
orderhdr.AMT2check,
nvl(orderhdr.staffhrs,0),
wave,
zoe.unknown_lip_count(orderhdr.orderid,orderhdr.shipid),
orderhdr.dateshipped,
orderhdr.deliveryservice,
orderhdr.saturdaydelivery,
orderhdr.specialservice1,
orderhdr.specialservice2,
orderhdr.specialservice3,
orderhdr.specialservice4,
orderhdr.cod,
orderhdr.amtcod,
nvl(orderhdr.asnvariance,'N'),
orderhdr.hdrpassthruchar01,
orderhdr.hdrpassthruchar02,
orderhdr.hdrpassthruchar03,
orderhdr.hdrpassthruchar04,
orderhdr.hdrpassthruchar05,
orderhdr.hdrpassthruchar06,
orderhdr.hdrpassthruchar07,
orderhdr.hdrpassthruchar08,
orderhdr.hdrpassthruchar09,
orderhdr.hdrpassthruchar10,
orderhdr.hdrpassthruchar11,
orderhdr.hdrpassthruchar12,
orderhdr.hdrpassthruchar13,
orderhdr.hdrpassthruchar14,
orderhdr.hdrpassthruchar15,
orderhdr.hdrpassthruchar16,
orderhdr.hdrpassthruchar17,
orderhdr.hdrpassthruchar18,
orderhdr.hdrpassthruchar19,
orderhdr.hdrpassthruchar20,
orderhdr.hdrpassthrunum01,
orderhdr.hdrpassthrunum02,
orderhdr.hdrpassthrunum03,
orderhdr.hdrpassthrunum04,
orderhdr.hdrpassthrunum05,
orderhdr.hdrpassthrunum06,
orderhdr.hdrpassthrunum07,
orderhdr.hdrpassthrunum08,
orderhdr.hdrpassthrunum09,
orderhdr.hdrpassthrunum10,
orderhdr.qtypick,
orderhdr.WEIGHTpick,
orderhdr.CUBEpick,
orderhdr.AMTpick,
orderhdr.FTZ216Authorization,
orderhdr.componenttemplate,
orderhdr.cancel_after,
orderhdr.delivery_requested,
orderhdr.requested_ship,
orderhdr.ship_not_before,
orderhdr.ship_no_later,
orderhdr.cancel_if_not_delivered_by,
orderhdr.do_not_deliver_after,
orderhdr.do_not_deliver_before,
orderhdr.hdrpassthrudate01,
orderhdr.hdrpassthrudate02,
orderhdr.hdrpassthrudate03,
orderhdr.hdrpassthrudate04,
orderhdr.hdrpassthrudoll01,
orderhdr.hdrpassthrudoll02,
orderhdr.TMS_Shipment_id,
orderhdr.TMS_release_id,
orderhdr.prono,
orderhdr.recent_order_id,
decode(orderhdr.shiptoname, null, consignee.name, orderhdr.shiptoname),
orderhdr.shippingcost,
orderhdr.xdockprocessing,
orderhdr.xdockorderid,
orderhdr.xdockshipid,
orderhdr.hdrpassthruchar21,
orderhdr.hdrpassthruchar22,
orderhdr.hdrpassthruchar23,
orderhdr.hdrpassthruchar24,
orderhdr.hdrpassthruchar25,
orderhdr.hdrpassthruchar26,
orderhdr.hdrpassthruchar27,
orderhdr.hdrpassthruchar28,
orderhdr.hdrpassthruchar29,
orderhdr.hdrpassthruchar30,
orderhdr.hdrpassthruchar31,
orderhdr.hdrpassthruchar32,
orderhdr.hdrpassthruchar33,
orderhdr.hdrpassthruchar34,
orderhdr.hdrpassthruchar35,
orderhdr.hdrpassthruchar36,
orderhdr.hdrpassthruchar37,
orderhdr.hdrpassthruchar38,
orderhdr.hdrpassthruchar39,
orderhdr.hdrpassthruchar40,
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightcommit),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightship),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weighttotcommit),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightrcvd),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightorder),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2sort),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2pack),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2check),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightpick),
nvl(orderhdr.weight_entered_lbs,0),
nvl(orderhdr.weight_entered_kgs,0),
orderhdr.parentorderid,
orderhdr.parentshipid,
orderhdr.cancelled_date,
(select sum(nvl(zlbl.uom_qty_conv(orderhdr.custid, orderdtl.item, nvl(orderdtl.qtyorder,0), orderdtl.uom, 'PCS'),0))
   from orderdtl
  where orderdtl.orderid = orderhdr.orderid
    and orderdtl.shipid = orderhdr.shipid),
(select sum(nvl(zlbl.uom_qty_conv(orderhdr.custid, orderdtl.item, nvl(orderdtl.qtyorder,0), orderdtl.uom, 'CTN'),0))
   from orderdtl
  where orderdtl.orderid = orderhdr.orderid
    and orderdtl.shipid = orderhdr.shipid)
from orderstatus, ordertypes, shipmenttypes, shipmentterms,
     orderpriority, loads, loadstop, orderhdr, consignee
where orderhdr.orderstatus = orderstatus.code (+)
  and orderhdr.ordertype = ordertypes.code (+)
  and orderhdr.shiptype = shipmenttypes.code(+)
  and orderhdr.shipterms = shipmentterms.code(+)
  and orderhdr.priority = orderpriority.code(+)
  and orderhdr.loadno = loads.loadno(+)
  and orderhdr.loadno = loadstop.loadno(+)
  and orderhdr.stopno = loadstop.stopno(+)
  and orderhdr.shipto = consignee.consignee(+);

comment on table pho_orderhdrview is '$Id$';

create or replace view d2k_orderhdrview
(
BILLOFLADING,
PRIORITY,
WEIGHTCOMMIT,
CUBECOMMIT,
AMTCOMMIT,
QTYSHIP,
WEIGHTSHIP,
CUBESHIP,
AMTSHIP,
QTYTOTCOMMIT,
WEIGHTTOTCOMMIT,
CUBETOTCOMMIT,
AMTTOTCOMMIT,
QTYRCVD,
WEIGHTRCVD,
CUBERCVD,
AMTRCVD,
COMMENT1,
STATUSUSER,
STATUSUPDATE,
LASTUSER,
LASTUPDATE,
ORDERID,
SHIPID,
CUSTID,
ORDERTYPE,
ordertypeabbrev,
ENTRYDATE,
APPTDATE,
SHIPDATE,
PO,
RMA,
ORDERSTATUS,
orderstatusabbrev,
COMMITSTATUS,
FROMFACILITY,
TOFACILITY,
LOADNO,
STOPNO,
SHIPNO,
SHIPTO,
DELAREA,
QTYORDER,
WEIGHTORDER,
CUBEORDER,
AMTORDER,
QTYCOMMIT,
arrivaldate,
consignee,
shiptype,
carrier,
reference,
shipterms,
shiptypeabbrev,
shiptermsabbrev,
priorityabbrev,
hazardous,
stageloc,
QTY2sort,
WEIGHT2sort,
CUBE2sort,
AMT2sort,
QTY2pack,
WEIGHT2pack,
CUBE2pack,
AMT2pack,
QTY2check,
WEIGHT2check,
CUBE2check,
AMT2check,
staffhrs,
wave,
unknownlipcount,
dateshipped,
deliveryservice,
saturdaydelivery,
specialservice1,
specialservice2,
specialservice3,
specialservice4,
cod,
amtcod,
asnvariance,
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
QTYpick,
WEIGHtpick,
CUBEpick,
AMTpick,
FTZ216Authorization,
componenttemplate
,cancel_after
,delivery_requested
,requested_ship
,ship_not_before
,ship_no_later
,cancel_if_not_delivered_by
,do_not_deliver_after
,do_not_deliver_before,
hdrpassthrudate01,
hdrpassthrudate02,
hdrpassthrudate03,
hdrpassthrudate04,
hdrpassthrudoll01,
hdrpassthrudoll02,
TMS_Shipment_id,
TMS_release_id,
prono,
recent_order_id,
shiptoname,
shippingcost,
xdockprocessing,
xdockorderid,
xdockshipid,
hdrpassthruchar21,
hdrpassthruchar22,
hdrpassthruchar23,
hdrpassthruchar24,
hdrpassthruchar25,
hdrpassthruchar26,
hdrpassthruchar27,
hdrpassthruchar28,
hdrpassthruchar29,
hdrpassthruchar30,
hdrpassthruchar31,
hdrpassthruchar32,
hdrpassthruchar33,
hdrpassthruchar34,
hdrpassthruchar35,
hdrpassthruchar36,
hdrpassthruchar37,
hdrpassthruchar38,
hdrpassthruchar39,
hdrpassthruchar40,
weightcommit_kgs,
weightship_kgs,
weighttotcommit_kgs,
weightrcvd_kgs,
weightorder_kgs,
weight2sort_kgs,
weight2pack_kgs,
weight2check_kgs,
weightpick_kgs,
weight_entered_lbs,
weight_entered_kgs,
parentorderid,
parentshipid,
shiptocontact,
shiptoaddr1,
shiptoaddr2,
shiptocity,
shiptostate,
shiptopostalcode,
shiptocountrycode,
shiptophone,
shiptofax,
shiptoemail
)
as
select
orderhdr.BILLOFLADING,
orderhdr.PRIORITY,
orderhdr.WEIGHTCOMMIT,
orderhdr.CUBECOMMIT,
orderhdr.AMTCOMMIT,
orderhdr.QTYSHIP,
orderhdr.WEIGHTSHIP,
orderhdr.CUBESHIP,
orderhdr.AMTSHIP,
orderhdr.QTYTOTCOMMIT,
orderhdr.WEIGHTTOTCOMMIT,
orderhdr.CUBETOTCOMMIT,
orderhdr.AMTTOTCOMMIT,
orderhdr.QTYRCVD,
orderhdr.WEIGHTRCVD,
orderhdr.CUBERCVD,
orderhdr.AMTRCVD,
zbol.orderhdrcomments(orderhdr.rowid),
orderhdr.STATUSUSER,
orderhdr.STATUSUPDATE,
orderhdr.LASTUSER,
orderhdr.LASTUPDATE,
orderhdr.ORDERID,
orderhdr.SHIPID,
orderhdr.CUSTID,
ORDERTYPE,
ordertypes.abbrev,
orderhdr.ENTRYDATE,
nvl(orderhdr.APPTDATE,loads.apptdate),
SHIPDATE,
orderhdr.PO,
orderhdr.RMA,
orderhdr.ORDERSTATUS,
orderstatus.abbrev,
orderhdr.COMMITSTATUS,
orderhdr.FROMFACILITY,
orderhdr.TOFACILITY,
orderhdr.LOADNO,
orderhdr.STOPNO,
orderhdr.SHIPNO,
orderhdr.SHIPTO,
orderhdr.DELAREA,
orderhdr.QTYORDER,
orderhdr.WEIGHTORDER,
orderhdr.CUBEORDER,
orderhdr.AMTORDER,
orderhdr.QTYCOMMIT,
orderhdr.arrivaldate,
orderhdr.consignee,
orderhdr.shiptype,
nvl(loads.carrier,orderhdr.carrier),
orderhdr.reference,
orderhdr.shipterms,
shipmenttypes.abbrev,
shipmentterms.abbrev,
orderpriority.abbrev,
substr(zci.hazardous_item_on_order(orderhdr.orderid,orderhdr.shipid),1,1),
nvl(orderhdr.stageloc,nvl(loadstop.stageloc,loads.stageloc)),
orderhdr.QTY2sort,
orderhdr.WEIGHT2sort,
orderhdr.CUBE2sort,
orderhdr.AMT2sort,
orderhdr.QTY2pack,
orderhdr.WEIGHT2pack,
orderhdr.CUBE2pack,
orderhdr.AMT2pack,
orderhdr.QTY2check,
orderhdr.WEIGHT2check,
orderhdr.CUBE2check,
orderhdr.AMT2check,
nvl(orderhdr.staffhrs,0),
wave,
zoe.unknown_lip_count(orderhdr.orderid,orderhdr.shipid),
orderhdr.dateshipped,
orderhdr.deliveryservice,
orderhdr.saturdaydelivery,
orderhdr.specialservice1,
orderhdr.specialservice2,
orderhdr.specialservice3,
orderhdr.specialservice4,
orderhdr.cod,
orderhdr.amtcod,
nvl(orderhdr.asnvariance,'N'),
orderhdr.hdrpassthruchar01,
orderhdr.hdrpassthruchar02,
orderhdr.hdrpassthruchar03,
orderhdr.hdrpassthruchar04,
orderhdr.hdrpassthruchar05,
orderhdr.hdrpassthruchar06,
orderhdr.hdrpassthruchar07,
orderhdr.hdrpassthruchar08,
orderhdr.hdrpassthruchar09,
orderhdr.hdrpassthruchar10,
orderhdr.hdrpassthruchar11,
orderhdr.hdrpassthruchar12,
orderhdr.hdrpassthruchar13,
orderhdr.hdrpassthruchar14,
orderhdr.hdrpassthruchar15,
orderhdr.hdrpassthruchar16,
orderhdr.hdrpassthruchar17,
orderhdr.hdrpassthruchar18,
orderhdr.hdrpassthruchar19,
orderhdr.hdrpassthruchar20,
orderhdr.hdrpassthrunum01,
orderhdr.hdrpassthrunum02,
orderhdr.hdrpassthrunum03,
orderhdr.hdrpassthrunum04,
orderhdr.hdrpassthrunum05,
orderhdr.hdrpassthrunum06,
orderhdr.hdrpassthrunum07,
orderhdr.hdrpassthrunum08,
orderhdr.hdrpassthrunum09,
orderhdr.hdrpassthrunum10,
orderhdr.qtypick,
orderhdr.WEIGHTpick,
orderhdr.CUBEpick,
orderhdr.AMTpick,
orderhdr.FTZ216Authorization,
orderhdr.componenttemplate,
orderhdr.cancel_after,
orderhdr.delivery_requested,
orderhdr.requested_ship,
orderhdr.ship_not_before,
orderhdr.ship_no_later,
orderhdr.cancel_if_not_delivered_by,
orderhdr.do_not_deliver_after,
orderhdr.do_not_deliver_before,
orderhdr.hdrpassthrudate01,
orderhdr.hdrpassthrudate02,
orderhdr.hdrpassthrudate03,
orderhdr.hdrpassthrudate04,
orderhdr.hdrpassthrudoll01,
orderhdr.hdrpassthrudoll02,
orderhdr.TMS_Shipment_id,
orderhdr.TMS_release_id,
orderhdr.prono,
orderhdr.recent_order_id,
decode(orderhdr.shiptoname, null, consignee.name, orderhdr.shiptoname),
orderhdr.shippingcost,
orderhdr.xdockprocessing,
orderhdr.xdockorderid,
orderhdr.xdockshipid,
orderhdr.hdrpassthruchar21,
orderhdr.hdrpassthruchar22,
orderhdr.hdrpassthruchar23,
orderhdr.hdrpassthruchar24,
orderhdr.hdrpassthruchar25,
orderhdr.hdrpassthruchar26,
orderhdr.hdrpassthruchar27,
orderhdr.hdrpassthruchar28,
orderhdr.hdrpassthruchar29,
orderhdr.hdrpassthruchar30,
orderhdr.hdrpassthruchar31,
orderhdr.hdrpassthruchar32,
orderhdr.hdrpassthruchar33,
orderhdr.hdrpassthruchar34,
orderhdr.hdrpassthruchar35,
orderhdr.hdrpassthruchar36,
orderhdr.hdrpassthruchar37,
orderhdr.hdrpassthruchar38,
orderhdr.hdrpassthruchar39,
orderhdr.hdrpassthruchar40,
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightcommit),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightship),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weighttotcommit),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightrcvd),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightorder),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2sort),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2pack),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weight2check),
zwt.from_lbs_to_kgs(orderhdr.custid,orderhdr.weightpick),
nvl(orderhdr.weight_entered_lbs,0),
nvl(orderhdr.weight_entered_kgs,0),
orderhdr.parentorderid,
orderhdr.parentshipid,
decode(orderhdr.shiptoname, null, consignee.contact, orderhdr.shiptocontact),
decode(orderhdr.shiptoname, null, consignee.addr1, orderhdr.shiptoaddr1),
decode(orderhdr.shiptoname, null, consignee.addr2, orderhdr.shiptoaddr2),
decode(orderhdr.shiptoname, null, consignee.city, orderhdr.shiptocity),
decode(orderhdr.shiptoname, null, consignee.state, orderhdr.shiptostate),
decode(orderhdr.shiptoname, null, consignee.postalcode, orderhdr.shiptopostalcode),
decode(orderhdr.shiptoname, null, consignee.countrycode, orderhdr.shiptocountrycode),
decode(orderhdr.shiptoname, null, consignee.phone, orderhdr.shiptophone),
decode(orderhdr.shiptoname, null, consignee.fax, orderhdr.shiptofax),
decode(orderhdr.shiptoname, null, consignee.email, orderhdr.shiptoemail)
from orderstatus, ordertypes, shipmenttypes, shipmentterms,
     orderpriority, loads, loadstop, orderhdr, consignee
where orderhdr.orderstatus = orderstatus.code (+)
  and orderhdr.ordertype = ordertypes.code (+)
  and orderhdr.shiptype = shipmenttypes.code(+)
  and orderhdr.shipterms = shipmentterms.code(+)
  and orderhdr.priority = orderpriority.code(+)
  and orderhdr.loadno = loads.loadno(+)
  and orderhdr.loadno = loadstop.loadno(+)
  and orderhdr.stopno = loadstop.stopno(+)
  and orderhdr.shipto = consignee.consignee(+);

comment on table d2k_orderhdrview is '$Id$';

exit;