--
-- $Id$
--


CREATE OR REPLACE PACKAGE BODY         alps.zimportproc7weber

Is


procedure begin_shipnote945weber
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_summarize_lots_yn IN varchar2
,in_include_zero_qty_lines_yn IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_include_fromlpid_yn IN varchar2
,in_ltl_freight_passthru IN varchar2
,in_bol_tracking_yn IN varchar2
,in_round_freight_weight_up_yn IN varchar2
,in_invclass_yn IN varchar2
,in_carton_uom IN varchar2
,in_contents_by_po IN varchar2
,in_outlot IN varchar2
,in_cnt_detail_yn IN varchar2
,in_cnt_detail_ignore_ui3_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curCustomer is
  select c.custid,nvl(c.linenumbersyn,'N') as linenumbersyn, c.manufacturerucc,
         nvl(ca.mixed_order_pallet_dimensions,'N') as mixed_order_pallet_dimensions
    from customer c, customer_aux ca
   where c.custid = in_custid
     and c.custid = ca.custid(+);
cu curCustomer%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and loadno = in_loadno
   order by orderid,shipid;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         substr(zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),1,15) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            substr(zmp.shipplate_fromlpid(nvl(parentlpid,lpid)),1,15);
sp curShippingPlate%rowtype;



cursor curShippingPlateLot(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         lotnumber,
         max(fromlpid) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            lotnumber;
spl curShippingPlateLot%rowtype;

cursor curShippingPlateInvClass(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(parentlpid,lpid) as parentlpid,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         lotnumber,
                        inventoryclass,
         max(fromlpid) as fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by nvl(parentlpid,lpid),substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            lotnumber,inventoryclass;
spi curShippingPlateInvClass%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select od.ORDERID as orderid,
         od.SHIPID as shipid,
         od.ITEM as item,
         od.LOTNUMBER as lotnumber,
         nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty,
         nvl(ol.DTLPASSTHRUchar01,od.DTLPASSTHRUchar01) as dtlpassthruchar01,
         nvl(ol.DTLPASSTHRUchar02,od.DTLPASSTHRUchar02) as dtlpassthruchar02,
         nvl(ol.DTLPASSTHRUchar03,od.DTLPASSTHRUchar03) as dtlpassthruchar03,
         nvl(ol.DTLPASSTHRUchar04,od.DTLPASSTHRUchar04) as dtlpassthruchar04,
         nvl(ol.DTLPASSTHRUchar05,od.DTLPASSTHRUchar05) as dtlpassthruchar05,
         nvl(ol.DTLPASSTHRUchar06,od.DTLPASSTHRUchar06) as dtlpassthruchar06,
         nvl(ol.DTLPASSTHRUchar07,od.DTLPASSTHRUchar07) as dtlpassthruchar07,
         nvl(ol.DTLPASSTHRUchar08,od.DTLPASSTHRUchar08) as dtlpassthruchar08,
         nvl(ol.DTLPASSTHRUchar09,od.DTLPASSTHRUchar09) as dtlpassthruchar09,
         nvl(ol.DTLPASSTHRUchar10,od.DTLPASSTHRUchar10) as dtlpassthruchar10,
         nvl(ol.DTLPASSTHRUchar11,od.DTLPASSTHRUchar11) as dtlpassthruchar11,
         nvl(ol.DTLPASSTHRUchar12,od.DTLPASSTHRUchar12) as dtlpassthruchar12,
         nvl(ol.DTLPASSTHRUchar13,od.DTLPASSTHRUchar13) as dtlpassthruchar13,
         nvl(ol.DTLPASSTHRUchar14,od.DTLPASSTHRUchar14) as dtlpassthruchar14,
         nvl(ol.DTLPASSTHRUchar15,od.DTLPASSTHRUchar15) as dtlpassthruchar15,
         nvl(ol.DTLPASSTHRUchar16,od.DTLPASSTHRUchar16) as dtlpassthruchar16,
         nvl(ol.DTLPASSTHRUchar17,od.DTLPASSTHRUchar17) as dtlpassthruchar17,
         nvl(ol.DTLPASSTHRUchar18,od.DTLPASSTHRUchar18) as dtlpassthruchar18,
         nvl(ol.DTLPASSTHRUchar19,od.DTLPASSTHRUchar19) as dtlpassthruchar19,
         nvl(ol.DTLPASSTHRUchar20,od.DTLPASSTHRUchar20) as dtlpassthruchar20,
         nvl(ol.DTLPASSTHRUNUM01,od.dtlpassthrunum01) as dtlpassthrunum01,
         nvl(ol.DTLPASSTHRUNUM02,od.dtlpassthrunum02) as dtlpassthrunum02,
         nvl(ol.DTLPASSTHRUNUM03,od.dtlpassthrunum03) as dtlpassthrunum03,
         nvl(ol.DTLPASSTHRUNUM04,od.dtlpassthrunum04) as dtlpassthrunum04,
         nvl(ol.DTLPASSTHRUNUM05,od.dtlpassthrunum05) as dtlpassthrunum05,
         nvl(ol.DTLPASSTHRUNUM06,od.dtlpassthrunum06) as dtlpassthrunum06,
         nvl(ol.DTLPASSTHRUNUM07,od.dtlpassthrunum07) as dtlpassthrunum07,
         nvl(ol.DTLPASSTHRUNUM08,od.dtlpassthrunum08) as dtlpassthrunum08,
         nvl(ol.DTLPASSTHRUNUM09,od.dtlpassthrunum09) as dtlpassthrunum09,
         nvl(ol.DTLPASSTHRUNUM10,od.dtlpassthrunum10) as dtlpassthrunum10,
         nvl(ol.LASTUSER,od.lastuser) as lastuser,
         nvl(ol.LASTUPDATE,od.lastupdate) as lastupdate,
         nvl(ol.DTLPASSTHRUDATE01,od.dtlpassthrudate01) as dtlpassthrudate01,
         nvl(ol.DTLPASSTHRUDATE02,od.dtlpassthrudate02) as dtlpassthrudate02,
         nvl(ol.DTLPASSTHRUDATE03,od.dtlpassthrudate03) as dtlpassthrudate03,
         nvl(ol.DTLPASSTHRUDATE04,od.dtlpassthrudate04) as dtlpassthrudate04,
         nvl(ol.DTLPASSTHRUDOLL01,od.dtlpassthrudoll01) as dtlpassthrudoll01,
         nvl(ol.DTLPASSTHRUDOLL02,od.dtlpassthrudoll02) as dtlpassthrudoll02,
         nvl(ol.QTYAPPROVED,0) as qtyapproved,
                        OD.uomentered as uomentered
         --               nvl(ol.uomentered, OD.uomentered) as uomentered
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
--     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));
ol curOrderDtlLine%rowtype;

cursor curCarrier(in_carrier varchar2) is
  select *
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

cursor curCustItem(in_custid varchar2, in_item varchar2) is
  select descr
    from custitemview
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

cursor curLoads(in_loadno number) is
  select *
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

type lot_rcd is record (
  lotnumber    orderdtl.lotnumber%type,
  qtyapplied    orderdtl.qtyorder%type,
  qtyordered    orderdtl.qtyorder%type,
  qtydiff       orderdtl.qtyorder%type

);

type lot_tbl is table of lot_rcd
     index by binary_integer;

lots lot_tbl;
lotx integer;
lotfound boolean;
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strDebugYN char(1);
curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
strFromLpid varchar2(15);
InvClass varchar2(2);
dteTest date;
qtyRemain shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
qtyLineAccum shippingplate.quantity%type;
qtyShipped shippingplate.quantity%type;
strCaseUpc varchar2(255);
dteExpirationDate date;
weightshipped orderdtl.weightship%type;
weighthold orderdtl.weightship%type;
cubetemp orderdtl.cubeship%type;
weighttemp orderdtl.weightship%type;
cubehold orderdtl.cubeship%type;
holdvics varchar2(17);
labelType varchar(2);
CIUpc varchar2(20);

dtl945 ship_nt_945_dtl%rowtype;
strLotNumber shippingplate.lotnumber%type;
l_condition varchar2(255);
l_carton_uom varchar2(4);
qtyOrd integer;
ppCnt integer;

procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(200);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

/*
cntChar := 1;
while (cntChar * 120) < (Length(in_text)+120)
loop
   zms.log_msg('945', '945', null,
   substr(in_text,((cntChar-1)*120)+1,120), 'I', '945', strMsg);
  cntChar := cntChar + 1;
end loop;
*/
exception when others then
  null;
end;

procedure insert_945_lot(oh curOrderHdr%rowtype, od curOrderDtl%rowtype,
  ol curOrderDtlLine%rowtype, in_lotnumber varchar2, in_qty number,
  in_ord number, in_diff number) is
begin

debugmsg('begin insert_945_lot '  || od.orderid || '-' || od.shipid || ' ' ||
  od.item || ' ' || od.lotnumber);

strLotNumber := null;
if od.lotnumber is null then
  strLotNumber := '(none)';
else
  strLotNumber := od.lotnumber;
end if;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into ship_nt_945_lot_' || strSuffix ||
' values (:ORDERID,:SHIPID,:CUSTID,:ASSIGNEDID,' ||
':ITEM,:LOTNUMBER,:LINK_LOTNUMBER,' ||
':QTYSHIPPED,:QTYORDERED,:QTYDIFF)',
  dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':ORDERID', oh.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', oh.SHIPID);
dbms_sql.bind_variable(curFunc, ':CUSTID', oh.CUSTID);
dbms_sql.bind_variable(curFunc, ':ASSIGNEDID', ol.dtlpassthrunum10);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', in_lotnumber);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', strLotNumber);
dbms_sql.bind_variable(curFunc, ':QTYSHIPPED', in_qty);
dbms_sql.bind_variable(curFunc, ':QTYORDERED', in_ord);
dbms_sql.bind_variable(curFunc, ':QTYDIFF', in_diff);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end;

procedure insert_945_dtl(oh curOrderHdr%rowtype, od curOrderDtl%rowtype,
  ol curOrderDtlLine%rowtype, invcls varchar2) is
begin

debugmsg('begin insert_945_dtl '  || od.orderid || '-' || od.shipid || ' ' ||
  od.item || ' ' || od.lotnumber);

strLotNumber := null;
if od.lotnumber is null then
  strLotNumber := '(none)';
else
  strLotNumber := od.lotnumber;
end if;

if upper(nvl(in_include_fromlpid_yn,'N')) = 'Y' and
   upper(nvl(in_summarize_lots_yn,'Y')) = 'Y' then
  qtyShipped := qtyLineNumber;
else
  qtyShipped := ol.qty - qtyRemain;
end if;
debugmsg('get upc');
begin
  select upc
    into dtl945.Upc
    from custitemupcview
   where custid = cu.custid
     and item = od.item;
exception when others then
  dtl945.Upc := '';
end;
weightshipped := zci.item_weight(cu.custid,od.item,od.uom) * qtyShipped;
weighthold := zci.item_weight(cu.custid,od.item,od.uom);
cubehold := od.cubeship;
if od.qtyship > 0 then
   cubehold := od.cubeship / od.qtyship;
        end if;
debugmsg('wt/cube hold: ' || weighthold || '-' || cubehold || '<');

dtl945.shipticket := substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15);

if nvl(rtrim(in_invclass_yn),'N') = 'N' then
  InvClass := '  ';
else
  InvClass := invcls;
end if;

if ca.multiship = 'Y' then
  dtl945.trackingno := substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30);
else
  if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
    dtl945.trackingno :=
          nvl(oh.prono,nvl(ld.prono,nvl(oh.billoflading,nvl(ld.billoflading,to_char(oh.orderid) || ''-'' || to_char(oh.shipid)))));
  else
    dtl945.trackingno :=
      nvl(oh.prono,nvl(ld.prono,to_char(oh.orderid) || ''-'' || to_char(oh.shipid)));
  end if;
end if;

weighthold := zci.item_weight(cu.custid,od.item,od.uom);
if od.qtyship > 0 then
   cubehold := od.cubeship / od.qtyship;
end if;

dtl945.kgs := weightshipped / 2.2046;
dtl945.gms := weightshipped / .0022046;
dtl945.ozs := weightshipped * 16;
dtl945.smallpackagelbs := 0;
-- dtl945.smallpackagelbs := zim14.freight_weight(oh.orderid,oh.shipid,od.item,od.lotnumber,
--  nvl(rtrim(in_round_freight_weight_up_yn),'N'));
dtl945.deliveryservice := ' ';
-- substr(zim14.delivery_service(oh.orderid,oh.shipid,od.item,od.lotnumber),1,10);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, 'insert into ship_nt_945_dtl_' || strSuffix ||
' values (:ORDERID,:SHIPID,:CUSTID,:ASSIGNEDID,:SHIPTICKET,:TRACKINGNO,' ||
':SERVICECODE,:LBS,:KGS,:GMS,:OZS,:ITEM,:LOTNUMBER,:LINK_LOTNUMBER,' ||
':INVENTORYCLASS,' ||
':STATUSCODE,:REFERENCE,:LINENUMBER,:ORDERDATE,:PO,:QTYORDERED,:QTYSHIPPED,' ||
':QTYDIFF,:UOM,:PACKLISTSHIPDATE,:WEIGHT,:WEIGHTQUAIFIER,:WEIGHTUNIT,' ||
':DESCRIPTION,:UPC,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,' ||
':DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,' ||
':DTLPASSTHRUCHAR08,:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,' ||
':DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,' ||
':DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,' ||
':DTLPASSTHRUCHAR20,:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,' ||
':DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,' ||
':DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,' ||
':DTLPASSTHRUDATE02,:DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,' ||
':DTLPASSTHRUDOLL02, :FROMLPID, :SMALLPACKAGELBS, :DELIVERYSERVICE, ' ||
':ENTEREDUOM, :QTYSHIPPEDUOM)',
  dbms_sql.native);
