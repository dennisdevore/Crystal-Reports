CREATE OR REPLACE VIEW TMSCONSIGNEEVIEW ( SHIPTERMS,
APPTREQUIRED, BILLFORPALLETS, MASTERACCOUNT, CONSIGNEE,
NAME, CONTACT, ADDR1, ADDR2,
CITY, STATE, POSTALCODE, COUNTRYCODE,
PHONE, FAX, EMAIL, CONSIGNEESTATUS,
LASTUSER, LASTUPDATE, LTLCARRIER, TLCARRIER,
SPSCARRIER, BILLTO, SHIPTO, RAILCARRIER,
BILLTOCONSIGNEE, SHIPTYPE, AREA ) AS select /*+ ALL_ROWS */ a.SHIPTERMS,
a.APPTREQUIRED,
a.BILLFORPALLETS,
a.MASTERACCOUNT,
a.CONSIGNEE,
a.NAME,
a.CONTACT,
a.ADDR1,
a.ADDR2,
a.CITY,
a.STATE,
nvl(postalcode,'00000') as postalcode,		
a.COUNTRYCODE,
a.PHONE,
a.FAX,
a.EMAIL,
a.CONSIGNEESTATUS,
a.LASTUSER,
a.LASTUPDATE,
a.LTLCARRIER,
a.TLCARRIER,
a.SPSCARRIER,
a.BILLTO,
a.SHIPTO,
a.RAILCARRIER,
a.BILLTOCONSIGNEE,
a.SHIPTYPE,
b.area
from consignee a, tmsservicezip b
where nvl(postalcode,'00000') between  begzip and endzip;

comment on table TMSCONSIGNEEVIEW is '$Id$';



CREATE OR REPLACE VIEW TMSORDERHDRVIEW ( BILLOFLADING,
PRIORITY, WEIGHTCOMMIT, CUBECOMMIT, AMTCOMMIT,
QTYSHIP, WEIGHTSHIP, CUBESHIP, AMTSHIP,
QTYTOTCOMMIT, WEIGHTTOTCOMMIT, CUBETOTCOMMIT, AMTTOTCOMMIT,
QTYRCVD, WEIGHTRCVD, CUBERCVD, AMTRCVD,
COMMENT1, STATUSUSER, STATUSUPDATE, LASTUSER,
LASTUPDATE, ORDERID, SHIPID, CUSTID,
ORDERTYPE, ORDERTYPEABBREV, ENTRYDATE, APPTDATE,
SHIPDATE, PO, RMA, ORDERSTATUS,
ORDERSTATUSABBREV, COMMITSTATUS, FROMFACILITY, TOFACILITY,
LOADNO, STOPNO, SHIPNO, SHIPTO,
DELAREA, QTYORDER, WEIGHTORDER, CUBEORDER,
AMTORDER, QTYCOMMIT, ARRIVALDATE, CONSIGNEE,
SHIPTYPE, CARRIER, REFERENCE, SHIPTERMS,
SHIPTYPEABBREV, SHIPTERMSABBREV, PRIORITYABBREV, HAZARDOUS,
STAGELOC, QTY2SORT, WEIGHT2SORT, CUBE2SORT,
AMT2SORT, QTY2PACK, WEIGHT2PACK, CUBE2PACK,
AMT2PACK, QTY2CHECK, WEIGHT2CHECK, CUBE2CHECK,
AMT2CHECK, STAFFHRS, WAVE, UNKNOWNLIPCOUNT,
DATESHIPPED, DELIVERYSERVICE, SATURDAYDELIVERY, SPECIALSERVICE1,
SPECIALSERVICE2, SPECIALSERVICE3, SPECIALSERVICE4, COD,
AMTCOD, ASNVARIANCE, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR02,
HDRPASSTHRUCHAR03, HDRPASSTHRUCHAR04, HDRPASSTHRUCHAR05, HDRPASSTHRUCHAR06,
HDRPASSTHRUCHAR07, HDRPASSTHRUCHAR08, HDRPASSTHRUCHAR09, HDRPASSTHRUCHAR10,
HDRPASSTHRUCHAR11, HDRPASSTHRUCHAR12, HDRPASSTHRUCHAR13, HDRPASSTHRUCHAR14,
HDRPASSTHRUCHAR15, HDRPASSTHRUCHAR16, HDRPASSTHRUCHAR17, HDRPASSTHRUCHAR18,
HDRPASSTHRUCHAR19, HDRPASSTHRUCHAR20, HDRPASSTHRUNUM01, HDRPASSTHRUNUM02,
HDRPASSTHRUNUM03, HDRPASSTHRUNUM04, HDRPASSTHRUNUM05, HDRPASSTHRUNUM06,
HDRPASSTHRUNUM07, HDRPASSTHRUNUM08, HDRPASSTHRUNUM09, HDRPASSTHRUNUM10,
QTYPICK, WEIGHTPICK, CUBEPICK, AMTPICK,
TRANSAPPTDATE, DELIVERYAPTCONFNAME, INTERLINECARRIER, COMPANYCHECKOK,
TMSORDERSTATUS, NAME, PHONE, APPTREQUIRED,
CITY, STATE, POSTALCODE, AREA, DEFAULTCARRIER,
SERVICEDAYS, ROUTE,PALLETS,PRONO,recent_order_id,
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
weight_entered_kgs
) AS
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
orderhdr.ORDERTYPE,
ordertypes.abbrev,
orderhdr.ENTRYDATE,
orderhdr.APPTDATE,
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
orderhdr.TRANSAPPTDATE,
orderhdr.DELIVERYAPTCONFNAME,
orderhdr.INTERLINECARRIER,
orderhdr.companycheckok,
decode(orderhdr.orderstatus,'1','P','2','P','3','P','4','P','5','P','6','P',
 '6','P','7','P','8','P','9','S',orderhdr.orderstatus),
