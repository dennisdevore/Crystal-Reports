CREATE OR REPLACE FORCE VIEW ALPS.LOADSORDERVIEW
(LOADSTOPSTATUS, LOADSTOPSTATUSABBREV, LOADSTOPSTAGELOC, LOADSTOPSHIPTO, BILLOFLADING,
 PRIORITY, PRIORITYABBREV, WEIGHTCOMMIT, CUBECOMMIT, AMTCOMMIT,
 QTYSHIP, WEIGHTSHIP, CUBESHIP, AMTSHIP, QTYTOTCOMMIT,
 WEIGHTTOTCOMMIT, CUBETOTCOMMIT, AMTTOTCOMMIT, QTYRCVD, WEIGHTRCVD,
 CUBERCVD, AMTRCVD, COMMENT1, STATUSUSER, STATUSUPDATE,
 LASTUSER, LASTUPDATE, ORDERID, SHIPID, CUSTID,
 ORDERTYPE, ORDERTYPEABBREV, ENTRYDATE, APPTDATE, SHIPDATE,
 PO, RMA, ORDERSTATUS, ORDERSTATUSABBREV, COMMITSTATUS,
 FROMFACILITY, TOFACILITY, LOADNO, STOPNO, SHIPNO,
 SHIPTO, SHIPTOSTATE, SHIPTOPOSTALCODE, DELAREA, QTYORDER, WEIGHTORDER, CUBEORDER,
 AMTORDER, QTYCOMMIT, ORDERHDRCARRIER, ARRIVALDATE, CONSIGNEE,
 SHIPTYPE, SHIPTYPEABBREV, CARRIER, REFERENCE, SHIPTERMS,
 HAZARDOUS, LOADSTATUS, WAVE, CUSTNAME, QTY2SORT,
 WEIGHT2SORT, CUBE2SORT, AMT2SORT, QTY2PACK, WEIGHT2PACK,
 CUBE2PACK, AMT2PACK, QTY2CHECK, WEIGHT2CHECK, CUBE2CHECK,
 AMT2CHECK, STAFFHOURS, DELIVERYSERVICE, SATURDAYDELIVERY, SPECIALSERVICE1,
 SPECIALSERVICE2, SPECIALSERVICE3, SPECIALSERVICE4, COD, AMTCOD,
 ASNVARIANCE, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR02, HDRPASSTHRUCHAR03, HDRPASSTHRUCHAR04,
 HDRPASSTHRUCHAR05, HDRPASSTHRUCHAR06, HDRPASSTHRUCHAR07, HDRPASSTHRUCHAR08, HDRPASSTHRUCHAR09,
 HDRPASSTHRUCHAR10, HDRPASSTHRUCHAR11, HDRPASSTHRUCHAR12, HDRPASSTHRUCHAR13, HDRPASSTHRUCHAR14,
 HDRPASSTHRUCHAR15, HDRPASSTHRUCHAR16, HDRPASSTHRUCHAR17, HDRPASSTHRUCHAR18, HDRPASSTHRUCHAR19,
 HDRPASSTHRUCHAR20, HDRPASSTHRUNUM01, HDRPASSTHRUNUM02, HDRPASSTHRUNUM03, HDRPASSTHRUNUM04,
 HDRPASSTHRUNUM05, HDRPASSTHRUNUM06, HDRPASSTHRUNUM07, HDRPASSTHRUNUM08, HDRPASSTHRUNUM09,
 HDRPASSTHRUNUM10, QTYPICK, WEIGHTPICK, CUBEPICK, AMTPICK,
 CANCEL_AFTER, DELIVERY_REQUESTED, REQUESTED_SHIP, SHIP_NOT_BEFORE, SHIP_NO_LATER,
 CANCEL_IF_NOT_DELIVERED_BY, DO_NOT_DELIVER_AFTER, DO_NOT_DELIVER_BEFORE, HDRPASSTHRUDATE01, HDRPASSTHRUDATE02,
 HDRPASSTHRUDATE03, HDRPASSTHRUDATE04, HDRPASSTHRUDOLL01, HDRPASSTHRUDOLL02, PAPERBASED,
 TMS_ORDERS_TO_PLAN_FORMAT, TMS_STATUS, SHIPTOEMAIL, XDOCKORDERID,
HDRPASSTHRUCHAR21, HDRPASSTHRUCHAR22, HDRPASSTHRUCHAR23, HDRPASSTHRUCHAR24,
HDRPASSTHRUCHAR25, HDRPASSTHRUCHAR26, HDRPASSTHRUCHAR27, HDRPASSTHRUCHAR28,
HDRPASSTHRUCHAR29, HDRPASSTHRUCHAR30, HDRPASSTHRUCHAR31, HDRPASSTHRUCHAR32,
HDRPASSTHRUCHAR33, HDRPASSTHRUCHAR34, HDRPASSTHRUCHAR35, HDRPASSTHRUCHAR36,
HDRPASSTHRUCHAR37, HDRPASSTHRUCHAR38, HDRPASSTHRUCHAR39, HDRPASSTHRUCHAR40,
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
HDRPASSTHRUCHAR41, HDRPASSTHRUCHAR42, HDRPASSTHRUCHAR43, HDRPASSTHRUCHAR44,
HDRPASSTHRUCHAR45, HDRPASSTHRUCHAR46, HDRPASSTHRUCHAR47, HDRPASSTHRUCHAR48,
HDRPASSTHRUCHAR49, HDRPASSTHRUCHAR50, HDRPASSTHRUCHAR51, HDRPASSTHRUCHAR52,
HDRPASSTHRUCHAR53, HDRPASSTHRUCHAR54, HDRPASSTHRUCHAR55, HDRPASSTHRUCHAR56,
HDRPASSTHRUCHAR57, HDRPASSTHRUCHAR58, HDRPASSTHRUCHAR59, HDRPASSTHRUCHAR60,
appointmentid,backorderyn,
shiptoname,shiptoaddr1,shiptoaddr2,shiptocity,
shiptocountrycode,shiptophone,shiptofax,
manual_picks_yn,
total_picks,
allocable_qty,
orderhdr_rowid
)
AS
select
loadstop.loadstopstatus,
substr(zld.loadstopstatus_abbrev(loadstop.loadstopstatus),1,12),
nvl(loadstop.STAGELOC,loads.stageloc),
nvl(loadstop.shipto,orderhdr.shipto_master),
orderhdr.BILLOFLADING,
orderhdr.PRIORITY,
orderpriority.abbrev,
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
orderhdr.ORDERTYPE,
ordertypes.abbrev,
orderhdr.ENTRYDATE,
nvl(orderhdr.APPTDATE,loads.apptdate),
orderhdr.SHIPDATE,
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
nvl(orderhdr.SHIPTOSTATE,consignee.STATE),
nvl(orderhdr.SHIPTOPOSTALCODE,consignee.POSTALCODE),
orderhdr.DELAREA,
orderhdr.QTYORDER,
orderhdr.WEIGHTORDER,
orderhdr.CUBEORDER,
orderhdr.AMTORDER,
orderhdr.QTYCOMMIT,
loads.carrier,
orderhdr.arrivaldate,
orderhdr.consignee,
orderhdr.shiptype,
shipmenttypes.abbrev,
nvl(loads.carrier,orderhdr.carrier),
orderhdr.reference,
orderhdr.shipterms,
substr(zci.hazardous_item_on_order(orderhdr.orderid,orderhdr.shipid),1,1),
loads.loadstatus,
orderhdr.wave,
customer.name,
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
orderhdr.QTYpick,
orderhdr.WEIGHTpick,
orderhdr.CUBEpick,
orderhdr.AMTpick,
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
customer.paperbased,
customer.tms_orders_to_plan_format,
orderhdr.tms_status,
decode(orderhdr.shiptoemail, null, consignee.email, orderhdr.shiptoemail),
nvl(orderhdr.xdockorderid,0),
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
orderhdr.appointmentid,
orderhdr.backorderyn,
decode(orderhdr.shiptoname, null, consignee.contact, orderhdr.shiptocontact),
decode(orderhdr.shiptoname, null, consignee.addr1, orderhdr.shiptoaddr1),
decode(orderhdr.shiptoname, null, consignee.addr2, orderhdr.shiptoaddr2),
decode(orderhdr.shiptoname, null, consignee.city, orderhdr.shiptocity),
decode(orderhdr.shiptoname, null, consignee.countrycode, orderhdr.shiptocountrycode),
decode(orderhdr.shiptoname, null, consignee.phone, orderhdr.shiptophone),
decode(orderhdr.shiptoname, null, consignee.fax, orderhdr.shiptofax),
nvl(orderhdr.manual_picks_yn,'N'),
zgl.total_picks_for_order(orderhdr.orderid,orderhdr.shipid),
zcm.order_allocable_qty(orderhdr.fromfacility,orderhdr.custid,orderhdr.orderid,orderhdr.shipid),
orderhdr.rowid
 from orderpriority, ordertypes, orderstatus, shipmenttypes,
      loadstop, loads, customer, orderhdr, consignee
where orderhdr.loadno = loadstop.loadno (+)
  and orderhdr.stopno = loadstop.stopno (+)
  and orderhdr.loadno = loads.loadno (+)
  and orderhdr.custid = customer.custid (+)
  and orderhdr.shiptype = shipmenttypes.code(+)
  and orderhdr.orderstatus = orderstatus.code(+)
  and orderhdr.ordertype = ordertypes.code(+)
  and orderhdr.priority = orderpriority.code(+)
  and orderhdr.shipto = consignee.consignee(+);

comment on table loadsorderview is '$Id';

show error view loadsorderview;

exit;