dbms_sql.bind_variable(curFunc, ':ORDERID', oh.ORDERID);
dbms_sql.bind_variable(curFunc, ':SHIPID', oh.SHIPID);
dbms_sql.bind_variable(curFunc, ':CUSTID', oh.CUSTID);
dbms_sql.bind_variable(curFunc, ':ASSIGNEDID', ol.dtlpassthrunum10);
dbms_sql.bind_variable(curFunc, ':SHIPTICKET', dtl945.SHIPTICKET);
dbms_sql.bind_variable(curFunc, ':TRACKINGNO', dtl945.TRACKINGNO);
dbms_sql.bind_variable(curFunc, ':SERVICECODE', oh.deliveryservice);
dbms_sql.bind_variable(curFunc, ':LBS', weightshipped);
dbms_sql.bind_variable(curFunc, ':KGS', dtl945.kgs);
dbms_sql.bind_variable(curFunc, ':GMS', dtl945.gms);
dbms_sql.bind_variable(curFunc, ':OZS', dtl945.ozs);
dbms_sql.bind_variable(curFunc, ':ITEM', od.ITEM);
dbms_sql.bind_variable(curFunc, ':LOTNUMBER', od.lotnumber);
dbms_sql.bind_variable(curFunc, ':LINK_LOTNUMBER', strLotNumber);
dbms_sql.bind_variable(curFunc, ':INVENTORYCLASS', InvClass);
dbms_sql.bind_variable(curFunc, ':STATUSCODE', od.linestatus);
dbms_sql.bind_variable(curFunc, ':REFERENCE', oh.REFERENCE);
dbms_sql.bind_variable(curFunc, ':LINENUMBER', ol.LINENUMBER);
dbms_sql.bind_variable(curFunc, ':ORDERDATE', oh.ENTRYDATE);
dbms_sql.bind_variable(curFunc, ':PO', oh.PO);
dbms_sql.bind_variable(curFunc, ':QTYORDERED', ol.QTY);
dbms_sql.bind_variable(curFunc, ':QTYSHIPPED', qtySHIPPED);
dbms_sql.bind_variable(curFunc, ':QTYDIFF', ol.QTY - qtyShipped);
dbms_sql.bind_variable(curFunc, ':UOM', od.UOM);
dbms_sql.bind_variable(curFunc, ':PACKLISTSHIPDATE', oh.PACKLISTSHIPDATE);
dbms_sql.bind_variable(curFunc, ':WEIGHT', weightshipped);
dbms_sql.bind_variable(curFunc, ':WEIGHTQUAIFIER', 'G');
dbms_sql.bind_variable(curFunc, ':WEIGHTUNIT', 'L');
dbms_sql.bind_variable(curFunc, ':DESCRIPTION', ci.descr);
dbms_sql.bind_variable(curFunc, ':UPC', dtl945.upc);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
dbms_sql.bind_variable(curFunc, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
dbms_sql.bind_variable(curFunc, ':FROMLPID', strFromLpid);
dbms_sql.bind_variable(curFunc, ':SMALLPACKAGELBS', dtl945.smallpackagelbs);
dbms_sql.bind_variable(curFunc, ':DELIVERYSERVICE', dtl945.DELIVERYSERVICE);
dbms_sql.bind_variable(curFunc, ':ENTEREDUOM', ol.uomentered);
dbms_sql.bind_variable(curFunc, ':QTYSHIPPEDUOM',
    zcu.equiv_uom_qty(OH.custid,OD.item,OD.uom,qtyShipped,ol.uomentered));

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

end;


procedure verify_caselabels(oh curorderhdr%rowtype) is
labelType varchar2(2);
otherType varchar2(2);
olpid varchar2(15);
owave orderhdr.wave%type;
out_msg varchar2(2000);
l_cnt pls_integer;
begin
-- ignore order if labels were created via weber_prplbls
   select count(1) into l_cnt
      from caselabels
      where orderid = oh.orderid
        and shipid = oh.shipid
        and labeltype = 'PP';
   if l_cnt != 0 then
      return;
   end if;

/* determine which type of label (CS,PL) was created last and get rid of
   the other type if any exist */
   labelType := null;
   select nvl(max(c.labeltype),'CS') into labelType
      from caselabels c
      where c.orderid = oh.orderid
        and c.shipid = oh.shipid
        and c.created = (select max(cs.created)
                            from caselabels cs
                            where c.orderid = cs.orderid
                              and c.shipid = cs.shipid);

   if labelType = 'CS' or
      labelType = 'CQ' then
      otherType := 'PL';
   else
      otherType := 'CS';
   end if;
   debugmsg('Other type ' || otherType);

   delete from caselabels
      where orderid = oh.orderid
        and shipid = oh.shipid
        and labeltype = othertype;
   owave := zconsorder.cons_orderid(oh.orderid, oh.shipid);
   if owave != 0 then
      select min(lpid) into olpid
      from shippingplate
      where orderid = oh.orderid
        and shipid = oh.shipid;
   else
      select min(lpid) into olpid
         from shippingplate
         where orderid = oh.orderid
           and shipid = oh.shipid
           and status != 'U'
           and parentlpid is null;
   end if;
   debugmsg('lpid ' || olpid);
   if labelType = 'PL' then
      debugmsg('check pallet labels ' || out_msg);
      weber_pltlbls.ord_lbl(olpid,'X', 'C',out_msg);
      debugmsg('plt out ' || out_msg);
   else
      debugmsg('check case labels ' || out_msg);
      weber_caslbls.ord_lbl(olpid,'X', 'C',out_msg);
      debugmsg('cse out ' || out_msg);
   end if;


end;

procedure add_945_dtl_rows_by_lot(oh curorderhdr%rowtype) is
ndxlot integer;
dsplymsg varchar2(255);
begin
  debugmsg('begin add_945_dtl_rows_by_lot');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    spl := null;
    open curShippingPlateLot(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateLot into spl;
    debugmsg('get lines');
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      qtyLineAccum := 0;
      lots.delete;
      qtyLineNumber := 0;
      qtyRemain := ol.qty;
      if spl.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if spl.qty = 0 then
            debugmsg('get shippingplate');
            fetch curShippingPlateLot into spl;
            if curShippingPlateLot%notfound then
              spl := null;
              exit;
            end if;
          end if;
          if spl.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := spl.qty;
          end if;
          qtyLineAccum := qtyLineAccum + qtyLineNumber;
          debugmsg('get expiration date');
          dteExpirationDate := zimsip.lip_expirationdate(spl.fromlpid);
          debugmsg('find lot');
          lotfound := false;
          for lotx in 1..lots.count
          loop
            if nvl(lots(lotx).lotnumber,'(none)') = nvl(spl.lotnumber,'(none)') then
              lots(lotx).qtyapplied := lots(lotx).qtyapplied + qtyLineNumber;
              lotfound := true;
              exit;
            end if;
          end loop;
          if lotfound then
            dsplymsg := 'lot found ' || to_char(lotx, '99') || spl.lotnumber;
            debugmsg(spl.lotnumber);
          else
            lotx := lots.count + 1;
            dsplymsg := 'lot new ' || to_char(lotx, '99') || spl.lotnumber;
            if lotx = 1 then
               debugmsg(' lotx1');
            else
               debugmsg(' lotx not 1');
            end if;
            lots(lotx).lotnumber := spl.lotnumber;
            lots(lotx).qtyApplied := qtyLineNumber;
            debugmsg(spl.lotnumber || '-' || lots(lotx).lotnumber);
          end if;
          qtyRemain := qtyRemain - qtyLineNumber;
          spl.qty := spl.qty - qtyLineNumber;
        end loop; -- shippingplate
      end if;
      if (qtyLineAccum <> 0) or
         (qtyLineAccum = 0 and
          upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y') then
        insert_945_dtl(oh, od, ol, '  ');
        qtyOrd := od.qtyorder;
        for lotx in 1..lots.count
        loop
          if lotx = lots.count then
             lots(lotx).qtyordered := qtyOrd;
          else
             lots(lotx).qtyordered := lots(lotx).qtyapplied;
          end if;
          lots(lotx).qtydiff := lots(lotx).qtyordered - lots(lotx).qtyapplied;
          qtyOrd := qtyOrd - lots(lotx).qtyapplied;
          insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied,lots(lotx).qtyordered,lots(lotx).qtydiff);
        end loop;
      end if;
    end loop; -- orderdtlline
    close curShippingPlateLot;
  end loop; -- orderdtl
end;

procedure add_945_dtl_rows_by_invclass(oh curorderhdr%rowtype) is
sqlMsg varchar2(255);
begin
  debugmsg('begin add_945_dtl_rows_by_invclass');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    qtyRemain := od.qtyship;
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    spi := null;
    open curShippingPlateInvClass(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateInvClass into spi;
    debugmsg('get lines');
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      qtyLineAccum := 0;
      lots.delete;
      qtyLineNumber := 0;
--      qtyRemain := ol.qty;
/*
      -- If the Detail Line qty is zero, default it to the ship qty
         for the Order Detail.  WARNING!!! multiple zero quantity lines
         will cause a malfunction (maybe)...
*/
/*      if qtyRemain = 0 then
         qtyRemain := od.qtyship;
      end if;
*/
      if spi.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if spi.qty = 0 then
            debugmsg('get shippingplate');
            fetch curShippingPlateInvClass into spi;
            if curShippingPlateInvClass%notfound then
              spi := null;
              exit;
            end if;
          end if;
          if spi.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := spi.qty;
          end if;
          qtyLineAccum := qtyLineAccum + qtyLineNumber;
          debugmsg('get expiration date');
          dteExpirationDate := zimsip.lip_expirationdate(spi.fromlpid);
          debugmsg('find lot');
          lotfound := false;
          for lotx in 1..lots.count
          loop
            if nvl(lots(lotx).lotnumber,'(none)') = nvl(spi.lotnumber,'(none)') then
              lots(lotx).qtyapplied := lots(lotx).qtyapplied + qtyLineNumber;
              lotfound := true;
              exit;
            end if;
          end loop;
          if lotfound then
            debugmsg('lot found');
          else
            debugmsg('new lot' || to_char(lotx, '99') || '-' || spi.lotnumber);
            lotx := lots.count + 1;
            lots(lotx).lotnumber := spi.lotnumber;
            lots(lotx).qtyApplied := qtyLineNumber;
          end if;
          qtyRemain := qtyRemain - qtyLineNumber;
          spi.qty := spi.qty - qtyLineNumber;
        end loop; -- shippingplate
      end if;
      if (qtyLineAccum <> 0) or
         (qtyLineAccum = 0 and
          upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y') then
        insert_945_dtl(oh, od, ol, spi.inventoryclass);
        qtyOrd := od.qtyorder;
        for lotx in 1..lots.count
        loop
          if lotx = lots.count then
             lots(lotx).qtyordered := qtyOrd;
          else
             lots(lotx).qtyordered := lots(lotx).qtyapplied;
          end if;
          lots(lotx).qtydiff := lots(lotx).qtyordered - lots(lotx).qtyapplied;
          qtyOrd := qtyOrd - lots(lotx).qtyapplied;
          insert_945_lot(oh,od,ol,lots(lotx).lotnumber,lots(lotx).qtyapplied,lots(lotx).qtyordered,lots(lotx).qtydiff);
        end loop;
      end if;
    end loop; -- orderdtlline
    close curShippingPlateInvClass;
  end loop; -- orderdtl
end;

procedure add_945_dtl_rows_by_item(oh curorderhdr%rowtype) is
begin
  debugmsg('begin add_945_dtl_rows_by_item');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    debugmsg('order dtl loop');
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    sp := null;
    open curShippingPlate(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlate into sp;
    debugmsg('sp  is ' || sp.parentlpid || '|' || sp.fromlpid || ' ' || sp.qty);
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      qtyLineAccum := 0;
      debugmsg('order line loop');
      qtyRemain := ol.qty;
      qtyLineNumber := 0;
      if sp.parentlpid is not null then
        while (qtyRemain > 0)
        loop
          if sp.qty = 0 then
            debugmsg('get next shipping plate');
            fetch curShippingPlate into sp;
            if curShippingPlate%notfound then
              debugmsg('no more shipping plate');
              sp := null;
              exit;
            end if;
          end if;
          if sp.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := sp.qty;
          end if;
          qtyLineAccum := qtyLineAccum + qtyLineNumber;
          dteExpirationDate := null;
          qtyRemain := qtyRemain - qtyLineNumber;
          sp.qty := sp.qty - qtyLineNumber;
          if upper(nvl(in_include_fromlpid_yn,'N')) = 'Y' then
            strFromLpid := sp.fromlpid;
            insert_945_dtl(oh,od,ol,'  ');
            strFromLpid := '';
          end if;
        end loop; -- shippingplate
      end if;
      if (qtyLineAccum <> 0 and
          upper(nvl(in_include_fromlpid_yn,'N')) != 'Y') or
         (qtyLineAccum = 0 and
          upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'Y') then
          insert_945_dtl(oh, od, ol,'  ');
      end if;
    end loop; -- orderdtlline
    close curShippingPlate;
  end loop; -- orderdtl
  debugmsg('end add_945_dtl_rows_by_item');
end;

procedure add_945_man_rows(oh curorderhdr%rowtype) is
TYPE cur_type is REF CURSOR;
cr cur_type;

man945 ship_nt_945_man%rowtype;
qty number;

cmdsql varchar2(100);
cursor C_SP
IS
select *
  from shippingplate
 where orderid = oh.orderid
   and shipid = oh.shipid
   and item = man945.item
   and nvl(lotnumber,'(none)') = nvl(man945.lotnumber,'(none)')
   and serialnumber is not null;

SP shippingplate%rowtype;

begin
    debugmsg('begin add_945_man_rows ' || oh.orderid || '-' || oh.shipid);

    man945 := null;
    man945.orderid := oh.orderid;
    man945.shipid := oh.shipid;
    man945.custid := oh.custid;

    cmdsql := 'select item, lotnumber, assignedid, qtyshipped,'||
        ' dtlpassthruchar01 from ship_nt_945_dtl_'||strSuffix;

    debugmsg(cmdsql);

    SP := null;

    open cr for cmdsql;

    loop
        fetch cr into man945.item, man945.lotnumber, man945.assignedid, qty,
            man945.dtlpassthruchar01;
        exit when cr%notfound;

        debugmsg('MAN:'||man945.item||'/'||man945.lotnumber||' Id:'||
            man945.assignedid||' Qty:'||qty);

        man945.link_lotnumber := nvl(man945.lotnumber,'(none)');

        if nvl(SP.item,'aa') != man945.item
        or nvl(SP.lotnumber,'(none)') != nvl(man945.lotnumber,'(none)')
        then
            if C_SP%isopen then
                close C_SP;
            end if;
            open C_SP;
        end if;
        loop
          fetch C_SP into SP;
          exit when C_SP%notfound;
          if SP.item is not null then
            debugmsg('Have SN:'||SP.serialnumber);

            man945.serialnumber := SP.serialnumber;

            execute immediate 'insert into ship_nt_945_man_'||strSuffix||
            ' values(:orderid,:shipid,:custid,:assignedid,:item,:lotnumber,'||
            ' :link_lotnumber,:serialnumber,:dtlpassthruchar01) ' using
            man945.orderid, man945.shipid, man945.custid,man945.assignedid,
            man945.item, man945.lotnumber, man945.link_lotnumber,
            man945.serialnumber, man945.dtlpassthruchar01;

            qty := qty - SP.quantity;

          end if;
          exit when qty <= 0;

        end loop;


    end loop;

    close cr;
    if C_SP%isopen then
        close C_SP;
    end if;

end;

procedure add_945_dtl_rows(oh curorderhdr%rowtype) is
begin

debugmsg('begin add_945_dtl_rows ' || oh.orderid || '-' || oh.shipid);

if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  if oh.orderstatus = 'X' then
    return;
  end if;
end if;

ca := null;
open curCarrier(oh.carrier);
fetch curCarrier into ca;
close curCarrier;

ld := null;
open curLoads(oh.loadno);
fetch curLoads into ld;
close curLoads;

  if nvl(in_invclass_yn, 'N') = 'Y' then
     debugmsg('exec add_by_cls');
     add_945_dtl_rows_by_invclass(oh);
  else
     if nvl(in_summarize_lots_yn,'N') = 'Y'  then
        debugmsg('exec add_by_item');
        add_945_dtl_rows_by_item(oh);
     else
        debugmsg('exec add_by_lot');
        add_945_dtl_rows_by_lot(oh);
     end if;
  end if;

        add_945_man_rows(oh);

exception when others then
  debugmsg(sqlerrm);
end;

procedure extract_by_line_numbers is
begin

debugmsg('begin 945 extract by line numbers');
debugmsg('creating 945 dtl');
cmdSql := 'create table SHIP_NT_945_DTL_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4),SHIPTICKET VARCHAR2(15),TRACKINGNO VARCHAR2(81),' ||
' SERVICECODE VARCHAR2(4),LBS NUMBER(17,8),KGS NUMBER,GMS NUMBER,' ||
' OZS NUMBER,item varchar2(50) not null,LOTNUMBER VARCHAR2(30),' ||
' LINK_LOTNUMBER VARCHAR2(30),INVENTORYCLASS VARCHAR2(4),' ||
' STATUSCODE VARCHAR2(2),REFERENCE VARCHAR2(20),LINENUMBER VARCHAR2(255),' ||
' ORDERDATE DATE,PO VARCHAR2(20),QTYORDERED NUMBER(7),QTYSHIPPED NUMBER(7),' ||
' QTYDIFF NUMBER,UOM VARCHAR2(4),PACKLISTSHIPDATE DATE,WEIGHT NUMBER(17,8),' ||
' WEIGHTQUAIFIER CHAR(1),WEIGHTUNIT CHAR(1),DESCRIPTION VARCHAR2(255),' ||
' UPC VARCHAR2(20),DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255),' ||
' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),DTLPASSTHRUNUM03 NUMBER(16,4),' ||
' DTLPASSTHRUNUM04 NUMBER(16,4),DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),' ||
' DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),DTLPASSTHRUNUM09 NUMBER(16,4),' ||
' DTLPASSTHRUNUM10 NUMBER(16,4),DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,' ||
' DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,DTLPASSTHRUDOLL01 NUMBER(10,2),' ||
' DTLPASSTHRUDOLL02 NUMBER(10,2), FROMLPID varchar2(15), smallpackagelbs number,'||
' deliveryservice varchar2(10), entereduom varchar2(4), qtyshippedEUOM number )';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 lot');
cmdSql := 'create table SHIP_NT_945_lot_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4),item varchar2(50) not null,LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),' ||
' QTYSHIPPED NUMBER(7), QTYORDERED NUMBER(7), QTYDIFF NUMBER(7) )';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 lxd');
cmdSql := 'create table SHIP_NT_945_LXD_' || strSuffix ||
        ' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' ASSIGNEDID NUMBER(16,4) )';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 man');
cmdSql := 'create table SHIP_NT_945_MAN_' || strSuffix ||
' (ORDERID NUMBER(9),SHIPID NUMBER(2),CUSTID VARCHAR2(10),'||
' ASSIGNEDID NUMBER(16,4),item varchar2(50),' ||
' LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),'||
' SERIALNUMBER VARCHAR2(30), DTLPASSTHRUCHAR01 VARCHAR2(255) ' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('creating 945 s18');
cmdSql := 'create table SHIP_NT_945_S18_' || strSuffix ||
' (ORDERID NUMBER,SHIPID NUMBER,CUSTID VARCHAR2(10),item varchar2(50),' ||
' LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),SSCC18 VARCHAR2(20)' ||
')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
if in_orderid != 0 then
  debugmsg('by order ' || in_orderid || '-' || in_shipid);
  for oh in curOrderHdr
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_dtl_rows(oh);
  end loop;
elsif in_loadno != 0 then
  debugmsg('by loadno ' || in_loadno);
  for oh in curOrderHdrByLoad
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_dtl_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
  debugmsg('by date ' || in_begdatestr || '-' || in_enddatestr);
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;
  for oh in curOrderHdrByShipDate
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_dtl_rows(oh);
  end loop;
end if;


end;


----------------------------------------------------------------------
-- Extract by ID and contents
----------------------------------------------------------------------


procedure add_945_cnt_rows(oh curorderhdr%rowtype) is

TYPE cur_type is REF CURSOR;
cr cur_type;


cursor C_SP_old(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and status = 'SH'
     and parentlpid is null;

cursor C_SP(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where status = 'SH'
     and parentlpid is null
     and lpid in
    (select nvl(parentlpid,lpid)
       from shippingplate
       start with orderid = in_orderid and shipid = in_shipid
                  and type in ('F','P')
       connect by prior parentlpid = lpid);

cursor C_SP_CARTON(in_orderid number, in_shipid number, in_item varchar2,
                   in_lotnumber varchar2, in_lpid varchar2 )
is
  select custid, item, lotnumber, orderitem, orderlot, unitofmeasure, sum(quantity) quantity
    from ShippingPlate
   where status = 'SH'
     and type in ('F','P')
     and lpid in (select lpid
                  from shippingplate
                  where orderid = in_orderid
                    and shipid = in_shipid
                    and item = in_item
                    and nvl(lotnumber,'(none)') = nvl(in_lotnumber, '(none)')
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid)
  group by custid, item, lotnumber, orderitem, orderlot, unitofmeasure;


cursor C_CONS_SP(in_orderid number,in_shipid number)
is
  select *
    from ShippingPlate
   where status = 'SH'
     and orderid = in_orderid
     and shipid = in_shipid
     and type in ('F','P');


cursor C_LBL(in_orderid number, in_shipid number, in_labeltype varchar2,
    in_lpid varchar2, in_item varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and case when labeltype in('PP','CS','CQ') then 'CS' else 'PL' end=decode(in_labeltype,'P','PL','CS')
     and lpid = in_lpid
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'));

cursor C_LBL_MIXED(in_lpid varchar2)
is
  select *
    from caselabels
   where lpid = in_lpid and
         labeltype = 'PL';
cursor C_LBLC(in_orderid number, in_shipid number, in_labeltype varchar2,
    in_lpid varchar2, in_item varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and case when labeltype in('PP','CS','CQ') then 'CS' else 'PL' end=decode(in_labeltype,'P','PL','CS')
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'))
     and lpid in
    (select lpid
       from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
       start with lpid = in_lpid
      connect by prior lpid = parentlpid);

cursor C_LBLCS(in_orderid number, in_shipid number,
    in_lpid varchar2, in_item varchar2, in_lot varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and labeltype in ('CS','PP','CQ')
     and nvl(item,'(none)') = nvl(in_item,nvl(item,'(none)'))
     and nvl(lotnumber,'(none)') = nvl(in_lot,nvl(lotnumber,'(none)'))
     and lpid in
    (select lpid
       from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
       start with lpid = in_lpid
      connect by prior lpid = parentlpid);

cursor C_LBLCS_CONS(in_orderid number, in_shipid number,
    in_lpid varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and labeltype in ('CS','PP','CQ')
     and lpid = in_lpid;

do_cases boolean;
no_item_carton boolean;


LBL caselabels%rowtype;
LBLCS caselabels%rowtype;

SP shippingplate%rowtype;

cursor C_ODLC(in_orderid number, in_shipid number, in_item varchar2,
    in_lotnumber varchar2, in_assignedid number)
IS
select
    D.custid,
    D.item,
    D.lotnumber,
    D.uom,
    D.itementered,
    D.consigneesku,
    nvl(L.dtlpassthruchar01,D.dtlpassthruchar01) dtlpassthruchar01,
    nvl(L.dtlpassthruchar02,D.dtlpassthruchar02) dtlpassthruchar02,
    nvl(L.dtlpassthruchar03,D.dtlpassthruchar03) dtlpassthruchar03,
    nvl(L.dtlpassthruchar04,D.dtlpassthruchar04) dtlpassthruchar04,
    nvl(L.dtlpassthruchar05,D.dtlpassthruchar05) dtlpassthruchar05,
    nvl(L.dtlpassthruchar06,D.dtlpassthruchar06) dtlpassthruchar06,
    nvl(L.dtlpassthruchar07,D.dtlpassthruchar07) dtlpassthruchar07,
    nvl(L.dtlpassthruchar08,D.dtlpassthruchar08) dtlpassthruchar08,
    nvl(L.dtlpassthruchar09,D.dtlpassthruchar09) dtlpassthruchar09,
    nvl(L.dtlpassthruchar10,D.dtlpassthruchar10) dtlpassthruchar10,
    nvl(L.dtlpassthruchar11,D.dtlpassthruchar11) dtlpassthruchar11,
    nvl(L.dtlpassthruchar12,D.dtlpassthruchar12) dtlpassthruchar12,
    nvl(L.dtlpassthruchar13,D.dtlpassthruchar13) dtlpassthruchar13,
    nvl(L.dtlpassthruchar14,D.dtlpassthruchar14) dtlpassthruchar14,
    nvl(L.dtlpassthruchar15,D.dtlpassthruchar15) dtlpassthruchar15,
    nvl(L.dtlpassthruchar16,D.dtlpassthruchar16) dtlpassthruchar16,
    nvl(L.dtlpassthruchar17,D.dtlpassthruchar17) dtlpassthruchar17,
    nvl(L.dtlpassthruchar18,D.dtlpassthruchar18) dtlpassthruchar18,
    nvl(L.dtlpassthruchar19,D.dtlpassthruchar19) dtlpassthruchar19,
    nvl(L.dtlpassthruchar20,D.dtlpassthruchar20) dtlpassthruchar20,
    nvl(L.dtlpassthrunum01,D.dtlpassthrunum01) dtlpassthrunum01,
    nvl(L.dtlpassthrunum02,D.dtlpassthrunum02) dtlpassthrunum02,
    nvl(L.dtlpassthrunum03,D.dtlpassthrunum03) dtlpassthrunum03,
    nvl(L.dtlpassthrunum04,D.dtlpassthrunum04) dtlpassthrunum04,
    nvl(L.dtlpassthrunum05,D.dtlpassthrunum05) dtlpassthrunum05,
    nvl(L.dtlpassthrunum06,D.dtlpassthrunum06) dtlpassthrunum06,
    nvl(L.dtlpassthrunum07,D.dtlpassthrunum07) dtlpassthrunum07,
    nvl(L.dtlpassthrunum08,D.dtlpassthrunum08) dtlpassthrunum08,
    nvl(L.dtlpassthrunum09,D.dtlpassthrunum09) dtlpassthrunum09,
    nvl(L.dtlpassthrunum10,D.dtlpassthrunum10) dtlpassthrunum10,
    nvl(L.dtlpassthrudate01,D.dtlpassthrudate01) dtlpassthrudate01,
    nvl(L.dtlpassthrudate02,D.dtlpassthrudate02) dtlpassthrudate02,
    nvl(L.dtlpassthrudate03,D.dtlpassthrudate03) dtlpassthrudate03,
    nvl(L.dtlpassthrudate04,D.dtlpassthrudate04) dtlpassthrudate04,
    nvl(L.dtlpassthrudoll01,D.dtlpassthrudoll01) dtlpassthrudoll01,
    nvl(L.dtlpassthrudoll02,D.dtlpassthrudoll02) dtlpassthrudoll02,
    D.childorderid,D.childshipid
  from orderdtl D, orderdtlline L
 where D.orderid = in_orderid
   and D.shipid = in_shipid
   and D.item = in_item
   and nvl(D.lotnumber, '(none)') = nvl(in_lotnumber,'(none)')
   and D.orderid = L.orderid(+)
   and D.shipid = L.shipid(+)
   and D.item = L.item(+)
   and nvl(D.lotnumber,'(none)') = nvl(L.lotnumber(+),'(none)')
   and nvl(in_assignedid,-1) = nvl(L.dtlpassthrunum10(+),-1);

ODLC C_ODLC%rowtype;

cursor C_OD(in_orderid number, in_shipid number, in_item varchar2,
    in_lotnumber varchar2)
IS
select *
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');

OD orderdtl%rowtype;

CNT ship_nt_945_cnt%rowtype;
CNT2 ship_nt_945_cnt%rowtype;
orderedqty number;
ctn_qty number;

owave orderhdr.wave%type;

type odl_rcd is record (
  item            orderdtlline.item%type,
  lotnumber       orderdtlline.lotnumber%type,
  linenumber      orderdtlline.linenumber%type,
  uom             orderdtl.uom%type,
  qty             orderdtl.qtyorder%type,
  totalqtyordered orderdtl.qtyorder%type,
  qty_ship        orderdtl.qtyorder%type
);

type odl_tbl is table of odl_rcd
     index by binary_integer;

odl odl_tbl;
odlx integer;
odlfound boolean;



cursor C_ODL(in_orderid number, in_shipid number)
IS
select
      od.ITEM as item,
      od.LOTNUMBER as lotnumber,
      nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
      nvl(OL.qty,nvl(OD.qtyorder,0)) as qty,
      nvl(OD.qtyorder,0) as totalqtyordered,
      I.baseuom
 from custitemview I, orderdtlline ol, orderdtl od
where od.orderid = in_orderid
  and od.shipid = in_shipid
  and OD.orderid = OL.orderid(+)
  and OD.shipid = OL.shipid(+)
  and OD.item = OL.item(+)
  and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
  and I.custid = od.custid
  and I.item = od.item
order by 1,2,3;


procedure write_dtl_contents(ODLC C_ODLC%rowtype)
is
   cntDtl pls_integer;
   cntChild pls_integer;
   maxUI3 shippingplate.useritem3%type;
   maxLIP shippingplate.lpid%type;
   maxChildLip shippingplate.lpid%type;
   ui3Ins integer;
   ui3Qty integer;
   cmdSql2 varchar2(2000);
   LP shippingplate%rowtype;
   TYPE cur_type is REF CURSOR;
   cr cur_type;
   sumQty integer;
   lipQty integer;
begin

debugmsg('CNT writing detial contents for LP:'||CNT.lpid);

cmdSql := 'select count(1) ' ||
           'from SHIP_NT_945_CNT_' || strSuffix ||
           ' where lpid = ''' || CNT.lpid || '''' ||
           '   and item = ''' || CNT.item || '''';
execute immediate cmdSql into cntDTL;
debugmsg('cntDTL ' || cntDTL || ' ' || CNT.item || ' ' || CNT.assignedid);
if cntDTL > 0 then
   cmdSql := 'select max(useritem3) ' ||
                  'from SHIP_NT_945_CNT_' || strSuffix ||
                  ' where lpid = ''' || CNT.lpid || '''' ||
                  '   and item = ''' ||CNT.item ||'''';
   execute immediate cmdsql into maxUI3;
   maxChildLip := null;
   cmdSql := 'select count(1) ' ||
              'from SHIP_NT_945_CNT_' || strSuffix ||
              ' where lpid = ''' || CNT.lpid || '''' ||
              '   and item = ''' || CNT.item || '''' ||
              '   and useritem3 = ''' || maxUI3 || '''';
   execute immediate cmdsql into cntChild;
   if cntChild > 0  then
      cmdSql := 'select max(childlpid) ' ||
                     'from SHIP_NT_945_CNT_' || strSuffix ||
                     ' where lpid = ''' || CNT.lpid || '''' ||
                     '   and item = ''' ||CNT.item ||'''';
      execute immediate cmdsql into maxChildLip;
   end if;
else
   maxUI3 := null;
   maxChildLip := null;
end if;

debugmsg('max UI3 ' || nvl(maxUI3, 'XXXXX'));
ui3Ins := 0;
for chsp in (select * from shippingplate
              where parentlpid = CNT.LPID
                and type in ('F','P')
                and item = CNT.item
                and useritem3 is not null
                and (useritem3 > nvl(maxUI3, ' ' ) or
                     (useritem3 = nvl(maxUI3, '(none)') and lpid > nvl(maxChildLip,'~~~~~~~~~~~')))
              order by useritem3)  loop
   if ui3Ins < CNT.qty then
      if ui3INS +  chsp.quantity > CNT.qty then
         ui3Qty := CNT.qty - ui3INS;
      else
         ui3Qty := chsp.quantity;
      end if;
      execute immediate 'insert into SHIP_NT_945_CNT_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
      ' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
      ' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
      ' :ASSIGNEDID, :ITEM,:LOTNUMEBR,:LINK_LOTNUMBER,'||
      ' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
      ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
      ' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
      ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
      ' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
      ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
      ' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
      ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
      ' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
      ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
      ' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
      ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
      ' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
      ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
      ' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
      ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
      ' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
      ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
      ' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
      ' :PO, :REFERENCE, :SHIPMENTSTATUSCODE,' ||
      ' :QTYORDERED, :QTYDIFFERENCE, ' ||
      ' :DESCRIPTION, :WEIGHT, :VOLUME, :CONSIGNEESKU, :VICS_BOL, :TOTALQTYORDERED, :CHILDLPID, '||
      ' :LENGTH, :WIDTH, :HEIGHT, :PALLET_WEIGHT )'
      using
          CNT.orderid,
          CNT.shipid,
          CNT.custid,
          CNT.lpid,
          CNT.fromlpid,
          CNT.plt_sscc18,
          CNT.ctn_sscc18,
          CNT.trackingno,
          CNT.link_plt_sscc18,
          CNT.link_ctn_sscc18,
          CNT.link_trackingno,
          CNT.assignedid,
          CNT.item,CNT.lotnumber,
          CNT.link_lotnumber,
          chsp.useritem1,
          chsp.useritem2,
          chsp.useritem3,
          ui3Qty,
          CNT.uom,
          CNT.cartons,
          ODLC.dtlpassthruchar01,
          ODLC.dtlpassthruchar02,
          ODLC.dtlpassthruchar03,
          ODLC.dtlpassthruchar04,
          ODLC.dtlpassthruchar05,
          ODLC.dtlpassthruchar06,
          ODLC.dtlpassthruchar07,
          ODLC.dtlpassthruchar08,
          nvl(ODLC.dtlpassthruchar09,CIUpc),
          ODLC.dtlpassthruchar10,
          ODLC.dtlpassthruchar11,
          ODLC.dtlpassthruchar12,
          ODLC.dtlpassthruchar13,
          ODLC.dtlpassthruchar14,
          ODLC.dtlpassthruchar15,
          ODLC.dtlpassthruchar16,
          ODLC.dtlpassthruchar17,
          ODLC.dtlpassthruchar18,
          ODLC.dtlpassthruchar19,
          ODLC.dtlpassthruchar20,
          ODLC.dtlpassthrunum01,
          ODLC.dtlpassthrunum02,
          ODLC.dtlpassthrunum03,
          ODLC.dtlpassthrunum04,
          ODLC.dtlpassthrunum05,
          ODLC.dtlpassthrunum06,
          ODLC.dtlpassthrunum07,
          ODLC.dtlpassthrunum08,
          ODLC.dtlpassthrunum09,
          ODLC.dtlpassthrunum10,
          ODLC.dtlpassthrudate01,
          ODLC.dtlpassthrudate02,
          ODLC.dtlpassthrudate03,
          ODLC.dtlpassthrudate04,
          ODLC.dtlpassthrudoll01,
          ODLC.dtlpassthrudoll02,
          CNT.po,
          CNT.reference,
          CNT.shipmentstatuscode,
          ui3Qty,
          ui3Qty - ui3Qty,
          ODLC.dtlpassthruchar10,
          CNT.weight,
          CNT.volume,
          ODLC.consigneesku,
          CNT.vicssubbol,
          ui3Qty,
          chsp.lpid,
          CNT.length,
          CNT.width,
          CNT.height,
          CNT.pallet_weight;
      ui3Ins := ui3INS + ui3Qty;
   end if;
end loop;
if ui3Ins < CNT.qty then
   debugmsg( '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~null user item 3');
   cmdSql := 'select count(1) ' ||
              'from SHIP_NT_945_CNT_' || strSuffix ||
              ' where lpid = ''' || CNT.lpid || '''' ||
              '   and item = ''' || CNT.item || '''' ||
              '   and useritem3 = ''999999999999999999''';
   debugmsg(cmdsql);
   execute immediate cmdSql into cntDTL;
   debugmsg('cntDTL ' || cntDTL || ' ' || CNT.item || ' ' || CNT.assignedid);
   cmdSql2 := 'select * from shippingplate '||
              ' where parentlpid = ''' || CNT.LPID || ''''||
              '   and type in (''F'',''P'') '||
              '   and item = '''|| CNT.item || ''''||
              '   and useritem3 is null ';
   if cntDTL > 0 then
      cmdSql := 'select max(childlpid) ' ||
                 'from SHIP_NT_945_CNT_' || strSuffix ||
                 ' where lpid = ''' || CNT.lpid || '''' ||
                 '   and item = ''' || CNT.item || '''' ||
                 '   and useritem3 = ''999999999999999999''';
      debugmsg(cmdsql);
      execute immediate cmdsql into maxLIP;
      cmdSql := 'select sum(qty) ' ||
                 'from SHIP_NT_945_CNT_' || strSuffix ||
                 ' where lpid = ''' || CNT.lpid || '''' ||
                 '   and item = ''' || CNT.item || '''' ||
                 '   and childlpid = ''' || maxLIP || '''';
      execute immediate cmdsql into sumQty;
      select quantity into lipQty
         from shippingplate
         where lpid = maxLIP;
      if sumQty < lipQty then
         cmdSql2 := cmdSql2 || ' and lpid >= ''' || maxLIP || '''';
      else
         cmdSql2 := cmdSql2 || ' and lpid > ''' || maxLIP || '''';

      end if;

   else
      maxUI3 := null;
   end if;
   debugmsg(cmdsql2);
   open cr for cmdsql2;
   loop
       fetch cr into LP;
       exit when cr%notfound;

       if ui3INS +  LP.quantity > CNT.qty then
          ui3Qty := CNT.qty - ui3INS;
       else
          ui3Qty := LP.quantity;
       end if;
       if ui3Ins < CNT.qty then

       execute immediate 'insert into SHIP_NT_945_CNT_' || strSuffix ||
       ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
       ' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
       ' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
       ' :ASSIGNEDID, :ITEM,:LOTNUMEBR,:LINK_LOTNUMBER,'||
       ' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
       ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
       ' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
       ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
       ' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
       ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
       ' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
       ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
       ' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
       ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
       ' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
       ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
       ' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
       ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
       ' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
       ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
       ' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
       ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
       ' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
       ' :PO, :REFERENCE, :SHIPMENTSTATUSCODE,' ||
       ' :QTYORDERED, :QTYDIFFERENCE, ' ||
       ' :DESCRIPTION, :WEIGHT, :VOLUME, :CONSIGNEESKU, :VICS_BOL, :TOTALQTYORDERED, :CHILDLPID, '||
       ' :LENGTH, :WIDTH, :HEIGHT, :PALLET_WEIGHT )'
       using
           CNT.orderid,
           CNT.shipid,
           CNT.custid,
           CNT.lpid,
           CNT.fromlpid,
           CNT.plt_sscc18,
           CNT.ctn_sscc18,
           CNT.trackingno,
           CNT.link_plt_sscc18,
           CNT.link_ctn_sscc18,
           CNT.link_trackingno,
           CNT.assignedid,
           CNT.item,CNT.lotnumber,
           CNT.link_lotnumber,
           LP.useritem1,
           LP.useritem2,
           '999999999999999999',
           ui3Qty,
           CNT.uom,
           CNT.cartons,
           ODLC.dtlpassthruchar01,
           ODLC.dtlpassthruchar02,
           ODLC.dtlpassthruchar03,
           ODLC.dtlpassthruchar04,
           ODLC.dtlpassthruchar05,
           ODLC.dtlpassthruchar06,
           ODLC.dtlpassthruchar07,
           ODLC.dtlpassthruchar08,
           nvl(ODLC.dtlpassthruchar09,CIUpc),
           ODLC.dtlpassthruchar10,
           ODLC.dtlpassthruchar11,
           ODLC.dtlpassthruchar12,
           ODLC.dtlpassthruchar13,
           ODLC.dtlpassthruchar14,
           ODLC.dtlpassthruchar15,
           ODLC.dtlpassthruchar16,
           ODLC.dtlpassthruchar17,
           ODLC.dtlpassthruchar18,
           ODLC.dtlpassthruchar19,
           ODLC.dtlpassthruchar20,
           ODLC.dtlpassthrunum01,
           ODLC.dtlpassthrunum02,
           ODLC.dtlpassthrunum03,
           ODLC.dtlpassthrunum04,
           ODLC.dtlpassthrunum05,
           ODLC.dtlpassthrunum06,
           ODLC.dtlpassthrunum07,
           ODLC.dtlpassthrunum08,
           ODLC.dtlpassthrunum09,
           ODLC.dtlpassthrunum10,
           ODLC.dtlpassthrudate01,
           ODLC.dtlpassthrudate02,
           ODLC.dtlpassthrudate03,
           ODLC.dtlpassthrudate04,
           ODLC.dtlpassthrudoll01,
           ODLC.dtlpassthrudoll02,
           CNT.po,
           CNT.reference,
           CNT.shipmentstatuscode,
           ui3Qty,
           ui3Qty - ui3Qty,
           ODLC.dtlpassthruchar10,
           CNT.weight,
           CNT.volume,
           ODLC.consigneesku,
           CNT.vicssubbol,
           ui3Qty,
           LP.lpid,
           CNT.length,
           CNT.width,
           CNT.height,
           CNT.pallet_weight;
       end if;
       ui3Ins := ui3INS + ui3Qty;
   end loop;
   close cr;


end if;
commit;

end;

procedure write_dtl_contents_ui1(ODLC C_ODLC%rowtype)
is
   cntDtl pls_integer;
   cntChild pls_integer;
   maxUI1 shippingplate.useritem1%type;
   maxLIP shippingplate.lpid%type;
   maxChildLip shippingplate.lpid%type;
   ui1Ins integer;
   ui1qty integer;
   cmdSql2 varchar2(2000);
   LP shippingplate%rowtype;
   TYPE cur_type is REF CURSOR;
   cr cur_type;
   sumQty integer;
   lipQty integer;
begin

debugmsg('CNT writing detial contents for LP:'||CNT.lpid);

cmdSql := 'select count(1) ' ||
           'from SHIP_NT_945_CNT_' || strSuffix ||
           ' where lpid = ''' || CNT.lpid || '''' ||
           '   and item = ''' || CNT.item || '''';
execute immediate cmdSql into cntDTL;
debugmsg('cntDTL ' || cntDTL || ' ' || CNT.item || ' ' || CNT.assignedid);
if cntDTL > 0 then
   cmdSql := 'select max(useritem1) ' ||
                  'from SHIP_NT_945_CNT_' || strSuffix ||
                  ' where lpid = ''' || CNT.lpid || '''' ||
                  '   and item = ''' ||CNT.item ||'''';
   execute immediate cmdsql into maxUI1;
   maxChildLip := null;
   cmdSql := 'select count(1) ' ||
              'from SHIP_NT_945_CNT_' || strSuffix ||
              ' where lpid = ''' || CNT.lpid || '''' ||
              '   and item = ''' || CNT.item || '''' ||
              '   and useritem1 = ''' || maxUI1 || '''';
   execute immediate cmdsql into cntChild;
   if cntChild > 0  then
      cmdSql := 'select max(childlpid) ' ||
                     'from SHIP_NT_945_CNT_' || strSuffix ||
                     ' where lpid = ''' || CNT.lpid || '''' ||
                     '   and item = ''' ||CNT.item ||'''';
      execute immediate cmdsql into maxChildLip;
   end if;
else
   maxUI1 := null;
   maxChildLip := null;
end if;

debugmsg('max UI1 ' || nvl(maxUI1, 'XXXXX'));
ui1Ins := 0;
for chsp in (select * from shippingplate
              where type in ('F','P')
                and item = CNT.item
                and useritem1 is not null
                and (useritem1 > nvl(maxUI1, ' ' ) or
                     (useritem1 = nvl(maxUI1, '(none)') and lpid > nvl(maxChildLip,'~~~~~~~~~~~')))
                and lpid in
                     (select lpid
                        from shippingplate
                       where orderid = CNT.orderid
                         and shipid = CNT.shipid
                        start with lpid = CNT.lpid
                       connect by prior lpid = parentlpid)
              order by useritem1)  loop
   if ui1Ins < CNT.qty then
      if ui1INS +  chsp.quantity > CNT.qty then
         ui1Qty := CNT.qty - ui1INS;
      else
         ui1Qty := chsp.quantity;
      end if;
      execute immediate 'insert into SHIP_NT_945_CNT_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
      ' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
      ' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
      ' :ASSIGNEDID, :ITEM,:LOTNUMEBR,:LINK_LOTNUMBER,'||
      ' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
      ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
      ' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
      ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
      ' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
      ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
      ' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
      ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
      ' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
      ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
      ' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
      ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
      ' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
      ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
      ' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
      ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
      ' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
      ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
      ' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
      ' :PO, :REFERENCE, :SHIPMENTSTATUSCODE,' ||
      ' :QTYORDERED, :QTYDIFFERENCE, ' ||
      ' :DESCRIPTION, :WEIGHT, :VOLUME, :CONSIGNEESKU, :VICS_BOL, :TOTALQTYORDERED, :CHILDLPID, '||
      ' :LENGTH, :WIDTH, :HEIGHT, :PALLET_WEIGHT )'
      using
          CNT.orderid,
          CNT.shipid,
          CNT.custid,
          CNT.lpid,
          CNT.fromlpid,
          CNT.plt_sscc18,
          CNT.ctn_sscc18,
          CNT.trackingno,
          CNT.link_plt_sscc18,
          CNT.link_ctn_sscc18,
          CNT.link_trackingno,
          CNT.assignedid,
          CNT.item,CNT.lotnumber,
          CNT.link_lotnumber,
          chsp.useritem1,
          chsp.useritem2,
          chsp.useritem3,
          ui1Qty,
          CNT.uom,
          CNT.cartons,
          ODLC.dtlpassthruchar01,
          ODLC.dtlpassthruchar02,
          ODLC.dtlpassthruchar03,
          ODLC.dtlpassthruchar04,
          ODLC.dtlpassthruchar05,
          ODLC.dtlpassthruchar06,
          ODLC.dtlpassthruchar07,
          ODLC.dtlpassthruchar08,
          nvl(ODLC.dtlpassthruchar09,CIUpc),
          ODLC.dtlpassthruchar10,
          ODLC.dtlpassthruchar11,
          ODLC.dtlpassthruchar12,
          ODLC.dtlpassthruchar13,
          ODLC.dtlpassthruchar14,
          ODLC.dtlpassthruchar15,
          ODLC.dtlpassthruchar16,
          ODLC.dtlpassthruchar17,
          ODLC.dtlpassthruchar18,
          ODLC.dtlpassthruchar19,
          ODLC.dtlpassthruchar20,
          ODLC.dtlpassthrunum01,
          ODLC.dtlpassthrunum02,
          ODLC.dtlpassthrunum03,
          ODLC.dtlpassthrunum04,
          ODLC.dtlpassthrunum05,
          ODLC.dtlpassthrunum06,
          ODLC.dtlpassthrunum07,
          ODLC.dtlpassthrunum08,
          ODLC.dtlpassthrunum09,
          ODLC.dtlpassthrunum10,
          ODLC.dtlpassthrudate01,
          ODLC.dtlpassthrudate02,
          ODLC.dtlpassthrudate03,
          ODLC.dtlpassthrudate04,
          ODLC.dtlpassthrudoll01,
          ODLC.dtlpassthrudoll02,
          CNT.po,
          CNT.reference,
          CNT.shipmentstatuscode,
          ui1Qty,
          ui1Qty - ui1Qty,
          ODLC.dtlpassthruchar10,
          CNT.weight,
          CNT.volume,
          ODLC.consigneesku,
          CNT.vicssubbol,
          ui1Qty,
          chsp.lpid,
          CNT.length,
          CNT.width,
          CNT.height,
          CNT.pallet_weight;
      ui1Ins := ui1INS + ui1Qty;
   end if;
end loop;

if ui1Ins < CNT.qty then
   debugmsg( '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~null user item 1');
   cmdSql := 'select count(1) ' ||
              'from SHIP_NT_945_CNT_' || strSuffix ||
              ' where lpid = ''' || CNT.lpid || '''' ||
              '   and item = ''' || CNT.item || '''' ||
              '   and useritem1 = ''999999999999999999''';
   debugmsg(cmdsql);
   execute immediate cmdSql into cntDTL;
   debugmsg('cntDTL ' || cntDTL || ' ' || CNT.item || ' ' || CNT.assignedid);
   cmdSql2 := 'select * from shippingplate '||
              ' where (parentlpid = ''' || CNT.LPID || ''''||
                      ' or parentlpid in '||
                           '(select lpid from shippingplate '  ||
                            'where  parentlpid = ''' || CNT.LPID || ''''||
                            'and type = ''C'')) ' ||
              '   and type in (''F'',''P'') '||
              '   and item = '''|| CNT.item || ''''||
              '   and useritem1 is null ';
   if cntDTL > 0 then
      cmdSql := 'select max(childlpid) ' ||
                 'from SHIP_NT_945_CNT_' || strSuffix ||
                 ' where lpid = ''' || CNT.lpid || '''' ||
                 '   and item = ''' || CNT.item || '''' ||
                 '   and useritem1 = ''999999999999999999''';
      debugmsg(cmdsql);
      execute immediate cmdsql into maxLIP;
      cmdSql := 'select sum(qty) ' ||
                 'from SHIP_NT_945_CNT_' || strSuffix ||
                 ' where lpid = ''' || CNT.lpid || '''' ||
                 '   and item = ''' || CNT.item || '''' ||
                 '   and childlpid = ''' || maxLIP || '''';
      execute immediate cmdsql into sumQty;
      select quantity into lipQty
         from shippingplate
         where lpid = maxLIP;
      if sumQty < lipQty then
         cmdSql2 := cmdSql2 || ' and lpid >= ''' || maxLIP || '''';
      else
         cmdSql2 := cmdSql2 || ' and lpid > ''' || maxLIP || '''';

      end if;

   else
      maxUI1 := null;
   end if;
   debugmsg(cmdsql2);
   open cr for cmdsql2;
   loop
       fetch cr into LP;
       exit when cr%notfound;

       if ui1INS +  LP.quantity > CNT.qty then
          ui1Qty := CNT.qty - ui1INS;
       else
          ui1Qty := LP.quantity;
       end if;
       if ui1Ins < CNT.qty then

       execute immediate 'insert into SHIP_NT_945_CNT_' || strSuffix ||
       ' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
       ' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
       ' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
       ' :ASSIGNEDID, :ITEM,:LOTNUMEBR,:LINK_LOTNUMBER,'||
       ' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
       ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
       ' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
       ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
       ' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
       ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
       ' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
       ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
       ' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
       ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
       ' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
       ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
       ' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
       ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
       ' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
       ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
       ' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
       ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
       ' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
       ' :PO, :REFERENCE, :SHIPMENTSTATUSCODE,' ||
       ' :QTYORDERED, :QTYDIFFERENCE, ' ||
       ' :DESCRIPTION, :WEIGHT, :VOLUME, :CONSIGNEESKU, :VICS_BOL, :TOTALQTYORDERED, :CHILDLPID, '||
       ' :LENGTH, :WIDTH, :HEIGHT, :PALLET_WEIGHT )'
       using
           CNT.orderid,
           CNT.shipid,
           CNT.custid,
           CNT.lpid,
           CNT.fromlpid,
           CNT.plt_sscc18,
           CNT.ctn_sscc18,
           CNT.trackingno,
           CNT.link_plt_sscc18,
           CNT.link_ctn_sscc18,
           CNT.link_trackingno,
           CNT.assignedid,
           CNT.item,CNT.lotnumber,
           CNT.link_lotnumber,
           LP.useritem1,
           LP.useritem2,
           '999999999999999999',
           ui1Qty,
           CNT.uom,
           CNT.cartons,
           ODLC.dtlpassthruchar01,
           ODLC.dtlpassthruchar02,
           ODLC.dtlpassthruchar03,
           ODLC.dtlpassthruchar04,
           ODLC.dtlpassthruchar05,
           ODLC.dtlpassthruchar06,
           ODLC.dtlpassthruchar07,
           ODLC.dtlpassthruchar08,
           nvl(ODLC.dtlpassthruchar09,CIUpc),
           ODLC.dtlpassthruchar10,
           ODLC.dtlpassthruchar11,
           ODLC.dtlpassthruchar12,
           ODLC.dtlpassthruchar13,
           ODLC.dtlpassthruchar14,
           ODLC.dtlpassthruchar15,
           ODLC.dtlpassthruchar16,
           ODLC.dtlpassthruchar17,
           ODLC.dtlpassthruchar18,
           ODLC.dtlpassthruchar19,
           ODLC.dtlpassthruchar20,
           ODLC.dtlpassthrunum01,
           ODLC.dtlpassthrunum02,
           ODLC.dtlpassthrunum03,
           ODLC.dtlpassthrunum04,
           ODLC.dtlpassthrunum05,
           ODLC.dtlpassthrunum06,
           ODLC.dtlpassthrunum07,
           ODLC.dtlpassthrunum08,
           ODLC.dtlpassthrunum09,
           ODLC.dtlpassthrunum10,
           ODLC.dtlpassthrudate01,
           ODLC.dtlpassthrudate02,
           ODLC.dtlpassthrudate03,
           ODLC.dtlpassthrudate04,
           ODLC.dtlpassthrudoll01,
           ODLC.dtlpassthrudoll02,
           CNT.po,
           CNT.reference,
           CNT.shipmentstatuscode,
           ui1Qty,
           ui1Qty - ui1Qty,
           ODLC.dtlpassthruchar10,
           CNT.weight,
           CNT.volume,
           ODLC.consigneesku,
           CNT.vicssubbol,
           ui1Qty,
           LP.lpid,
           CNT.length,
           CNT.width,
           CNT.height,
           CNT.pallet_weight;
       end if;
       ui1Ins := ui1INS + ui1Qty;
   end loop;
   close cr;


end if;
commit;

end;





procedure write_contents(ODLC C_ODLC%rowtype)
is
nullLpid shippingplate.lpid%type;
dtlCnt integer;
sType shippingplate.type%type;
begin

-- Only insert zero lines if called for by Zero or Cancelled parameters.
if CNT.qty = 0 then
 if upper(nvl(in_include_zero_qty_lines_yn,'N')) = 'N' then
    if upper(nvl(in_include_cancelled_orders_yn,'Y')) != 'Y'
     or OH.orderstatus != 'X' then
        return;
    end if;
 end if;
end if;

debugmsg('CNT writing contents for LP:'||CNT.lpid);

--if CNT.lpid = '00000005044009S' then
--   debugmsg('CUSTID 10->' || length(cnt.custid));
--   debugmsg('LPID 15->' || length(cnt.LPID));
--   debugmsg('FROMLPID 15->' || length(cnt.FROMLPID));
--   debugmsg('PLT_SSCC18 20->' || length(cnt.PLT_SSCC18));
--   debugmsg('CTN_SSCC18 20->' || length(cnt.CTN_SSCC18 ));
--   debugmsg('TRACKINGNO 30->' || length(cnt.TRACKINGNO ));
--   debugmsg('LINK_PLT_SSCC18 20->' || length(cnt.LINK_PLT_SSCC18 ));
--   debugmsg('LINK_CTN_SSCC18 20->' || length(cnt.LINK_CTN_SSCC18 ));
--   debugmsg('LINK_TRACKINGNO 30->' || length(cnt.LINK_TRACKINGNO ));
--   debugmsg('ITEM 20->' || length(cnt.ITEM ));
--   debugmsg('LOTNUMBER 30->' || length(cnt.LOTNUMBER ));
--   debugmsg('LINK_LOTNUMBER 30->' || length(cnt.LINK_LOTNUMBER ));
--   debugmsg('USERITEM1 20->' || length(cnt.USERITEM1 ));
--   debugmsg('USERITEM2 20->' || length(cnt.USERITEM2 ));
--   debugmsg('USERITEM3 20->' || length(cnt.USERITEM3 ));
--   debugmsg('UOM 4->' || length(cnt.UOM ));
--   debugmsg('DTLPASSTHRUCHAR01 255->' || length(od.DTLPASSTHRUCHAR01 ));
--   debugmsg('DTLPASSTHRUCHAR02 255->' || length(od.DTLPASSTHRUCHAR02 ));
--   debugmsg('DTLPASSTHRUCHAR03 255->' || length(od.DTLPASSTHRUCHAR03 ));
--   debugmsg('DTLPASSTHRUCHAR04 255->' || length(od.DTLPASSTHRUCHAR04 ));
--   debugmsg('DTLPASSTHRUCHAR05 255->' || length(od.DTLPASSTHRUCHAR05 ));
--   debugmsg('DTLPASSTHRUCHAR06 255->' || length(od.DTLPASSTHRUCHAR06 ));
--   debugmsg('DTLPASSTHRUCHAR07 255->' || length(od.DTLPASSTHRUCHAR07 ));
--   debugmsg('DTLPASSTHRUCHAR08 255->' || length(od.DTLPASSTHRUCHAR08 ));
--   debugmsg('DTLPASSTHRUCHAR09 255->' || length(od.DTLPASSTHRUCHAR09 ));
--   debugmsg('DTLPASSTHRUCHAR10 255->' || length(od.DTLPASSTHRUCHAR10 ));
--   debugmsg('DTLPASSTHRUCHAR11 255->' || length(od.DTLPASSTHRUCHAR11 ));
--   debugmsg('DTLPASSTHRUCHAR12 255->' || length(od.DTLPASSTHRUCHAR12 ));
--   debugmsg('DTLPASSTHRUCHAR13 255->' || length(od.DTLPASSTHRUCHAR13 ));
--   debugmsg('DTLPASSTHRUCHAR14 255->' || length(od.DTLPASSTHRUCHAR14 ));
--   debugmsg('DTLPASSTHRUCHAR15 255->' || length(od.DTLPASSTHRUCHAR15 ));
--   debugmsg('DTLPASSTHRUCHAR16 255->' || length(od.DTLPASSTHRUCHAR16 ));
--   debugmsg('DTLPASSTHRUCHAR17 255->' || length(od.DTLPASSTHRUCHAR17 ));
--   debugmsg('DTLPASSTHRUCHAR18 255->' || length(od.DTLPASSTHRUCHAR18 ));
--   debugmsg('DTLPASSTHRUCHAR19 255->' || length(od.DTLPASSTHRUCHAR19 ));
--   debugmsg('DTLPASSTHRUCHAR20 255->' || length(od.DTLPASSTHRUCHAR20 ));

--   debugmsg('PO 20->' || length(cnt.PO ));
--   debugmsg('REFERENCE 20->' || length(cnt.REFERENCE ));
--   debugmsg('SHIPMENTSTATUSCODE 2->' || length(cnt.SHIPMENTSTATUSCODE ));
--   debugmsg('DESCRIPTION 40->' || length(od.dtlpassthruchar10 ));
--   debugmsg('CONSIGNEESKU VARCHAR(255->' || length(od.CONSIGNEESKU ));
--   debugmsg('VICSSUBBOL 17->' || length(cnt.VICSSUBBOL ));
--end if;

begin
  select upc
    into CIUpc
    from custitemupcview
   where custid = cu.custid
     and item = od.item;
exception when others then
  CIUpc := '';
end;


if CNT.qty = 0 then
    CNT.shipmentstatuscode := 'CU';
else
    if CNT.qtyordered <= CNT.qty then
        CNT.shipmentstatuscode := 'CC';
    else
        CNT.shipmentstatuscode := 'PR';
    end if;
end if;
if nvl(in_cnt_detail_yn, 'N') = 'Y' and
   CNT.qty != 0 then
   select type into sType
      from shippingplate
      where lpid = CNT.lpid;
   debugmsg('sType ' || sType || ' ' || CNT.qty);
   if sType = 'M' or
      sType = 'C' then
         if  nvl(in_cnt_detail_ignore_ui3_yn,'N') = 'Y' then
            write_dtl_contents_ui1(ODLC);
         else
         write_dtl_contents(ODLC);
         end if;
         return;
   end if;
end if;

nullLpid := null;

execute immediate 'insert into SHIP_NT_945_CNT_' || strSuffix ||
' values (:ORDERID,:SHIPID,:CUSTID,:LPID,:FROMLPID,'||
' :PLT_SSCC18,:CTN_SSCC18,:TRACKINGNO,'||
' :LINK_PLT_SSCC18,:LINK_CTN_SSCC18,:LINK_TRACKINGNO,'||
' :ASSIGNEDID, :ITEM,:LOTNUMEBR,:LINK_LOTNUMBER,'||
' :USERITEM1,:USERITEM2,:USERITEM3,:QTY,:UOM,:CARTONS, ' ||
' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,' ||
' :DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,' ||
' :DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,' ||
' :DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,' ||
' :DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,' ||
' :DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,' ||
' :DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,' ||
' :DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,' ||
' :DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,' ||
' :DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
' :PO, :REFERENCE, :SHIPMENTSTATUSCODE,' ||
' :QTYORDERED, :QTYDIFFERENCE, ' ||
' :DESCRIPTION, :WEIGHT, :VOLUME, :CONSIGNEESKU, :VICS_BOL, :TOTALQTYORDERED, :CHILDLPID, '||
' :LENGTH, :WIDTH, :HEIGHT, :PALLET_WEIGHT )'
using
    CNT.orderid,
    CNT.shipid,
    CNT.custid,
    CNT.lpid,
    CNT.fromlpid,
    CNT.plt_sscc18,
    CNT.ctn_sscc18,
    CNT.trackingno,
    CNT.link_plt_sscc18,
    CNT.link_ctn_sscc18,
    CNT.link_trackingno,
    CNT.assignedid,
    CNT.item,CNT.lotnumber,
    CNT.link_lotnumber,
    CNT.useritem1,
    CNT.useritem2,
    CNT.useritem3,
    CNT.qty,
    CNT.uom,
    CNT.cartons,
    ODLC.dtlpassthruchar01,
    ODLC.dtlpassthruchar02,
    ODLC.dtlpassthruchar03,
    ODLC.dtlpassthruchar04,
    ODLC.dtlpassthruchar05,
    ODLC.dtlpassthruchar06,
    ODLC.dtlpassthruchar07,
    ODLC.dtlpassthruchar08,
    nvl(ODLC.dtlpassthruchar09,CIUpc),
    ODLC.dtlpassthruchar10,
    ODLC.dtlpassthruchar11,
    ODLC.dtlpassthruchar12,
    ODLC.dtlpassthruchar13,
    ODLC.dtlpassthruchar14,
    ODLC.dtlpassthruchar15,
    ODLC.dtlpassthruchar16,
    ODLC.dtlpassthruchar17,
    ODLC.dtlpassthruchar18,
    ODLC.dtlpassthruchar19,
    ODLC.dtlpassthruchar20,
    ODLC.dtlpassthrunum01,
    ODLC.dtlpassthrunum02,
    ODLC.dtlpassthrunum03,
    ODLC.dtlpassthrunum04,
    ODLC.dtlpassthrunum05,
    ODLC.dtlpassthrunum06,
    ODLC.dtlpassthrunum07,
    ODLC.dtlpassthrunum08,
    ODLC.dtlpassthrunum09,
    ODLC.dtlpassthrunum10,
    ODLC.dtlpassthrudate01,
    ODLC.dtlpassthrudate02,
    ODLC.dtlpassthrudate03,
    ODLC.dtlpassthrudate04,
    ODLC.dtlpassthrudoll01,
    ODLC.dtlpassthrudoll02,
    CNT.po,
    CNT.reference,
    CNT.shipmentstatuscode,
    CNT.qtyordered,
    CNT.qtyordered - CNT.qty,
    ODLC.dtlpassthruchar10,
    CNT.weight,
    CNT.volume,
    ODLC.consigneesku,
    CNT.vicssubbol,
    CNT.totalqtyordered,
    nullLpid,
    CNT.length,
    CNT.width,
    CNT.height,
    CNT.pallet_weight;


commit;

end;

procedure distribute_odl(in_custid varchar2, in_item varchar2, in_lot varchar2,
    in_orderitem varchar2, in_orderlot varchar2,
    in_uom varchar2, in_qty IN OUT number)
is
l_qty integer;
begin

    debugmsg('Begin Distribute::');
    if do_cases then
        debugmsg('Doing cases for:'||in_item||'/'||l_carton_uom||'/'||in_uom);
        ctn_qty := zcu.equiv_uom_qty(in_custid, in_item,
                           l_carton_uom, 1, in_uom);

        debugmsg('ctn_qty:'||ctn_qty);
        if (nvl(ctn_qty,0) < 1) then
            ctn_qty := 1;
        end if;
    else
        ctn_qty := in_qty;
        debugmsg('ctn_qty:'||ctn_qty||' in:'||in_qty);
    end if;


    for odlx in 1..odl.count loop

        debugmsg('Check ODL:'||odl(odlx).item
            ||'/'||odl(odlx).lotnumber
            ||'/'||odl(odlx).linenumber
            ||'/'||odl(odlx).qty);

        CNT.totalqtyordered := odl(odlx).totalqtyordered;

        if in_orderitem = odl(odlx).item
         and nvl(in_orderlot,'(none)')
                = nvl(odl(odlx).lotnumber,'(none)')
         and odl(odlx).qty > 0 then

          ODLC := null;
          OPEN C_ODLC(OD.orderid, OD.shipid, odl(odlx).item,
                odl(odlx).lotnumber, odl(odlx).linenumber);
          FETCH C_ODLC into ODLC;
          CLOSE C_ODLC;

         while (in_qty > 0 and odl(odlx).qty > 0)
         loop


            if not do_cases then
                ctn_qty := in_qty;
                debugmsg('ctn_qty:'||ctn_qty||' in:'||in_qty);
            end if;

            CNT.qtyordered := least(odl(odlx).qty, ctn_qty);


            l_qty := least(in_qty, CNT.qtyordered);



            if l_qty <= odl(odlx).qty then
                CNT.assignedid := odl(odlx).linenumber;
                CNT.qty := l_qty; --csp.quantity;
                weighttemp := l_qty * weighthold;
                cubetemp   := l_qty * cubehold;
                CNT.weight := weighttemp;
                CNT.volume := cubetemp;
                CNT.cartons := zcu.equiv_uom_qty(in_custid, in_item,
                       in_uom, l_qty, l_carton_uom);
                odl(odlx).qty := odl(odlx).qty - l_qty; --csp.quantity;
                -- csp.quantity := 0;
                debugmsg('Adding < CNT for:'||CNT.qty||'-'||weighttemp||
                                                                          '/' || weighthold);
                write_contents(ODLC);
            else
                CNT.assignedid := odl(odlx).linenumber;
                CNT.qty := odl(odlx).qty;
                weighttemp := odl(odlx).qty * weighthold;
                cubetemp := odl(odlx).qty * cubehold;
                CNT.weight := weighttemp;
                CNT.volume := cubetemp;
                CNT.cartons := zcu.equiv_uom_qty(in_custid, in_item,
                       in_uom, CNT.qty, l_carton_uom);
                odl(odlx).qty := 0;
                debugmsg('Adding > CNT for:'||CNT.qty);
                write_contents(ODLC);

            end if;

            in_qty := in_qty - l_qty;
            odl(odlx).qty_ship := odl(odlx).qty_ship + CNT.qty;
         end loop;
        end if;
        exit when in_qty <= 0;
    end loop;


--    if csp.quantity > 0 then
    while (in_qty > 0)
    loop
        CNT.assignedid := null;
--        CNT.qty := csp.quantity;
        weighttemp := least(in_qty,ctn_qty) * weighthold;
        cubetemp   := least(in_qty,ctn_qty) * cubehold;
        CNT.weight := weighttemp;
        CNT.volume := cubetemp;
        CNT.qty := least(in_qty, ctn_qty);
        CNT.qtyordered := 0;
--        CNT.cartons := zcu.equiv_uom_qty(csp.custid, csp.item,
--                 csp.unitofmeasure, csp.quantity, l_carton_uom);
        CNT.cartons := zcu.equiv_uom_qty(in_custid, in_item,
                 in_uom, least(in_qty,ctn_qty), l_carton_uom);
        in_qty := in_qty - least(in_qty, ctn_qty);
        debugmsg('Adding no match CNT for:'||CNT.qty);
        ODLC := null;
        OPEN C_ODLC(OD.orderid, OD.shipid, in_item,
            in_lot, null);
        FETCH C_ODLC into ODLC;
        CLOSE C_ODLC;
        write_contents(ODLC);
    end loop;

end distribute_odl;


begin

debugmsg('begin add_945_cnt_rows ' || oh.orderid || '-' || oh.shipid);

if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  if oh.orderstatus = 'X' then
    return;
  end if;
end if;

ca := null;
open curCarrier(oh.carrier);
fetch curCarrier into ca;
close curCarrier;

ld := null;
open curLoads(oh.loadno);
fetch curLoads into ld;
close curLoads;

-- First load the orderdtlline information
odl.delete;
odlx := 0;

for crec in C_ODL(oh.orderid, oh.shipid) loop
    odlx := odl.count + 1;
    odl(odlx).item := crec.item;
    odl(odlx).lotnumber := crec.lotnumber;
    odl(odlx).linenumber := crec.linenumber;
    odl(odlx).qty := crec.qty;
    odl(odlx).totalqtyordered := crec.totalqtyordered;
    odl(odlx).qty_ship := 0;
    odl(odlx).uom := crec.baseuom;

    debugmsg('Add ODL:'||odl(odlx).item
        ||'/'||odl(odlx).lotnumber
        ||'/'||odl(odlx).linenumber
        ||'/'||odl(odlx).qty);

end loop;

owave := zconsorder.cons_orderid(oh.orderid, oh.shipid);



if owave != 0 then -- consolidated order processing
   for csp in C_CONS_SP(oh.orderid, oh.shipid) loop
       debugmsg('CNT begin cons plate:'||csp.lpid || ' Type:'||csp.type);
       CNT := null;
       CNT.orderid := oh.orderid;
       CNT.shipid := oh.shipid;
       CNT.custid := oh.custid;
       CNT.lpid := csp.lpid;
       CNT.fromlpid := csp.fromlpid;
       CNT.reference := substr(oh.reference,1,20);
       CNT.height := csp.height;
       CNT.length := csp.length;
       CNT.width := csp.width;
       CNT.pallet_weight := csp.pallet_weight;
       -- CNT.shipmentstatuscode := substr(oh.orderstatus,1,1);



       debugmsg('C---->' || oh.orderid || ' ' || oh.shipid || ' P ' || csp.lpid);
       LBL := null;
       CNT.plt_sscc18 := null;
       CNT.trackingno := csp.trackingno;
       CNT.link_plt_sscc18 := nvl(LBL.barcode,'(none)');
       CNT.link_trackingno := nvl(csp.trackingno,'(none)');

       do_cases := FALSE;

       CNT.ctn_sscc18 := LBL.barcode;
       CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');

       --CNT.ctn_sscc18 := null;
       --CNT.link_ctn_sscc18 := '(none)';

       OD := null;
       OPEN C_OD(oh.orderid, oh.shipid, csp.orderitem, csp.orderlot);
               --csp,item, csp.lotnumber);
       FETCH C_OD into OD;
       CLOSE C_OD;

       CNT.assignedid := OD.dtlpassthrunum10;
       CNT.item := csp.item;
       CNT.lotnumber := csp.lotnumber;
       CNT.link_lotnumber := nvl(csp.lotnumber,'(none)');
       CNT.useritem1 := csp.useritem1;
       CNT.useritem2 := csp.useritem2;
       CNT.useritem3 := csp.useritem3;
       -- CNT.qty := csp.quantity;
       CNT.uom := csp.unitofmeasure;
       -- Calculate weight and cube hold numbers
       weighthold := zci.item_weight(csp.custid,od.item,od.uom);
       cubehold := od.cubeship;
       if od.qtyship > 0 then
          cubehold := od.cubeship / od.qtyship;
         end if;
       debugmsg('wt/cube hold: ' || weighthold || '-' || cubehold || '<');

       -- CNT.cartons := zcu.equiv_uom_qty(csp.custid, csp.item,
       --                csp.unitofmeasure, csp.quantity, l_carton_uom);


       holdvics := SUBSTR(NVL(SUBSTR(cu.ManufacturerUCC,1,7), '0400000') || LPAD(oh.orderid||oh.shipid,9,'0'),1,17);
       CNT.vicssubbol := VICSChkDigit(holdvics);

       CNT.po := null;
       if csp.fromlpid is not null
       and nvl(in_contents_by_po,'N') = 'Y' then
         begin
           select po
             into CNT.po
             from allplateview
            where lpid = csp.fromlpid;
         exception when others then
           CNT.po := null;
         end;
       end if;

       for cs in C_LBLCS_CONS(oh.orderid, oh.shipid, csp.lpid) loop
          odlfound := false;
           debugmsg('Check for Item 1:'||cs.item ||'/'||cs.lotnumber
                   ||'/('||csp.orderitem||'/'||csp.orderlot||')'||'/'||cs.quantity);

               CNT.ctn_sscc18 := cs.barcode;
               CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');


               weighthold := zci.item_weight(csp.custid,od.item,od.uom);
               if od.qtyship > 0 then
                  cubehold := od.cubeship / od.qtyship;
               end if;
               debugmsg('wt/cube hold cons: ' || weighthold || '-' || cubehold || '<');


               distribute_odl(cs.custid, cs.item, cs.lotnumber,
                   csp.orderitem, csp.orderlot,
                   csp.unitofmeasure, cs.quantity); -- csp.quantity);
       end loop;



    --_!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   end loop;
else
   for csp in C_SP(oh.orderid, oh.shipid) loop
       debugmsg('CNT begin plate:'||csp.lpid || ' Type:'||csp.type);

       -- set up the contents row
       CNT := null;

       CNT.orderid := oh.orderid;
       CNT.shipid := oh.shipid;
       CNT.custid := oh.custid;
       CNT.lpid := csp.lpid;
       CNT.height := csp.height;
       CNT.length := csp.length;
       CNT.width := csp.width;
       CNT.pallet_weight := csp.pallet_weight;
       CNT.fromlpid := csp.fromlpid;
           CNT.reference := substr(oh.reference,1,20);
           --CNT.shipmentstatuscode := substr(oh.orderstatus,1,1);


       -- locate the top level label (if any)
       debugmsg('---->' || oh.orderid || ' ' || oh.shipid || ' P ' || csp.lpid);
       LBL := null;
       OPEN C_LBL(oh.orderid, oh.shipid, 'P', csp.lpid, null);
       FETCH C_LBL into LBL;
       CLOSE C_LBL;
       debugmsg('LBL.lpid ' || LBL.lpid || ' mopd ' || cu.mixed_order_pallet_dimensions ||
                ' order ' || csp.orderid || '-' || csp.shipid);
       if LBL.lpid is null and
          cu.mixed_order_pallet_dimensions = 'Y' and
          csp.orderid = 0 and
          csp.shipid = 0 then
          debugmsg('open c_lbl_mixed)');
          OPEN C_LBL_MIXED(csp.lpid);
          FETCH C_LBL_MIXED into LBL;
          CLOSE C_LBL_MIXED;
       end if;
       CNT.plt_sscc18 := LBL.barcode;
       debugmsg ('Pallet barcode ->' || CNT.plt_sscc18);

       CNT.trackingno := csp.trackingno;
       CNT.link_plt_sscc18 := nvl(LBL.barcode,'(none)');
       CNT.link_trackingno := nvl(csp.trackingno,'(none)');

       do_cases := FALSE;

       LBLCS := null;
       OPEN C_LBLCS(oh.orderid, oh.shipid, csp.lpid, null, null);
       FETCH C_LBLCS into LBLCS;
       CLOSE C_LBLCS;

       if LBLCS.lpid is not null then
           do_cases := TRUE;
           debugmsg('do cases true >' || csp.type);
       end if;


       if csp.type in ('F','P') then

           LBL := null;
           OPEN C_LBL(oh.orderid, oh.shipid, 'C', csp.lpid, csp.item);
           FETCH C_LBL into LBL;
           CLOSE C_LBL;

           CNT.ctn_sscc18 := LBL.barcode;
           CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');

           --CNT.ctn_sscc18 := null;
           --CNT.link_ctn_sscc18 := '(none)';

           OD := null;
           OPEN C_OD(oh.orderid, oh.shipid, csp.orderitem, csp.orderlot);
                   --csp,item, csp.lotnumber);
           FETCH C_OD into OD;
           CLOSE C_OD;

           CNT.assignedid := OD.dtlpassthrunum10;
           CNT.item := csp.item;
           CNT.lotnumber := csp.lotnumber;
           CNT.link_lotnumber := nvl(csp.lotnumber,'(none)');
           CNT.useritem1 := csp.useritem1;
           CNT.useritem2 := csp.useritem2;
           CNT.useritem3 := csp.useritem3;
           -- CNT.qty := csp.quantity;
           CNT.uom := csp.unitofmeasure;
           -- Calculate weight and cube hold numbers
           weighthold := zci.item_weight(csp.custid,od.item,od.uom);
           cubehold := od.cubeship;
           if od.qtyship > 0 then
              cubehold := od.cubeship / od.qtyship;
             end if;
           debugmsg('wt/cube hold: ' || weighthold || '-' || cubehold || '<');

           -- CNT.cartons := zcu.equiv_uom_qty(csp.custid, csp.item,
           --                csp.unitofmeasure, csp.quantity, l_carton_uom);


             holdvics := SUBSTR(NVL(SUBSTR(cu.ManufacturerUCC,1,7), '0400000') ||
               LPAD(
             oh.orderid||oh.shipid,9,'0'),1,17);

                   CNT.vicssubbol := VICSChkDigit(holdvics);

           CNT.po := null;
           if csp.fromlpid is not null
           and nvl(in_contents_by_po,'N') = 'Y' then
             begin
               select po
                 into CNT.po
                 from allplateview
                where lpid = csp.fromlpid;
             exception when others then
               CNT.po := null;
             end;
           end if;

           if do_cases then
               for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid,
                   csp.item, csp.lotnumber)
               loop
                   odlfound := false;
                   debugmsg('Check for Item 1:'||cs.item
                       ||'/'||cs.lotnumber
                       ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                       ||'/'||cs.quantity);

                   CNT.ctn_sscc18 := cs.barcode;
                   CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');
                   weighthold := zci.item_weight(csp.custid,od.item,od.uom);
                   if od.qtyship > 0 then
                      cubehold := od.cubeship / od.qtyship;
                   end if;
                   debugmsg('wt/cube hold 1: ' || weighthold || '-' || cubehold || '<');

                   distribute_odl(cs.custid, cs.item, cs.lotnumber,
                       csp.orderitem, csp.orderlot,
                       csp.unitofmeasure, cs.quantity);

               end loop;


           else
               odlfound := false;
               debugmsg('Check for Item 2:'||csp.item
                   ||'/'||csp.lotnumber
                   ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                   ||'/'||csp.quantity);
               weighthold := zci.item_weight(csp.custid,od.item,od.uom);
               if od.qtyship > 0 then
                  cubehold := od.cubeship / od.qtyship;
               end if;
               debugmsg('wt/cube hold 2: ' || weighthold || '-' || cubehold || '<');

               distribute_odl(csp.custid, csp.item, csp.lotnumber,
                   csp.orderitem, csp.orderlot,
                   csp.unitofmeasure, csp.quantity);
           end if;
           goto lp_continue;

       end if;

   -- Need contents of the top level plate since it has no real contents
   --    for cdtl in (select item, lotnumber, useritem1, useritem2, useritem3,
   --                    unitofmeasure, sum(quantity) quantity
   --                   from shippingplate
   --                  where orderid = oh.orderid
   --                    and shipid = oh.shipid
   --                    and parentlpid = csp.lpid
   --                    and type in ('F','P')
   --                   group by item, lotnumber, useritem1, useritem2, useritem3,
   --                        unitofmeasure)
       for cdtl in (select S.item, S.lotnumber, S.orderitem, S.orderlot,
                       decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null) po,
                       min(S.useritem1) useritem1,
                       min(S.useritem2) useritem2,
                       min(S.useritem3) useritem3,
                       S.unitofmeasure, sum(S.quantity) quantity
                      from shippingplate S
                     where S.orderid = oh.orderid
                       and S.shipid = oh.shipid
                       -- and parentlpid = csp.lpid
                       and S.type in ('F','P')
                       start with S.parentlpid = csp.lpid
                           connect by prior S.lpid = S.parentlpid
                      group by S.item, S.lotnumber, S.orderitem, S.orderlot,
                       S.unitofmeasure,
                       decode(nvl(in_contents_by_po,'N'),'Y',find_po(S.fromlpid),null))
       loop
           no_item_carton := FALSE;
           LBL := null;
           OPEN C_LBL(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
           FETCH C_LBL into LBL;
           CLOSE C_LBL;

           if LBL.orderid is null then
               OPEN C_LBLC(oh.orderid, oh.shipid, 'C', csp.lpid, cdtl.item);
               FETCH C_LBLC into LBL;
               CLOSE C_LBLC;
           end if;

        -- if caselabels is written with no item for multi-item cartons
        -- then just get the barcode via the csp.lpid.
           if LBL.orderid is null then
               OPEN C_LBLC(oh.orderid, oh.shipid, 'C', csp.lpid, NULL);
               FETCH C_LBLC into LBL;
               CLOSE C_LBLC;
               no_item_carton := TRUE;
           end if;
           if nvl(in_outlot, 'N') = 'Y' then
              no_item_carton := TRUE;
           end if;

           CNT.ctn_sscc18 := LBL.barcode;
           CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');

           OD := null;
           OPEN C_OD(oh.orderid, oh.shipid, cdtl.orderitem, cdtl.orderlot);
           FETCH C_OD into OD;
           CLOSE C_OD;

           CNT.assignedid := OD.dtlpassthrunum10;
           CNT.item := cdtl.item;
           CNT.lotnumber := cdtl.lotnumber;
           CNT.link_lotnumber := nvl(cdtl.lotnumber,'(none)');
           CNT.useritem1 := cdtl.useritem1;
           CNT.useritem2 := cdtl.useritem2;
           CNT.useritem3 := cdtl.useritem3;
           CNT.uom := cdtl.unitofmeasure;
           CNT.po := cdtl.po;

           holdvics := SUBSTR(NVL(SUBSTR(cu.ManufacturerUCC,1,7), '0400000') ||
                              LPAD(oh.orderid||oh.shipid,9,'0'),1,17);

           CNT.vicssubbol := VICSChkDigit(holdvics);


           if do_cases then
              if no_item_carton then
                 for cs in C_SP_CARTON(oh.orderid, oh.shipid, cdtl.item, cdtl.lotnumber, csp.lpid)
                 loop
                     odlfound := false;
                     debugmsg('Check for Item C:'||cs.item
                         ||'/'||cs.lotnumber
                         ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                         ||'/'||cs.quantity);

                     weighthold := zci.item_weight(csp.custid,od.item,od.uom);
                     if od.qtyship > 0 then
                        cubehold := od.cubeship / od.qtyship;
                     end if;
                     debugmsg('wt/cube hold C: ' || weighthold || '-' || cubehold || '<');

                     CNT.ctn_sscc18 := LBL.barcode;
                     CNT.link_ctn_sscc18 := nvl(LBL.barcode,'(none)');

                     distribute_odl(cs.custid, cs.item, cs.lotnumber,
                         cdtl.orderitem, cdtl.orderlot,
                         cdtl.unitofmeasure, cs.quantity);
                 end loop;
              else
                 for cs in C_LBLCS(oh.orderid, oh.shipid, csp.lpid,
                     cdtl.item, cdtl.lotnumber)
                 loop
                     odlfound := false;
                     debugmsg('Check for Item 3:'||cs.item
                         ||'/'||cs.lotnumber
                         ||'/('||cdtl.orderitem||'/'||cdtl.orderlot||')'
                         ||'/'||cs.quantity);

                     weighthold := zci.item_weight(csp.custid,od.item,od.uom);
                     if od.qtyship > 0 then
                        cubehold := od.cubeship / od.qtyship;
                     end if;
                     debugmsg('wt/cube hold 3: ' || weighthold || '-' || cubehold || '<');

                     CNT.ctn_sscc18 := cs.barcode;
                     CNT.link_ctn_sscc18 := nvl(cs.barcode,'(none)');

                     distribute_odl(cs.custid, cs.item, cs.lotnumber,
                         cdtl.orderitem, cdtl.orderlot,
                         cdtl.unitofmeasure, cs.quantity);
                 end loop;
              end if;
           else
               odlfound := false;
               debugmsg('Check for Item 4:'||cdtl.item
                   ||'/'||cdtl.lotnumber
                   ||'/('||csp.orderitem||'/'||csp.orderlot||')'
                   ||'/'||cdtl.quantity);

               weighthold := zci.item_weight(csp.custid,od.item,od.uom);
               if od.qtyship > 0 then
                  cubehold := od.cubeship / od.qtyship;
               end if;
               debugmsg('wt/cube hold 4: ' || weighthold || '-' || cubehold || '<');

               distribute_odl(csp.custid, cdtl.item, cdtl.lotnumber,
                   cdtl.orderitem, cdtl.orderlot,
                   cdtl.unitofmeasure, cdtl.quantity);
           end if;
       end loop;

   <<lp_continue>>
       null;
   end loop;
end if;
-- Now if we are doing zero lines

/*
if upper(nvl(in_include_zero_qty_lines_yn,'N')) = 'Y' then

    debugmsg('Starting zero for:'||oh.orderid||'/'||oh.shipid);

    for cod in (select *
                  from orderdtl
                  where orderid = oh.orderid
                    and shipid = oh.shipid
                    and nvl(qtyship,0) = 0)
    loop

        debugmsg('Have zero for:'||cod.item);

        CNT := null;

        CNT.orderid := oh.orderid;
        CNT.shipid := oh.shipid;
        CNT.custid := oh.custid;
        CNT.lpid := '999999999999999';
        CNT.fromlpid := '999999999999999';
                CNT.reference := oh.reference;
                CNT.shipmentstatuscode := 'CU';

        CNT.link_plt_sscc18 := '(none)';
        CNT.link_ctn_sscc18 := '(none)';
        CNT.link_trackingno := '(none)';

        CNT.assignedid := COD.dtlpassthrunum10;
        CNT.item := COD.item;
        CNT.lotnumber := COD.lotnumber;
        CNT.link_lotnumber := nvl(COD.lotnumber,'(none)');
        CNT.qty := 0;
        CNT.uom := COD.uom;
        CNT.cartons := 0;
        CNT.weight := 0;
        CNT.volume := 0;
        CNT.totalqtyordered := cod.qtyorder;
        CNT.qtyordered := cod.qtyorder;
        holdvics := SUBSTR(NVL(SUBSTR(cu.ManufacturerUCC,1,7), '0400000')
                || LPAD(oh.orderid||oh.shipid,9,'0'),1,17);
        CNT.vicssubbol := VICSChkDigit(holdvics);

        write_contents(COD);



    end loop;
end if;

*/

-- Check for Leftover ODL quantities
CNT := null;
CNT.orderid := oh.orderid;
CNT.shipid := oh.shipid;
CNT.custid := oh.custid;
CNT.lpid := '999999999999999';
CNT.fromlpid := '999999999999999';
CNT.reference := oh.reference;
CNT.shipmentstatuscode := 'CU';

CNT.link_plt_sscc18 := '(none)';
CNT.link_ctn_sscc18 := '(none)';
CNT.link_trackingno := '(none)';
CNT.height := null;
CNT.length := null;
CNT.width := null;
CNT.pallet_weight := null;



for odlx in 1..odl.count loop
  if odl(odlx).qty > 0 then
       debugmsg('Leftover ODL:'||odl(odlx).item
            ||'/'||odl(odlx).lotnumber
            ||'/'||odl(odlx).linenumber
            ||'/'||odl(odlx).qty);


    if do_cases then
        ctn_qty := zcu.equiv_uom_qty(in_custid, odl(odlx).item,
                       l_carton_uom, 1, odl(odlx).uom);

        if (nvl(ctn_qty,0) < 1) then
            ctn_qty := 1;
        end if;
    else
        ctn_qty := odl(odlx).qty;
    end if;

    while (odl(odlx).qty > 0)
    loop

        OD := null;
        OPEN C_OD(oh.orderid, oh.shipid, odl(odlx).item, odl(odlx).lotnumber);
        FETCH C_OD into OD;
        CLOSE C_OD;

        ODLC := null;
        OPEN C_ODLC(OD.orderid, OD.shipid, odl(odlx).item,
            odl(odlx).lotnumber, odl(odlx).linenumber);
        FETCH C_ODLC into ODLC;
        CLOSE C_ODLC;


/*
        if OD.linestatus = 'X' then
           CNT.shipmentstatuscode := 'CU';
        else
           if OD.qtyorder = OD.qtyship then
              CNT.shipmentstatuscode := 'CC';
           else
              CNT.shipmentstatuscode := 'PR';
           end if;
        end if;
*/
-- XXXXX

        CNT.item := odl(odlx).item;
        CNT.lotnumber := odl(odlx).lotnumber;
        CNT.link_lotnumber := nvl(odl(odlx).lotnumber,'(none)');
        CNT.totalqtyordered := odl(odlx).totalqtyordered;
        CNT.qtyordered := least(odl(odlx).qty, ctn_qty);

        CNT.assignedid := odl(odlx).linenumber;
        CNT.qty := 0; --csp.quantity;
        weighttemp := least(odl(odlx).qty,ctn_qty) * weighthold;
        cubetemp   := least(odl(odlx).qty,ctn_qty) * cubehold;
        CNT.weight := weighttemp;
        CNT.volume := cubetemp;
        CNT.cartons := 0;
        write_contents(ODLC);

        odl(odlx).qty := odl(odlx).qty - CNT.qtyordered;
    end loop;



  end if;
end loop;

cmdSql := 'update SHIP_NT_945_CNT_' || strSuffix ||
            '   set shipmentstatuscode = ''' || 'CU' || '''' || ',' ||
            '       plt_sscc18 = ''' || '99999999999999999999' || '''' ||
            ', totalqtyordered = qtyordered' ||
            ' where qty = 0 ';
debugmsg(cmdsql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

exception when others then
  debugmsg(sqlerrm);
end;


procedure extract_by_id_contents is
begin

l_carton_uom := nvl(substr(in_carton_uom,1,4),'CS');


debugmsg('begin 945 extract by id contents');
debugmsg('creating 945 cnt');
cmdSql := 'create table SHIP_NT_945_CNT_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,' ||
' LPID VARCHAR2(15), FROMLPID VARCHAR2(15), PLT_SSCC18 VARCHAR2(20),'||
' CTN_SSCC18 VARCHAR2(20), ' ||
' TRACKINGNO VARCHAR2(30), ' ||
' LINK_PLT_SSCC18 VARCHAR2(20), LINK_CTN_SSCC18 VARCHAR2(20), ' ||
' LINK_TRACKINGNO VARCHAR2(30), ' ||
' ASSIGNEDID NUMBER(16,4), item varchar2(50) not null, '||
' LOTNUMBER VARCHAR2(30),LINK_LOTNUMBER VARCHAR2(30),' ||
' USERITEM1 VARCHAR2(20),USERITEM2 VARCHAR2(20),USERITEM3 VARCHAR2(20),'||
' QTY NUMBER, UOM VARCHAR2(4), CARTONS NUMBER, ' ||
' DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255),' ||
' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),' ||
' DTLPASSTHRUNUM03 NUMBER(16,4),DTLPASSTHRUNUM04 NUMBER(16,4),' ||
' DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),' ||
' DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),' ||
' DTLPASSTHRUNUM09 NUMBER(16,4),DTLPASSTHRUNUM10 NUMBER(16,4),' ||
' DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,' ||
' DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,' ||
' DTLPASSTHRUDOLL01 NUMBER(10,2),DTLPASSTHRUDOLL02 NUMBER(10,2),'||
' PO VARCHAR2(20), REFERENCE VARCHAR2(20), SHIPMENTSTATUSCODE VARCHAR2(2),' ||
' QTYORDERED NUMBER(10), QTYDIFFERENCE NUMBER(10), DESCRIPTION VARCHAR2(255),' ||
' WEIGHT NUMBER(17,8), VOLUME NUMBER(10,4), CONSIGNEESKU VARCHAR(255),'||
' VICSSUBBOL VARCHAR2(17), TOTALQTYORDERED NUMBER(10), CHILDLPID VARCHAR2(15), '||
' LENGTH NUMBER(10,4), WIDTH NUMBER(10,4), HEIGHT NUMBER(10,4), PALLET_WEIGHT NUMBER(10,4) )';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



debugmsg('creating 945 id');
cmdSql := 'create view SHIP_NT_945_ID_'|| strSuffix ||
' as select Y.plseqno, ' ||
' row_number() over (order by null) seqno, orderid,shipid,custid, ' ||
' X.lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
' trackingno,'||
' link_plt_sscc18,link_ctn_sscc18,link_trackingno, sum(cartons) cartons, ' ||
' length, width, height ' ||
'  from ship_nt_945_cnt_' || strSuffix || ' X, '||
' (select row_number() over (order by lpid) plseqno, lpid '||
'    from ship_nt_945_cnt_'||strSuffix||' group by lpid ) Y '||
' where X.lpid = Y.lpid ' ||
'  group by Y.plseqno, orderid,shipid,custid,X.lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
'  trackingno, '||
'  link_plt_sscc18,link_ctn_sscc18,link_trackingno, length, width, height ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

/*
debugmsg('creating 945 id mm');
cmdSql := 'create view SHIP_NT_945_ID_MM_'|| strSuffix ||
' as select Y.plseqno, ' ||
' row_number() over (order by null) seqno, item, lotnumber, '||
' nvl(lotnumber,''(none)'') || X.assignedid link_lotnumber,orderid,shipid,custid, ' ||
' X.lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
' trackingno,'||
' link_plt_sscc18,link_ctn_sscc18,link_trackingno, sum(cartons) cartons ' ||
' from ship_nt_945_cnt_' || strSuffix || ' X, '||
' (select row_number() over (order by lpid) plseqno,lpid,assignedid '||
' from ship_nt_945_cnt_'||strSuffix||' group by lpid,assignedid ) Y '||
' where X.lpid = Y.lpid AND X.assignedid=Y.assignedid '||
' group by Y.plseqno,item,lotnumber,link_lotnumber,orderid,shipid,custid,'||
' X.lpid,fromlpid,plt_sscc18,ctn_sscc18,trackingno, '||
' link_plt_sscc18,link_ctn_sscc18,link_trackingno,X.assignedid';
*/

cmdSql := 'create view SHIP_NT_945_ID_MM_'|| strSuffix ||
' as select Y.plseqno, ' ||
' row_number() over (order by null) seqno, item, lotnumber, '||
' nvl(lotnumber,''(none)'') link_lotnumber,orderid,shipid,custid, ' ||
' X.lpid,fromlpid,plt_sscc18,ctn_sscc18,'||
' trackingno,'||
' link_plt_sscc18,link_ctn_sscc18,link_trackingno, sum(cartons) cartons, ' ||
' length, width, height '||
'  from ship_nt_945_cnt_' || strSuffix || ' X, '||
' (select row_number() over (order by lpid) plseqno, lpid '||
'    from ship_nt_945_cnt_'||strSuffix||' group by lpid ) Y '||
' where X.lpid = Y.lpid ' ||
'  group by Y.plseqno,item,lotnumber,link_lotnumber,orderid,shipid,custid,'||
          ' X.lpid,fromlpid,plt_sscc18,ctn_sscc18,trackingno, '||
          ' link_plt_sscc18,link_ctn_sscc18,link_trackingno, length, width, height ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


debugmsg('creating 945 pl');
cmdSql := 'create view SHIP_NT_945_PL_'|| strSuffix ||
' as select plseqno, orderid,shipid,custid, ' ||
' lpid,fromlpid,plt_sscc18,'||
' link_plt_sscc18, sum(cartons) cartons, length, width, height ' ||
'  from ship_nt_945_id_' || strSuffix ||
'  group by plseqno,orderid,shipid,custid,lpid,fromlpid,plt_sscc18,'||
'  link_plt_sscc18, length, width, height ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



debugmsg('creating 945 pl mm');
cmdSql := 'create view SHIP_NT_945_PL_MM_'|| strSuffix ||
' as select plseqno, seqno, item,lotnumber,link_lotnumber,orderid,shipid,'||
          ' custid,lpid,fromlpid,plt_sscc18,link_plt_sscc18,'||
          ' sum(cartons) cartons ' ||
'  from ship_nt_945_id_mm_' || strSuffix ||
'  group by plseqno,seqno,item,lotnumber,link_lotnumber,orderid,shipid,'||
           'custid,lpid,fromlpid,plt_sscc18,link_plt_sscc18 ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



if in_orderid != 0 then
  debugmsg('by order ' || in_orderid || '-' || in_shipid);
  for oh in curOrderHdr
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_cnt_rows(oh);
  end loop;
elsif in_loadno != 0 then
  debugmsg('by loadno ' || in_loadno);
  for oh in curOrderHdrByLoad
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_cnt_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
  debugmsg('by date ' || in_begdatestr || '-' || in_enddatestr);
  begin
    dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -1;
    out_msg := 'Invalid begin date string ' || in_begdatestr;
    return;
  end;
  begin
    dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
  exception when others then
    out_errorno := -2;
    out_msg := 'Invalid end date string ' || in_enddatestr;
    return;
  end;
  for oh in curOrderHdrByShipDate
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
    add_945_cnt_rows(oh);
  end loop;
end if;


exception when others then
  out_msg := 'zimeidc945 ' || sqlerrm;
  out_errorno := sqlcode;

end; -- extract_by_id_contents;


begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'SHIP_NT_945_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;
ppCnt := 0;

  l_condition := null;

  if in_orderid != 0 then
     l_condition := ' and oh.orderid = '||to_char(in_orderid)
                 || ' and oh.shipid = '||to_char(in_shipid)
                 || ' ';
     for oh in curOrderHdr
     loop
       debugmsg('ord ' || oh.orderid);
       verify_caselabels(oh);
     end loop;
  elsif in_loadno != 0 then
     l_condition := ' and oh.loadno = '||to_char(in_loadno)
                 || ' ';
     debugmsg('trying curOrderHdrByLoad');
     for oh in curOrderHdrByLoad
     loop
       debugmsg('lod ' || oh.orderid);
       verify_caselabels(oh);
     end loop;
  elsif in_begdatestr is not null then
     l_condition :=  ' and oh.statusupdate >= to_date(''' || in_begdatestr
                 || ''', ''yyyymmddhh24miss'')'
                 ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
                 || ''', ''yyyymmddhh24miss'') ';
     begin
       dteTest := to_date(in_begdatestr,'yyyymmddhh24miss');
     exception when others then
       out_errorno := -1;
       out_msg := 'Invalid begin date string vc ' || in_begdatestr;
       return;
     end;
     begin
       dteTest := to_date(in_enddatestr,'yyyymmddhh24miss');
     exception when others then
       out_errorno := -2;
       out_msg := 'Invalid end date string vc ' || in_enddatestr;
       return;
     end;
     for oh in curOrderHdrByShipDate
      loop
       debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
       verify_caselabels(oh);
     end loop;
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  l_condition := l_condition || ' and oh.custid = '''||in_custid||'''';

  debugmsg('Condition = '||l_condition);


  -- Create header view
cmdSql := 'create view ship_nt_945_hdr_' || strSuffix ||
  ' (custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
  'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
  'width,length,shiptoidcode,'||
  'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
  'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
  'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,'||
  'reportingcode,'||
  'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
  'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
  'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
  'depositor_name,depositor_id,'||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
  'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
  'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
  'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
  'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
  'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
  'shippingcost, prono_or_all_trackingnos, shipfromaddr1, shipfromcity, ' ||
  'shipfromstate, shipfrompostalcode, shipfromcountrycode, ' ||
  'customername, customeraddr1, customeraddr2, customercity, customerstate, ' ||
  'customerpostalcode, customercountrycode, totqtyshipped, totqtyordered, ' ||
  'qtydifference, ' ||
  'cancelafter, deliveryrequested, requestedship, shipnotbefore, shipnolater, ' ||
  'cancelifnotdelivdby, donotdeliverafter, donotdeliverbefore, cancelleddate, ' ||
  'vicsbol, vicssubbol, ordercount ) '||
  'as select ' ||
  'oh.custid,'' '','' '',oh.loadno,oh.orderid,oh.shipid,oh.reference,';
if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
  ' nvl(oh.prono,nvl(l.prono,nvl(oh.billoflading,nvl(L.billoflading,'||
  'to_char(orderid) || ''-'' || to_char(shipid)))))),';
else
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
  ' nvl(oh.prono,nvl(l.prono,to_char(orderid) || ''-'' || to_char(shipid)))),';
end if;
cmdSql := cmdSql ||
  'oh.statusupdate,oh.shipdate,nvl(deliveryservice,''OTHR''),'||
  'zim7.sum_shipping_weight(orderid,shipid),'||
  'zim7.sum_shipping_weight(orderid,shipid) / 2.2046,'||
  'zim7.sum_shipping_weight(orderid,shipid) / .0022046,'||
  'zim7.sum_shipping_weight(orderid,shipid) * 16,'||
  'substr(zoe.max_shipping_container(orderid,shipid),1,15),'||
  'zoe.cartontype_height(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_width(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_length(zoe.max_cartontype(orderid,shipid)),'||
  'oh.shipto,'||
  'decode(CN.consignee,null,shiptoname,CN.name),'||
  'decode(CN.consignee,null,shiptocontact,CN.contact),'||
  'decode(CN.consignee,null,shiptoaddr1,CN.addr1),'||
  'decode(CN.consignee,null,shiptoaddr2,CN.addr2),'||
  'decode(CN.consignee,null,shiptocity,CN.city),'||
  'decode(CN.consignee,null,shiptostate,CN.state),'||
  'decode(CN.consignee,null,shiptopostalcode,CN.postalcode),'||
  'decode(CN.consignee,null,shiptocountrycode,CN.countrycode),'||
  'decode(CN.consignee,null,shiptophone,CN.phone),'||
  'oh.carrier,ca.name,'||
  '''  '',oh.hdrpassthruchar06,oh.shiptype,oh.shipterms,''A'','||
  'oh.reference,oh.po,oh.hdrpassthruchar07,'||
  'to_char(oh.arrivaldate,''YYYYMMDD''),'||
  'decode(nvl(oh.loadno,0),0,to_char(oh.orderid)||''-''||to_char(oh.shipid),'||
  'nvl(oh.billoflading,nvl(L.billoflading,to_char(oh.orderid)||''-''||to_char(oh.shipid)))),'||
  'nvl(oh.prono,L.prono),'||
  'decode(zim7.load_orders(L.loadno), ''Y'',L.loadno,null),'||
  'decode(zim7.split_shipment(oh.custid, oh.reference),''Y'',oh.reference,null),'||
  'to_char(oh.dateshipped,''YYYYMMDD''),'||
  'to_char(oh.dateshipped,''HHMISS''),oh.qtyship,'||
  'zim7.sum_shipping_weight(orderid,shipid),''LB'',oh.cubeship,''CF'',0,''CT'','||
  'F.name,F.facility,C.name,'' '','||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
  'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
  'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
  'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
  'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,'||
  'HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,' ||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,' ||
  'L.trailer,L.seal,'||
  'zim7.pallet_count(oh.loadno,oh.custid,oh.fromfacility,oh.orderid,oh.shipid), ';
if rtrim(in_ltl_freight_passthru) is not null then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'zim14.freight_total(oh.orderid,oh.shipid,null,null),oh.'||
  in_ltl_freight_passthru || ') ';
else
  cmdSql := cmdSql || 'zim14.freight_total(oh.orderid,oh.shipid,null,null) ';
end if;

cmdSql := cmdSql || ', '' '', OH.carrier||OH.deliveryservice,'
 ||' '' '', ';
-- ||'OH.shippingcost, ';

if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  ' '' '', ' ||
--  'substr(zoe.order_trackingnos(oh.orderid,oh.shipid),1,1000),'||
  ' nvl(oh.prono,nvl(l.prono,nvl(oh.billoflading,nvl(L.billoflading,'||
  'to_char(orderid) || ''-'' || to_char(shipid)))))), ';
else
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  ' '' '' , ' ||
--  'substr(zoe.order_trackingnos(oh.orderid,oh.shipid),1,1000),'||
  ' nvl(oh.prono,nvl(l.prono,to_char(orderid) || ''-'' || to_char(shipid)))), ';
end if;
  cmdSql := cmdSql || 'F.addr1, F.city, F.state, ' ||
  'F.postalcode, F.countrycode, C.name, C.addr1, ' ||
  'C. addr2, C.city, C.state, C.postalcode, C.countrycode, ' ||
  'OH.qtyship, OH.qtyorder, OH.qtyorder - OH.qtyship, ' ||
  'OH.cancel_after, OH.delivery_requested, OH.requested_ship, OH.ship_not_before, ' ||
  'OH.ship_no_later, OH.cancel_if_not_delivered_by, OH.do_not_deliver_after, ' ||
  'OH.do_not_deliver_before, OH.cancelled_date, ' ||
  'zim7wb.VICSChkDigit(SUBSTR(NVL(SUBSTR(C.ManufacturerUCC,1,7), ''0400000'')  ||  ' ||
  'LPAD(L.LoadNo,9,''0''),1,17)), '  ||
  'zim7wb.VICSChkDigit(SUBSTR(NVL(SUBSTR(C.ManufacturerUCC,1,7), ''0400000'')  ||  ' ||
  'LPAD( ' ||
  'OH.orderid||OH.shipid,9,''0''),1,17)), ' ||
  '(select count(*) from orderhdr oh where oh.orderstatus = ''9'' ' ||
  l_condition || ')';


cmdSql := cmdSql ||
  ' from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
  ' and oh.carrier = ca.carrier(+) '||
  ' and oh.loadno = L.loadno(+) ' ||
  ' and oh.fromfacility = F.facility(+) '||
  ' and oh.custid = C.custid(+) ' ||
  ' and oh.shipto = CN.consignee(+) ' ||
  l_condition;
-- debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
 /*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
 */

cntRows := dbms_sql.execute(curFunc);
debugmsg('-----Row count after hdr create:' || cntRows);
dbms_sql.close_cursor(curFunc);

    extract_by_id_contents();


if cu.linenumbersyn = 'Y' then
  debugmsg('perform extract by line numbers');
  extract_by_line_numbers;
  goto finish_shipnote945;
end if;

-- Create LXD View
cmdSql := 'create view ship_nt_945_lxd_' || strSuffix ||
 '(orderid,shipid,custid,assignedid) '||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10 '||
 ' from orderdtl d, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 '  and oh.orderid = d.orderid '||
 ' and oh.shipid = d.shipid ';
if upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'N' then
  cmdSql := cmdSql || ' and nvl(d.qtyship,0) <> 0 ';
end if;
cmdSql := cmdSql || l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


-- Create Detail View
cmdSql := 'create view ship_nt_945_dtl_' || strSuffix ||
 '(orderid,shipid,custid,assignedid,shipticket,trackingno,servicecode,'||
 'lbs,kgs,gms,ozs,item,lotnumber,link_lotnumber,inventoryclass,'||
 'statuscode,reference,linenumber,orderdate,po,qtyordered,qtyshipped,'||
 'qtydiff,uom,packlistshipdate,weight,weightquaifier,weightunit,' ||
 'description,upc'||
 ',DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03' ||
 ',DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07' ||
 ',DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11' ||
 ',DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15' ||
 ',DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19' ||
 ',DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03' ||
 ',DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07' ||
 ',DTLPASSTHRUNUM08,DTLPASSTHRUNUM09, '||
' DTLPASSTHRUNUM10,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,DTLPASSTHRUDATE03,' ||
' DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02, FROMLPID, smallpackagelbs ,' ||
' deliveryservice, entereduom, qtyshippedeuom)' ||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10,'||
 'substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15),'||
 'decode(nvl(ca.multiship,''N''),''Y'','||
 '  substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
 ' nvl(oh.prono,to_char(oh.orderid) || ''-'' || to_char(oh.shipid))),'||
 'nvl(oh.deliveryservice,''OTHR''),nvl(d.weightship,0)'||
 ',nvl(d.weightship,0) / 2.2046,nvl(d.weightship,0) / .0022046,' ||
 'nvl(d.weightship,0) * 16,'||
 'd.item,d.lotnumber,nvl(d.lotnumber,''(none)''),d.inventoryclass,'||
 'decode(D.linestatus, ''X'',''CU'','||
 'decode(nvl(d.qtyship,0), 0,''DS'','||
        'decode(zim7.split_item(oh.custid,oh.reference,d.item),'||
                '''Y'',''SS'','||
         'decode(zim7.changed_qty(oh.orderid,oh.shipid,'||
                                  'd.item,d.lotnumber),'||
            '''Y'',''PR'',''CC'')))),'||
 'oh.reference,'||
 'nvl(d.dtlpassthruchar13,''000000''),oh.entrydate,oh.po,d.qtyentered,'||
 'nvl(d.qtyship,0),'||
 'nvl(d.qtyship,0) - d.qtyentered,d.uom,oh.packlistshipdate,'||
 'nvl(d.weightship,0),''G'','||
 '''L'', nvl(d.dtlpassthruchar10,i.descr), nvl(D.dtlpassthruchar09,U.upc) ' ||
 ',D.DTLPASSTHRUCHAR01,D.DTLPASSTHRUCHAR02,D.DTLPASSTHRUCHAR03' ||
 ',D.DTLPASSTHRUCHAR04,D.DTLPASSTHRUCHAR05,D.DTLPASSTHRUCHAR06,D.DTLPASSTHRUCHAR07' ||
 ',D.DTLPASSTHRUCHAR08,D.DTLPASSTHRUCHAR09,D.DTLPASSTHRUCHAR10,D.DTLPASSTHRUCHAR11' ||
 ',D.DTLPASSTHRUCHAR12,D.DTLPASSTHRUCHAR13,D.DTLPASSTHRUCHAR14,D.DTLPASSTHRUCHAR15' ||
 ',D.DTLPASSTHRUCHAR16,D.DTLPASSTHRUCHAR17,D.DTLPASSTHRUCHAR18,D.DTLPASSTHRUCHAR19' ||
 ',D.DTLPASSTHRUCHAR20,D.DTLPASSTHRUNUM01,D.DTLPASSTHRUNUM02,D.DTLPASSTHRUNUM03' ||
 ',D.DTLPASSTHRUNUM04,D.DTLPASSTHRUNUM05,D.DTLPASSTHRUNUM06,D.DTLPASSTHRUNUM07' ||
 ',D.DTLPASSTHRUNUM08,D.DTLPASSTHRUNUM09,D.DTLPASSTHRUNUM10, '||
 ' D.DTLPASSTHRUDATE01,D.DTLPASSTHRUDATE02,D.DTLPASSTHRUDATE03,D.DTLPASSTHRUDATE04,' ||
 ' D.DTLPASSTHRUDOLL01,D.DTLPASSTHRUDOLL02, ''000000000000000'',0,oh.deliveryservice, ' ||
 ' D.uomentered, zcu.equiv_uom_qty (D.custid,D.item,D.uom,D.qtyship,D.uomentered)' ||
 ' from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = d.orderid '||
 ' and oh.shipid = d.shipid '||
 ' and oh.carrier = ca.carrier(+) '||
 ' and d.custid = i.custid(+) '||
 ' and d.item = i.item(+) '||
 ' and d.custid = U.custid(+) '||
 ' and d.item = U.item(+) ';
if upper(nvl(in_include_zero_qty_lines_yn,'Y')) = 'N' then
  cmdSql := cmdSql || ' and nvl(d.qtyship,0) <> 0 ';
end if;
cmdSql := cmdSql || l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


  -- Create man (sscc18 view)
cmdSql := 'create view ship_nt_945_s18_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber,link_lotnumber,sscc18) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, nvl(s.lotnumber,''(none)''),s.barcode '||
 'from caselabels s, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.barcode is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

  -- Create man (serial number view)
cmdSql := 'create view ship_nt_945_man_' || strSuffix ||
 '(orderid,shipid,custid,assignedid,item,lotnumber,link_lotnumber,' ||
 ' serialnumber,dtlpassthruchar01) '||
 ' as select s.orderid,s.shipid,s.custid,d.dtlpassthrunum10,s.item,'||
 ' s.lotnumber, nvl(s.lotnumber,''(none)''),s.serialnumber, ' ||
 ' d.dtlpassthruchar01 '||
 'from shippingplate s, orderhdr oh, orderdtl d ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and d.orderid = s.orderid' ||
 ' and d.shipid = s.shipid' ||
 ' and d.item = s.item' ||
 ' and nvl(d.lotnumber,''(none)'') = nvl(s.lotnumber,''(none)'')'||
 ' and s.status||'''' = ''SH'''||
 ' and s.serialnumber is not null'||
 l_condition;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);

  -- Create lot view
debugmsg('create lot view');
cmdSql := 'create view ship_nt_945_lot_' || strSuffix ||
 '(orderid,shipid,custid,item,lotnumber,link_lotnumber,qtyshipped,qtyordered,qtydiff) '||
 ' as select s.orderid,s.shipid,s.custid,s.item,'||
 ' s.lotnumber, nvl(s.orderlot,''(none)''),sum(s.quantity),sum(s.quantity),0 '||
 'from shippingplate s, orderhdr oh ';
if upper(nvl(in_include_cancelled_orders_yn,'Y')) <> 'Y' then
  cmdSql := cmdSql || ' where oh.orderstatus = ''9'' ';
else
  cmdSql := cmdSql || ' where oh.orderstatus in (''9'',''X'') ';
end if;
cmdSql := cmdSql ||
 ' and oh.orderid = s.orderid'||
 ' and oh.shipid = s.shipid'||
 ' and s.status||'''' = ''SH'''||
 ' and s.type in (''F'',''P'') '||
 l_condition  ||
' group by s.orderid,s.shipid,s.custid,s.item,'||
' s.lotnumber, nvl(s.orderlot,''(none)'') ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/

cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


<< finish_shipnote945 >>

debugmsg('create ship hd view');
cmdSql := 'create view ship_nt_945_hd_' || strSuffix ||
' (custid,company,warehouse,loadno,orderid,shipid,reference,hdr_trackingno,dateshipped'
||' ,commitdate,shipviacode,hdr_lbs,hdr_kgs,hdr_gms,hdr_ozs,hdr_shipticket,height'
||' ,width,length,shiptoidcode,shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,shiptocity'
||' ,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,carrier,carrier_name'
||' ,packlistshipdate,routing,shiptype,shipterms,reportingcode,depositororder,po'
||' ,deliverydate,estdelivery,billoflading,prono,masterbol,splitshipno,invoicedate'
||' ,effectivedate,totalunits,totalweight,uomweight,totalvolume,uomvolume,ladingqty'
||' ,hdr_uom,warehouse_name,warehouse_id,depositor_name,depositor_id'
||' ,HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,HDRPASSTHRUCHAR05'
||' ,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10'
||' ,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15'
||' ,HDRPASSTHRUCHAR16,HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20'
||' ,HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,HDRPASSTHRUNUM05'
||' ,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,HDRPASSTHRUNUM09,HDRPASSTHRUNUM10'
||' ,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01'
||' ,HDRPASSTHRUDOLL02,trailer,seal,palletcount,freightcost,assignedid,shipticket,trackingno'
||' ,servicecode,lbs,kgs,gms,ozs,item,lotnumber,link_lotnumber,statuscode,linenumber'
||' ,orderdate,qtyordered,qtyshipped,qtydiff,uom,weight,weightquaifier,weightunit'
||' ,description,upc,DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04'
||' ,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09'
||' ,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14'
||' ,DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19'
||' ,DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04'
||' ,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09'
||' ,DTLPASSTHRUNUM10,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,DTLPASSTHRUDATE03,DTLPASSTHRUDATE04'
||' ,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,fromlpid,smallpackagelbs,deliveryservice)'
||' as select hdr.custid,company,warehouse,loadno,hdr.orderid,hdr.shipid,hdr.reference'
||' ,hdr.trackingno,dateshipped,commitdate,shipviacode,hdr.lbs,hdr.kgs,hdr.gms,hdr.ozs'
||' ,hdr.shipticket,height,width,length,shiptoidcode,shiptoname,shiptocontact,shiptoaddr1'
||' ,shiptoaddr2,shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone'
||' ,carrier,carrier_name,hdr.packlistshipdate,routing,shiptype,shipterms,reportingcode'
||' ,depositororder,hdr.po,deliverydate,estdelivery,billoflading,prono,masterbol'
||' ,splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,totalvolume'
||' ,uomvolume,ladingqty,hdr.uom,warehouse_name,warehouse_id,depositor_name,depositor_id'
||' ,HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,HDRPASSTHRUCHAR05'
||' ,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10'
||' ,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15'
||' ,HDRPASSTHRUCHAR16,HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20'
||' ,HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,HDRPASSTHRUNUM05'
||' ,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,HDRPASSTHRUNUM09,HDRPASSTHRUNUM10'
||' ,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01'
||' ,HDRPASSTHRUDOLL02,trailer,seal,palletcount,freightcost,assignedid,dtl.shipticket'
||' ,dtl.trackingno,servicecode,dtl.lbs,dtl.kgs,dtl.gms,dtl.ozs,item,lotnumber,link_lotnumber'
||' ,statuscode,linenumber,orderdate,qtyordered,qtyshipped,hdr.qtydifference,dtl.uom,weight'
||' ,weightquaifier,weightunit,description,upc,DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02'
||' ,DTLPASSTHRUCHAR03,DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07'
||' ,DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11,DTLPASSTHRUCHAR12'
||' ,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15,DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17'
||' ,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19,DTLPASSTHRUCHAR20,DTLPASSTHRUNUM01,DTLPASSTHRUNUM02'
||' ,DTLPASSTHRUNUM03,DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07'
||' ,DTLPASSTHRUNUM08,DTLPASSTHRUNUM09,DTLPASSTHRUNUM10,DTLPASSTHRUDATE01,DTLPASSTHRUDATE02'
||' ,DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,fromlpid'
||' ,smallpackagelbs,deliveryservice from ship_nt_945_dtl_' || strSuffix
||' dtl, ship_nt_945_hdr_' || strSuffix || ' hdr'
||' where hdr.orderid = dtl.orderid  and hdr.shipid = dtl.shipid ';
-- debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);



cmdSql := 'create view ship_nt_945_trl_' || strSuffix ||
' (orderid,shipid,custid,hdr_count,dtl_count,lot_count,lxd_count,man_count,s18_count) as '||
' select orderid, shipid,custid,'||
' (select count(1) from ship_nt_945_hdr_'||strSuffix||'),'||
' (select count(1) from ship_nt_945_dtl_'||strSuffix||'),'||
' (select count(1) from ship_nt_945_lot_'||strSuffix||'),'||
' (select count(1) from ship_nt_945_lxd_'||strSuffix||'),'||
' (select count(1) from ship_nt_945_man_'||strSuffix||'),'||
' (select count(1) from ship_nt_945_s18_'||strSuffix||') '||
' from ship_nt_945_hdr_'||strSuffix;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn945 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_shipnote945weber;


procedure end_shipnote945weber
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cmdSql varchar2(255);
strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

for obj in (select object_name, object_type
              from user_objects
             where object_name like 'SHIP_NT_945_%_' || strSuffix
               and object_name != 'SHIP_NT_945_HDR_' || strSuffix )
loop

  cmdSql := 'drop ' || obj.object_type || ' ' || obj.object_name;

  execute immediate cmdSql;

end loop;

cmdsql := 'drop view SHIP_NT_945_HDR_' || strSuffix;
execute immediate cmdSql;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn945 ' || sqlerrm;
  out_errorno := sqlcode;
end end_shipnote945weber;

FUNCTION find_po
(in_lpid IN varchar2
) return varchar2
IS
l_po plate.po%type;

BEGIN

    l_po := null;

    select po
      into l_po
      from allplateview
     where lpid = in_lpid;

    return l_po;

EXCEPTION WHEN OTHERS THEN
    return null;
END find_po;

FUNCTION VICSChkDigit
           (in_Data in varchar2)
           RETURN varchar2 IS
         OutData varchar2(17);

VarData varchar2 (16);
VarNumber number;

BEGIN

      VarData := NULL;

                IF LENGTH(in_Data) <> 16 THEN
          zut.prt(substr('Invalid Field length' || length(in_data),1,60));
                         OutData := '99999999999999999';

                         RETURN OutData;

                END IF;

--This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
VarNumber := TO_NUMBER(SUBSTR(in_Data,1,7));

--This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
VarNumber := TO_NUMBER(SUBSTR(in_Data,8,9));

VarNumber := 10 - MOD(TO_NUMBER(SUBSTR(TRIM(in_Data),1,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),2,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),3,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),4,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),5,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),6,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),7,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),8,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),9,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),10,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),11,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),12,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),13,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),14,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),15,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),16,1)) * 3,10);