nvl(tmsconsigneeview.name,orderhdr.shiptoname),
nvl(tmsconsigneeview.phone,orderhdr.shiptophone),
nvl(tmsconsigneeview.apptrequired,'N'),
nvl(tmsconsigneeview.city,orderhdr.shiptocity),
nvl(tmsconsigneeview.state,orderhdr.shiptostate),
nvl(tmsconsigneeview.postalcode,orderhdr.shiptopostalcode),
nvl(nvl(tmsconsigneeview.area,(select area from tmsservicezip where orderhdr.shiptopostalcode
                             between begzip and endzip)),'DEF'),
(select tmsserviceroute.defaultcarrier from tmsserviceroute
where nvl(nvl(tmsconsigneeview.AREA,(select area from tmsservicezip where
  		orderhdr.shiptopostalcode between begzip and endzip)),'DEF') = tmsserviceroute.AREA
  and facility.facilitygroup = tmsserviceroute.facilitygroup),
(select tmsserviceroute.servicedays from tmsserviceroute
where nvl(nvl(tmsconsigneeview.AREA,(select area from tmsservicezip where
  		orderhdr.shiptopostalcode between begzip and endzip)),'DEF') = tmsserviceroute.AREA
  and facility.facilitygroup = tmsserviceroute.facilitygroup),
(select tmsserviceroute.route from tmsserviceroute
where nvl(nvl(tmsconsigneeview.AREA,(select area from tmsservicezip where
  		orderhdr.shiptopostalcode between begzip and endzip)),'DEF') = tmsserviceroute.AREA
  and facility.facilitygroup = tmsserviceroute.facilitygroup),
orderpalletview.outpallets,
orderhdr.prono,
orderhdr.recent_order_id,
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
nvl(orderhdr.weight_entered_kgs,0)
from orderhdr, orderstatus, ordertypes, shipmenttypes, shipmentterms,
     orderpriority, loads, loadstop, tmsconsigneeview,facility,orderpalletview
