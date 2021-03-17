CREATE OR REPLACE function ordertrackingnos(in_orderid number, in_shipid number)
return varchar2 is
strTrackingNo varchar2(30);
intCount integer;

begin

strTrackingNo := '';

select count(distinct trackingno)
into intCount
from shippingplate
where orderid = in_orderid
and shipid = in_shipid
and trackingno is not null;

if (intCount = 1) then
	select distinct trackingno
	into strTrackingNo
  from shippingplate
  where orderid = in_orderid
  and shipid = in_shipid
  and trackingno is not null;
elsif (intCount > 1) then
	strTrackingNo := 'Multiple';
end if;

return strTrackingNo;
exception when others then
  return '';
end ordertrackingnos;
/

CREATE OR REPLACE function weborderattachment(in_userid varchar2, in_orderid number)
return varchar2 is
strPDFBOLPath varchar2(255);
strWEBPDFPath varchar2(255);
strFilePath varchar2(255);
strAttachment varchar2(255);

cursor curAttachment
is
  select trim(sd1.defaultvalue) pdfbolpath,
         trim(sd2.defaultvalue) webpdfpath,
         trim(oa.filepath) filepath
    from orderhdr oh,
         orderattach oa,
         systemdefaults sd1,
         systemdefaults sd2
   where oh.orderid = in_orderid
     and oa.orderid = oh.orderid
     and sd1.defaultid = 'PDFBOLPATH'
     and sd2.defaultid = 'WEBPDFPATH'
     and exists(select 1
                  from tbl_user_facilities
                 where nameid = in_userid
                   and facility_id in (oh.fromfacility,oh.tofacility))
     and oh.custid in(select custid
                        from customer, tbl_user_profile
                       where instr(','||assigned_customer||',', ','||custid||',', 1, 1) > 0
                         and nameid=in_userid)
   order by oa.lastupdate desc;

begin

strPDFBOLPath := '';
strWEBPDFPath := '';
strFilePath := '';
strAttachment := '';

open curAttachment;
fetch curAttachment into strPDFBOLPath,strWEBPDFPath,strFilePath;
close curAttachment;

if (strFilePath is null) then
  return '';
end if;