IF VarNumber = 10 THEN

                                  VarNumber := 0;

                         END IF;

OutData := in_Data || TO_CHAR(VarNumber);

RETURN OutData;


EXCEPTION
                 WHEN OTHERS THEN

                 RETURN '99999999999999999';

END VICSChkDigit;

function pallet_count
(in_loadno IN number
,in_custid IN varchar2
,in_facility IN varchar2
,in_orderid IN number
,in_shipid IN number
) return integer

is
out_pallet_count integer;
begin
out_pallet_count := 0;
if nvl(in_orderid,0) = 0 then
  select sum(nvl(outpallets,0))
    into out_pallet_count
    from pallethistory
   where loadno = in_loadno
     and custid = in_custid
     and facility = in_facility
     and not (pallettype='WRAP' or pallettype='WRAPINBOUND');
else
  select sum(nvl(outpallets,0))
    into out_pallet_count
    from pallethistory
   where loadno = in_loadno
     and custid = in_custid
     and facility = in_facility
     and orderid = in_orderid
     and shipid = in_shipid
     and not (pallettype='WRAP' or pallettype='WRAPINBOUND');
end if;
return nvl(out_pallet_count,0);
exception when others then
  return 0;
end;
end zimportproc7weber;
/
show error package body zimportproc7weber;
exit;