where orderhdr.orderstatus = orderstatus.code (+)
  and orderhdr.ordertype = ordertypes.code (+)
  and orderhdr.shiptype = shipmenttypes.code(+)
  and orderhdr.shipterms = shipmentterms.code(+)
  and orderhdr.priority = orderpriority.code(+)
  and orderhdr.loadno = loads.loadno(+)
  and orderhdr.loadno = loadstop.loadno(+)
  and orderhdr.stopno = loadstop.stopno(+)
  and orderhdr.shipto = tmsconsigneeview.CONSIGNEE (+)
  and orderhdr.FROMFACILITY = facility.facility (+)
  and orderhdr.orderid = orderpalletview.orderid (+)
  and orderhdr.shipid  = orderpalletview.shipid (+);

comment on table TMSORDERHDRVIEW is '$Id$';




CREATE OR REPLACE VIEW TMSORDERHDRNOPLTVIEW ( BILLOFLADING,
PRIORITY, WEIGHTCOMMIT, CUBECOMMIT, AMTCOMMIT,
QTYSHIP, WEIGHTSHIP, CUBESHIP, AMTSHIP,
QTYTOTCOMMIT, WEIGHTTOTCOMMIT, CUBETOTCOMMIT, AMTTOTCOMMIT,
QTYRCVD, WEIGHTRCVD, CUBERCVD, AMTRCVD,
COMMENT1, STATUSUSER, STATUSUPDATE, LASTUSER,
LASTUPDATE, ORDERID, SHIPID, CUSTID,
ORDERTYPE, ORDERTYPEABBREV, ENTRYDATE, APPTDATE,
SHIPDATE, PO, RMA, ORDERSTATUS,
ORDERSTATUSABBREV, COMMITSTATUS, FROMFACILITY, TOFACILITY,
LOADNO, STOPNO, SHIPNO, SHIPTO,
DELAREA, QTYORDER, WEIGHTORDER, CUBEORDER,
AMTORDER, QTYCOMMIT, ARRIVALDATE, CONSIGNEE,
SHIPTYPE, CARRIER, REFERENCE, SHIPTERMS,
SHIPTYPEABBREV, SHIPTERMSABBREV, PRIORITYABBREV, HAZARDOUS,
STAGELOC, QTY2SORT, WEIGHT2SORT, CUBE2SORT,
AMT2SORT, QTY2PACK, WEIGHT2PACK, CUBE2PACK,
AMT2PACK, QTY2CHECK, WEIGHT2CHECK, CUBE2CHECK,
AMT2CHECK, STAFFHRS, WAVE, UNKNOWNLIPCOUNT,
DATESHIPPED, DELIVERYSERVICE, SATURDAYDELIVERY, SPECIALSERVICE1,
SPECIALSERVICE2, SPECIALSERVICE3, SPECIALSERVICE4, COD,
AMTCOD, ASNVARIANCE, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR02,
HDRPASSTHRUCHAR03, HDRPASSTHRUCHAR04, HDRPASSTHRUCHAR05, HDRPASSTHRUCHAR06,
HDRPASSTHRUCHAR07, HDRPASSTHRUCHAR08, HDRPASSTHRUCHAR09, HDRPASSTHRUCHAR10,
HDRPASSTHRUCHAR11, HDRPASSTHRUCHAR12, HDRPASSTHRUCHAR13, HDRPASSTHRUCHAR14,
HDRPASSTHRUCHAR15, HDRPASSTHRUCHAR16, HDRPASSTHRUCHAR17, HDRPASSTHRUCHAR18,
HDRPASSTHRUCHAR19, HDRPASSTHRUCHAR20, HDRPASSTHRUNUM01, HDRPASSTHRUNUM02,
HDRPASSTHRUNUM03, HDRPASSTHRUNUM04, HDRPASSTHRUNUM05, HDRPASSTHRUNUM06,
HDRPASSTHRUNUM07, HDRPASSTHRUNUM08, HDRPASSTHRUNUM09, HDRPASSTHRUNUM10,
QTYPICK, WEIGHTPICK, CUBEPICK, AMTPICK,
TRANSAPPTDATE, DELIVERYAPTCONFNAME, INTERLINECARRIER, COMPANYCHECKOK,
TMSORDERSTATUS, NAME, PHONE, APPTREQUIRED,
CITY, STATE, POSTALCODE, AREA, DEFAULTCARRIER,
SERVICEDAYS, ROUTE,PRONO,recent_order_id ) AS
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
orderhdr.ORDERTYPE,
ordertypes.abbrev,
orderhdr.ENTRYDATE,
orderhdr.APPTDATE,
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
orderhdr.TRANSAPPTDATE,
orderhdr.DELIVERYAPTCONFNAME,
orderhdr.INTERLINECARRIER,
orderhdr.companycheckok,
decode(orderhdr.orderstatus,'1','P','2','P','3','P','4','P','5','P','6','P',
 '6','P','7','P','8','P','9','S',orderhdr.orderstatus),