if (instr(strPDFBOLPath, '/') = 0) and (substr(strPDFBOLPath,-1) <> '\') then
  strPDFBOLPath := strPDFBOLPath || '\';
end if;

if (instr(strPDFBOLPath, '/') <> 0) and (substr(strPDFBOLPath,-1) <> '/') then
  strPDFBOLPath := strPDFBOLPath || '/';
end if;

if (instr(strWEBPDFPath, '/') = 0) and (substr(strWEBPDFPath,-1) <> '\') then
  strWEBPDFPath := strWEBPDFPath || '\';
end if;

if (instr(strWEBPDFPath, '/') <> 0) and (substr(strWEBPDFPath,-1) <> '/') then
  strWEBPDFPath := strWEBPDFPath || '/';
end if;

strPDFBOLPath := replace(replace(strPDFBOLPath,'%FACILITY%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%CUSTOMER%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%CUSTHASH%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%LOAD%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%SHIPDATE%',''),'\\','\');

if (instr(strFilePath,strPDFBOLPath) = 0) then
  return '';
end if;

strAttachment := strWEBPDFPath||replace(replace(strFilePath,strPDFBOLPath,''),'\\','\');

return strAttachment;

exception when others then
  return '';
end weborderattachment;
/

CREATE OR REPLACE function haspdfattachment(in_orderid number)
return varchar2 is
strPDFBOLPath varchar2(255);
strFilePath varchar2(255);

cursor curAttachment
is
  select trim(sd1.defaultvalue) pdfbolpath,
         trim(oa.filepath) filepath
    from orderattach oa,
         systemdefaults sd1,
         systemdefaults sd2
   where oa.orderid = in_orderid
     and sd1.defaultid = 'PDFBOLPATH'
     and sd2.defaultid = 'WEBPDFPATH'
   order by oa.lastupdate desc;

begin

strPDFBOLPath := '';
strFilePath := '';

open curAttachment;
fetch curAttachment into strPDFBOLPath,strFilePath;
close curAttachment;

if (strFilePath is null) then
  return 'N';
end if;

if (substr(strPDFBOLPath,-1) <> '\') then
  strPDFBOLPath := strPDFBOLPath || '\';
end if;

strPDFBOLPath := replace(replace(strPDFBOLPath,'%FACILITY%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%CUSTOMER%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%CUSTHASH%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%LOAD%',''),'\\','\');
strPDFBOLPath := replace(replace(strPDFBOLPath,'%SHIPDATE%',''),'\\','\');

if (instr(strFilePath,strPDFBOLPath) = 0) then
  return 'N';
end if;

return 'Y';

exception when others then
  return 'N';
end haspdfattachment;
/

CREATE OR REPLACE VIEW WEBORDERHDRVIEW ( BILLOFLADING,
PRIORITY, WEIGHTCOMMIT, CUBECOMMIT, AMTCOMMIT,
QTYSHIP, WEIGHTSHIP, CUBESHIP, AMTSHIP,
QTYTOTCOMMIT, WEIGHTTOTCOMMIT, CUBETOTCOMMIT, AMTTOTCOMMIT,
QTYRCVD, WEIGHTRCVD, CUBERCVD, AMTRCVD,
COMMENT1, STATUSUSER, STATUSUPDATE, LASTUSER,
LASTUPDATE, ORDERID, SHIPID, CUSTID,
ORDERTYPE, ORDERTYPEABBREV, ENTRYDATE, APPTDATE,
SHIPDATE, PO, RMA, ORDERSTATUS,
ORDERSTATUSABBREV, COMMITSTATUS, FROMFACILITY, TOFACILITY,
LOADNO, STOPNO, SHIPNO,
DELAREA, QTYORDER, WEIGHTORDER, CUBEORDER,
AMTORDER, QTYCOMMIT, ARRIVALDATE,
SHIPTYPE, CARRIER, REFERENCE, SHIPTERMS,
SHIPTYPEABBREV, SHIPTERMSABBREV, PRIORITYABBREV, HAZARDOUS,
STAGELOC, QTY2SORT, WEIGHT2SORT, CUBE2SORT,
AMT2SORT, QTY2PACK, WEIGHT2PACK, CUBE2PACK,
AMT2PACK, QTY2CHECK, WEIGHT2CHECK, CUBE2CHECK,
AMT2CHECK, STAFFHRS, WAVE, UNKNOWNLIPCOUNT,
ACTUALSHIPDATE, DELIVERYSERVICE, SATURDAYDELIVERY, SPECIALSERVICE1,
SPECIALSERVICE2, SPECIALSERVICE3, SPECIALSERVICE4, COD,
AMTCOD, ASNVARIANCE, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR02,
HDRPASSTHRUCHAR03, HDRPASSTHRUCHAR04, HDRPASSTHRUCHAR05, HDRPASSTHRUCHAR06,
HDRPASSTHRUCHAR07, HDRPASSTHRUCHAR08, HDRPASSTHRUCHAR09, HDRPASSTHRUCHAR10,
HDRPASSTHRUCHAR11, HDRPASSTHRUCHAR12, HDRPASSTHRUCHAR13, HDRPASSTHRUCHAR14,
HDRPASSTHRUCHAR15, HDRPASSTHRUCHAR16, HDRPASSTHRUCHAR17, HDRPASSTHRUCHAR18,
HDRPASSTHRUCHAR19, HDRPASSTHRUCHAR20, HDRPASSTHRUCHAR21, HDRPASSTHRUCHAR22,
HDRPASSTHRUCHAR23, HDRPASSTHRUCHAR24, HDRPASSTHRUCHAR25, HDRPASSTHRUCHAR26,
HDRPASSTHRUCHAR27, HDRPASSTHRUCHAR28, HDRPASSTHRUCHAR29, HDRPASSTHRUCHAR30,
HDRPASSTHRUCHAR31, HDRPASSTHRUCHAR32, HDRPASSTHRUCHAR33, HDRPASSTHRUCHAR34,
HDRPASSTHRUCHAR35, HDRPASSTHRUCHAR36, HDRPASSTHRUCHAR37, HDRPASSTHRUCHAR38,
HDRPASSTHRUCHAR39, HDRPASSTHRUCHAR40, HDRPASSTHRUCHAR41, HDRPASSTHRUCHAR42,
HDRPASSTHRUCHAR43, HDRPASSTHRUCHAR44, HDRPASSTHRUCHAR45, HDRPASSTHRUCHAR46,
HDRPASSTHRUCHAR47, HDRPASSTHRUCHAR48, HDRPASSTHRUCHAR49, HDRPASSTHRUCHAR50,
HDRPASSTHRUCHAR51, HDRPASSTHRUCHAR52, HDRPASSTHRUCHAR53, HDRPASSTHRUCHAR54,
HDRPASSTHRUCHAR55, HDRPASSTHRUCHAR56, HDRPASSTHRUCHAR57, HDRPASSTHRUCHAR58,
HDRPASSTHRUCHAR59, HDRPASSTHRUCHAR60, HDRPASSTHRUDATE01, HDRPASSTHRUDATE02,
HDRPASSTHRUDATE03, HDRPASSTHRUDATE04, HDRPASSTHRUDOLL01, HDRPASSTHRUDOLL02,
HDRPASSTHRUNUM01, HDRPASSTHRUNUM02, HDRPASSTHRUNUM03, HDRPASSTHRUNUM04,
HDRPASSTHRUNUM05, HDRPASSTHRUNUM06, HDRPASSTHRUNUM07, HDRPASSTHRUNUM08,
HDRPASSTHRUNUM09, HDRPASSTHRUNUM10, QTYPICK, WEIGHTPICK, CUBEPICK, AMTPICK,
FTZ216AUTHORIZATION,SHIPTO,CONSIGNEE,PRONUMBER,SHIPTOID,BILLTOID,SHIPPER,
CANCELAFTERDATE,DELIVERYREQUESTEDDATE,REQUESTEDSHIPDATE,SHIPNOTBEFOREDATE,
SHIPNOLATERDATE,CANCELIFNOTDELIVEREDBYDATE,
DONOTDELIVERAFTERDATE,DONOTDELIVERBEFOREDATE,
SHIPTOCONTACT,
SHIPTOADDR1,
SHIPTOADDR2,
SHIPTOCITY,
SHIPTOSTATE,
SHIPTOPOSTALCODE,
SHIPTOCOUNTRYCODE,
SHIPTOPHONE,
SHIPTOFAX,
SHIPTOEMAIL,
BILLTOCONTACT,
BILLTOADDR1,
BILLTOADDR2,
BILLTOCITY,
BILLTOSTATE,
BILLTOPOSTALCODE,
BILLTOCOUNTRYCODE,
BILLTOPHONE,
BILLTOFAX,
BILLTOEMAIL,
TRAILER,
BILLLADING,
TRACKINGNUMBER,
SERVICECLASS,
EXPANDED_WEBSYNAPSE_FIELDS,
HDRCOMMENTS,
BOLCOMMENTS,
QTYCOMMITVARIANCE,
ATTACHMENT,
RECENT_ORDER_ID
) as
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
orderhdr.shipdate,
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
orderhdr.DELAREA,
orderhdr.QTYORDER,
orderhdr.WEIGHTORDER,
orderhdr.CUBEORDER,
orderhdr.AMTORDER,
orderhdr.QTYCOMMIT,
decode (orderhdr.ordertype,'R',nvl(loads.rcvddate,sysdate),'C',nvl(loads.rcvddate,sysdate),
orderhdr.arrivaldate),
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
to_char(orderhdr.hdrpassthrudate01,'MMDDYYYY'),
to_char(orderhdr.hdrpassthrudate02,'MMDDYYYY'),
to_char(orderhdr.hdrpassthrudate03,'MMDDYYYY'),
to_char(orderhdr.hdrpassthrudate04,'MMDDYYYY'),
orderhdr.hdrpassthrudoll01,
orderhdr.hdrpassthrudoll02,
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
nvl(orderhdr.SHIPTONAME,cons_ship.name),
nvl(orderhdr.BILLTONAME,cons_bill.name),
orderhdr.prono,
orderhdr.shipto,
orderhdr.consignee,
orderhdr.shipper,
to_char(orderhdr.cancel_after,'MMDDYYYY'),
to_char(orderhdr.delivery_requested,'MMDDYYYY'),
to_char(orderhdr.requested_ship,'MMDDYYYY'),
to_char(orderhdr.ship_not_before,'MMDDYYYY'),
to_char(orderhdr.ship_no_later,'MMDDYYYY'),
to_char(orderhdr.cancel_if_not_delivered_by,'MMDDYYYY'),
to_char(orderhdr.do_not_deliver_after,'MMDDYYYY'),
to_char(orderhdr.do_not_deliver_before,'MMDDYYYY'),
nvl(orderhdr.shiptocontact,cons_ship.contact),
nvl(orderhdr.shiptoaddr1,cons_ship.addr1),
nvl(orderhdr.shiptoaddr2,cons_ship.addr2),
nvl(orderhdr.shiptocity,cons_ship.city),
nvl(orderhdr.shiptostate,cons_ship.state),
nvl(orderhdr.shiptopostalcode,cons_ship.postalcode),
nvl(orderhdr.shiptocountrycode,cons_ship.countrycode),
nvl(orderhdr.shiptophone,cons_ship.phone),
nvl(orderhdr.shiptofax,cons_ship.fax),
nvl(orderhdr.shiptoemail,cons_ship.email),
nvl(orderhdr.billtocontact,cons_bill.contact),
nvl(orderhdr.billtoaddr1,cons_bill.addr1),
nvl(orderhdr.billtoaddr2,cons_bill.addr2),
nvl(orderhdr.billtocity,cons_bill.city),
nvl(orderhdr.billtostate,cons_bill.state),
nvl(orderhdr.billtopostalcode,cons_bill.postalcode),
nvl(orderhdr.billtocountrycode,cons_bill.countrycode),
nvl(orderhdr.billtophone,cons_bill.phone),
nvl(orderhdr.billtofax,cons_bill.fax),
nvl(orderhdr.billtoemail,cons_bill.email),
loads.trailer,
nvl(orderhdr.BILLOFLADING,loads.BILLOFLADING),
decode((select count(distinct trackingno)
from shippingplate
where orderid = orderhdr.orderid
and shipid = orderhdr.shipid
and trackingno is not null),0,'',
1,(select distinct trackingno
from shippingplate
where orderid = orderhdr.orderid
and shipid = orderhdr.shipid
and trackingno is not null),
'Multiple'),
trim(nvl(carrier.name,' ')||' '||nvl(carrierservicecodes.descr,' ')),
nvl(orderhdr.expanded_websynapse_fields,'N'),
zbol.orderidhdrcomments(orderhdr.orderid, orderhdr.shipid),
zbol.orderhdrbolcomments(orderhdr.orderid, orderhdr.shipid),
nvl(orderhdr.qtyorder,0)-nvl(orderhdr.qtycommit,0),
haspdfattachment(orderhdr.orderid) attachment,
orderhdr.recent_order_id
from orderhdr, orderstatus, ordertypes, shipmenttypes, shipmentterms,
     orderpriority, loads, loadstop,  consignee cons_bill, consignee cons_ship,
     carrier, carrierservicecodes
where orderhdr.orderstatus = orderstatus.code (+)
  and orderhdr.ordertype = ordertypes.code (+)
  and orderhdr.shiptype = shipmenttypes.code(+)
  and orderhdr.shipterms = shipmentterms.code(+)
  and orderhdr.priority = orderpriority.code(+)
  and orderhdr.loadno = loads.loadno(+)
  and orderhdr.loadno = loadstop.loadno(+)
  and orderhdr.stopno = loadstop.stopno(+)
  and orderhdr.consignee = cons_bill.consignee(+)
  and orderhdr.shipto = cons_ship.consignee(+)
  and orderhdr.carrier = carrier.carrier(+)
  and orderhdr.carrier = carrierservicecodes.carrier(+)
  and orderhdr.deliveryservice = carrierservicecodes.servicecode(+);

comment on table WEBORDERHDRVIEW is '$Id$';

exit;