nvl(tmsconsigneeview.name,orderhdr.shiptoname),
nvl(tmsconsigneeview.phone,orderhdr.shiptophone),
nvl(tmsconsigneeview.apptrequired,'N'),
nvl(tmsconsigneeview.city,orderhdr.shiptocity),
nvl(tmsconsigneeview.state,orderhdr.shiptostate),
nvl(tmsconsigneeview.postalcode,orderhdr.shiptopostalcode),
nvl(nvl(tmsconsigneeview.area,(select area from tmsservicezip where orderhdr.shiptopostalcode
                             between begzip and endzip)),'DEF'),
(select tmsserviceroute.defaultcarrier from tmsserviceroute
where nvl(nvl(tmsconsigneeview.AREA,(select area from tmsservicezip where
  		orderhdr.shiptopostalcode between begzip and endzip)),'DEF') = tmsserviceroute.AREA
  and facility.facilitygroup = tmsserviceroute.facilitygroup),
(select tmsserviceroute.servicedays from tmsserviceroute
where nvl(nvl(tmsconsigneeview.AREA,(select area from tmsservicezip where
  		orderhdr.shiptopostalcode between begzip and endzip)),'DEF') = tmsserviceroute.AREA
  and facility.facilitygroup = tmsserviceroute.facilitygroup),
(select tmsserviceroute.route from tmsserviceroute
where nvl(nvl(tmsconsigneeview.AREA,(select area from tmsservicezip where
  		orderhdr.shiptopostalcode between begzip and endzip)),'DEF') = tmsserviceroute.AREA
  and facility.facilitygroup = tmsserviceroute.facilitygroup),
orderhdr.prono,
orderhdr.recent_order_id
from orderhdr, orderstatus, ordertypes, shipmenttypes, shipmentterms,
     orderpriority, loads, loadstop, tmsconsigneeview,facility
where orderhdr.orderstatus = orderstatus.code (+)
  and orderhdr.ordertype = ordertypes.code (+)
  and orderhdr.shiptype = shipmenttypes.code(+)
  and orderhdr.shipterms = shipmentterms.code(+)
  and orderhdr.priority = orderpriority.code(+)
  and orderhdr.loadno = loads.loadno(+)
  and orderhdr.loadno = loadstop.loadno(+)
  and orderhdr.stopno = loadstop.stopno(+)
  and orderhdr.shipto = tmsconsigneeview.CONSIGNEE (+)
  and orderhdr.FROMFACILITY = facility.facility (+);

comment on table TMSORDERHDRNOPLTVIEW is '$Id$';




CREATE OR REPLACE VIEW TMSCUSTCONSNVIEW ( ID,
NAME, ADDR1, ADDR2, CITY,
STATE, POSTALCODE, COUTNRY, LASTUPDATE
 ) AS select consignee as ID,name,addr1,addr2,city,state,postalcode,b.descr as coutnry,a.lastupdate
from consignee a, countrycodes b
where a.countrycode = b.code
union
select 'B'||lpad(custid,8,'0') as ID,
name,addr1,addr2,city,state,postalcode,b.descr as coutnry,a.lastupdate
from customer a, countrycodes b
where a.countrycode = b.code;

comment on table TMSCUSTCONSNVIEW is '$Id$';

CREATE OR REPLACE VIEW TMSEXPORTVIEW ( BOL,
CUSTID, SEQ, ORDERSTATUS, SHIPPER,
CONSIGNEE, BILLTO, SHIPDATE, ARRIVALDATE,
ORDERDATE, SHIPTERMS, SCAC, PO,
REFERENCE, PRONO, APPTDATE, AMTCOD,
REVENUCODE, HAZFLAG, QTYSHIP, WEIGHTSHIP,
TERMINALCODE, ORDERID, SHIPID,FACILITY,CONFNAME,INERLINECARRIER,COMPANYCHECKOK,SERVICEDAYS,PALLETS ) AS
select to_char(oh.orderid) || '-' || to_char(oh.shipid) as BOL,custid,
'00' as SEQ, oh.orderstatus,
  lpad(oh.custid,9,'0') as shipper,oh.shipto,
 decode(oh.shipterms,'COL',oh.shipto, 'PPD','B'||lpad(oh.custid,8,'0'),'3RD',oh.consignee) as billto,
 oh.shipdate,oh.arrivaldate,oh.entrydate as orderdate,oh.shipterms,
 oh.carrier as scac,oh.po,oh.reference, nvl(oh.prono,ld.prono),oh.transapptdate,oh.amtcod,
 decode(oh.state,'CA',4,2) as revenucode,
  substr(zci.hazardous_item_on_order(oh.orderid,oh.shipid),1,1) as hazflag,
 oh.qtyship,round(oh.weightship,0),
 oh.route,
 oh.orderid,oh.shipid,oh.fromfacility,oh.deliveryaptconfname,oh.interlinecarrier,oh.companycheckok,
 oh.servicedays,oh.pallets
from TMSORDERHDRVIEW oh, loads ld
where oh.ordertype = 'O' and oh.orderstatus = '9'
and oh.loadno =ld.loadno (+);
--and oh.orderid < 10000;

comment on table TMSEXPORTVIEW is '$Id$';

CREATE OR REPLACE VIEW TMS_DETAILVIEW ( DETAILBOL,
SEQ, LINETYPE, PIECES, WEIGHT,
HAZFLAG, LTLCLASS, DESCRIPTION, ORDERID,
SHIPID ) AS select BOL as DETAILBOL,SEQ,LINETYPE,PIECES,WEIGHT,HAZFLAG,LTLCLASS,DESCRIPTION,
  substr(bol,1,instr(bol,'-') - 1) as orderid, substr(bol,instr(bol,'-') + 1,1 ) as shipid
  from tmsexport;

comment on table TMS_DETAILVIEW is '$Id$';

CREATE OR REPLACE VIEW TMS_HDRVIEW ( BOL,
CUSTID, SEQ, ORDERSTATUS, SHIPPER,
CONSIGNEE, BILLTO, SHIPDATE, ARRIVALDATE,
ORDERDATE, SHIPTERMS, SCAC, PO,
REFERENCE, PRONO, APPTDATE, AMTCOD,
REVENUCODE, HAZFLAG, QTYSHIP, WEIGHTSHIP,
TERMINALCODE, ORDERID, SHIPID,FACILITY,CONFNAME,INERLINECARRIER,COMPANYCHECKOK,SERVICEDAYS,PALLETS ) AS
select BOL,CUSTID,SEQ,ORDERSTATUS,SHIPPER,CONSIGNEE,BILLTO,SHIPDATE,ARRIVALDATE,
	ORDERDATE,SHIPTERMS,SCAC,PO,REFERENCE,PRONO,APPTDATE,AMTCOD,REVENUCODE,HAZFLAG,QTYSHIP,
	WEIGHTSHIP,TERMINALCODE,ORDERID,SHIPID,FACILITY,CONFNAME,INERLINECARRIER,COMPANYCHECKOK,SERVICEDAYS,PALLETS
from tmsexportview;

comment on table TMS_HDRVIEW is '$Id$';


exit;


