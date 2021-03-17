create or replace package body alps.zimportproc5 as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure damaged_on_arrival
(in_DmgInStr IN varchar2
,in_fromlpid IN varchar2
,out_doa_yn OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
cntDamaged integer;

begin

cntDamaged := 0;

cmdSql := 'select count(1) as dmgcount from orderdtlrcpt where lpid = ''' ||
  in_fromlpid || ''' and invstatus ' || zcm.in_str_clause('I', in_DmgInStr);

curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
dbms_sql.define_column(curSql,1,cntDamaged);
cntRows := dbms_sql.execute(curSql);
cntRows := dbms_sql.fetch_rows(curSql);
if cntRows <= 0 then
  cntDamaged := 0;
else
  dbms_sql.column_value(curSql,1,cntDamaged);
end if;
dbms_sql.close_cursor(curSql);

if cntDamaged = 0 then
  out_doa_yn := 'N';
else
  out_doa_yn := 'Y';
end if;

exception when others then
  out_doa_yn := 'N';
end damaged_on_arrival;

procedure begin_I9_rcpt_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = 'R'
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByReceiptDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = 'R'
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = 'R'
     and loadno = in_loadno;

cursor curOrderDtlRcpt(in_orderid number,in_shipid number) is
  select orderitem,
         orderlot,
         item,
         lotnumber,
         inventoryclass,
         invstatus,
         sum(qtyrcvd) as qtyrcvd
    from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
   group by orderitem,orderlot,item,lotnumber,inventoryclass,invstatus;

cursor curOrderDtl(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
od curOrderDtl%rowtype;

cursor curLoads is
  select carrier
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
dteTest date;
strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strDescr orderstatus.descr%type;
strUnStatus orderstatus.abbrev%type;
strDmgStatus orderstatus.abbrev%type;
strRcptParm orderstatus.abbrev%type;
strMovement orderstatus.abbrev%type;
strReason orderstatus.abbrev%type;
strCarrier loads.carrier%type;
prm licenseplatestatus%rowtype;

procedure add_dtl_rows(oh orderhdr%rowtype) is
begin
  zmi3.get_cust_parm_value(oh.custid,'REGORDTYPES',prm.descr,prm.abbrev);
  if instr(prm.abbrev,oh.ordertype) <> 0 then
    for rc in curOrderDtlRcpt(oh.orderid,oh.shipid)
    loop
      zmi3.get_whse(oh.custid,rc.inventoryclass,strWhse,strRegWhse,strRetWhse);
      if strWhse is null then
        goto continue_loop;
      end if;
      zmi3.get_cust_parm_value(oh.custid,'UNSTATUS',strDescr,strUnStatus);
      if instr(strUnStatus,rc.invstatus) != 0 then
        strRcptParm := 'GR-UNRESTRCT';
      else
        strRcptParm := 'GR-OTHER';
      end if;
      zmi3.get_whse_parm_value(oh.custid,strWhse,strRcptParm,strDescr,strMovement);
      if strMovement is null then
        goto continue_loop;
      end if;
      od := null;
      open curOrderDtl(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot);
      fetch curOrderDtl into od;
      close curOrderDtl;
      if oh.loadno != 0 then
        ld := null;
        open curLoads;
        fetch curLoads into ld;
        close curLoads;
        strCarrier := nvl(ld.carrier,oh.carrier);
      else
        strCarrier := oh.carrier;
      end if;
      strReason := 'NA';
      if strRcptParm = 'GR-OTHER' then
        zmi3.get_cust_parm_value(oh.custid,'DMGSTATUS',strDescr,strDmgStatus);
        if instr(strDmgStatus,rc.invstatus) != 0 then
          strReason := '0001';
        end if;
      end if;
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, 'insert into i9_rcpt_note_dtl_' || strSuffix ||
        ' values (:custid,:loadno,:orderid,:shipid,:orderitem,:orderlot,' ||
        ':po,:linenumber,:carrier,:billoflading,:receiptdate,:movement,:reason,' ||
        ':item,:whse,:qtyrcvd)',
        dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':custid', oh.custid);
      dbms_sql.bind_variable(curSql, ':loadno', oh.loadno);
      dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
      dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
      dbms_sql.bind_variable(curSql, ':orderitem', rc.orderitem);
      dbms_sql.bind_variable(curSql, ':orderlot', rc.orderlot);
      dbms_sql.bind_variable(curSql, ':po', oh.po);
      dbms_sql.bind_variable(curSql, ':linenumber', od.dtlpassthrunum10);
      dbms_sql.bind_variable(curSql, ':carrier', strCarrier);
      dbms_sql.bind_variable(curSql, ':billoflading', oh.billoflading);
      dbms_sql.bind_variable(curSql, ':receiptdate', oh.statusupdate);
      dbms_sql.bind_variable(curSql, ':movement', strMovement);
      dbms_sql.bind_variable(curSql, ':reason', strReason);
      dbms_sql.bind_variable(curSql, ':item', rc.item);
      dbms_sql.bind_variable(curSql, ':whse', strWhse);
      dbms_sql.bind_variable(curSql, ':qtyrcvd', rc.qtyrcvd);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
    <<continue_loop>>
      null;
    end loop;
  end if;
end;

begin

out_errorno := 0;
out_msg := '';

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'I9_RCPT_NOTE_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cmdSql := 'create table I9_RCPT_NOTE_DTL_' || strSuffix ||
 ' (custid varchar2(10),loadno number(7),orderid number(9), ' ||
 ' shipid number(2),orderitem varchar2(50),orderlot varchar2(30), ' ||
 ' po varchar2(20),linenumber number(5),carrier varchar2(4), ' ||
 ' billoflading varchar2(40),receiptdate date,movement varchar2(12),reason varchar2(12), ' ||
 ' item varchar2(50),warehouse varchar2(12),qtyrcvd number(7) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create view I9_RCPT_NOTE_HDR_' || strSuffix ||
 ' (custid,loadno,orderid,shipid,orderitem,orderlot,po ' ||
 ' ,linenumber,carrier,billoflading,receiptdate,movement,reason) ' ||
 ' as select distinct custid,loadno,orderid,shipid,orderitem, ' ||
 ' orderlot,po,linenumber,carrier,billoflading,receiptdate,movement, ' ||
 ' reason from I9_rcpt_note_dtl_' || strSuffix;
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    add_dtl_rows(oh);
  end loop;
elsif in_loadno != 0 then
  for oh in curOrderHdrByLoad
  loop
    add_dtl_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
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
  for oh in curOrderHdrByReceiptDate
  loop
    add_dtl_rows(oh);
  end loop;
end if;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbi9rn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_I9_rcpt_note;

procedure end_I9_rcpt_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop view I9_RCPT_NOTE_HDR_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table I9_RCPT_NOTE_DTL_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zei9rn ' || sqlerrm;
  out_errorno := sqlcode;
end end_I9_rcpt_note;

procedure begin_I44_ship_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_cancelled_orders_yn IN varchar2
,in_count_lots_yn IN varchar2
,in_edi_orders_only_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdr_with_cancels is
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
     and orderstatus = '9'
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByShipDate_cancels is
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
     and orderstatus = '9'
     and loadno = in_loadno;

cursor curOrderHdrByLoad_with_cancels is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus in ('9','X')
     and loadno = in_loadno;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select custid
        ,orderid
        ,shipid
        ,item
        ,lotnumber
        ,uomentered
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
        ,UOM
        ,nvl(qtyorder,0) qtyorder
        ,nvl(qtyship,0) qtyship
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         substr(zim5.shipplate_rmatrackingno(nvl(parentlpid,lpid)),1,30) as rmatrackingno,
         substr(zedi.get_sscc18_code(oh.custid,decode(oh.shiptype,'S','0','1'), nvl(parentlpid,lpid)),1,20) as ucc128,
         sum(quantity) as qty
    from orderhdr oh, shippingplate sp
   where sp.orderid = in_orderid
     and sp.shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
     and sp.orderid = oh.orderid
     and sp.shipid = oh.shipid
   group by item,
            serialnumber,useritem1,useritem2,useritem3,
            substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            substr(zim5.shipplate_rmatrackingno(nvl(parentlpid,lpid)),1,30),
            substr(zedi.get_sscc18_code(oh.custid,decode(oh.shiptype,'S','0','1'), nvl(parentlpid,lpid)),1,20);
sp curShippingPlate%rowtype;

cursor curShippingPlateItem(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         max(serialnumber) as serialnumber,
         max(useritem1) as useritem1,
         max(useritem2) as useritem2,
         max(useritem3) as useritem3,
         max(substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30)) as trackingno,
         max(substr(zim5.shipplate_rmatrackingno(nvl(parentlpid,lpid)),1,30)) as rmatrackingno,
         max(substr(zedi.get_sscc18_code(oh.custid,decode(oh.shiptype,'S','0','1'), nvl(parentlpid,lpid)),1,20)) as ucc128,
         sum(quantity) as qty
    from orderhdr oh, ShippingPlate sp
   where sp.orderid = in_orderid
     and sp.shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
     and sp.orderid = oh.orderid
     and sp.shipid = oh.shipid
   group by item;

cursor curShippingPlateLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select sp.item,
         sp.serialnumber,
         sp.useritem1,
         sp.useritem2,
         sp.useritem3,
         substr(zmp.shipplate_trackingno(nvl(sp.parentlpid,sp.lpid)),1,30) as trackingno,
         substr(zim5.shipplate_rmatrackingno(nvl(sp.parentlpid,sp.lpid)),1,30) as rmatrackingno,
         substr(zedi.get_sscc18_code(oh.custid,
                  decode(nvl(trim(in_count_lots_yn),'N'),
                            'M', '?',
                            decode(oh.shiptype,'S','0','1')),
                  nvl(sp.parentlpid,sp.lpid)),1,20) ucc128,
         nvl(mp.quantity,0) mpqty,
         sum(sp.quantity) as qty
    from orderhdr oh, shippingplate sp, shippingplate mp
   where sp.orderid = in_orderid
     and sp.shipid = in_shipid
     and sp.orderitem = in_orderitem
     and nvl(sp.orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and sp.type in ('F','P')
     and sp.status = 'SH'
     and sp.orderid = oh.orderid
     and sp.shipid = oh.shipid
     and sp.parentlpid = mp.lpid(+)
   group by sp.item,
            sp.serialnumber,sp.useritem1,sp.useritem2,sp.useritem3,
            substr(zmp.shipplate_trackingno(nvl(sp.parentlpid,sp.lpid)),1,30),
            substr(zim5.shipplate_rmatrackingno(nvl(sp.parentlpid,sp.lpid)),1,30),
            substr(zedi.get_sscc18_code(oh.custid,
                  decode(nvl(trim(in_count_lots_yn),'N'),
                            'M', '?',
                            decode(oh.shiptype,'S','0','1')),
                  nvl(sp.parentlpid,sp.lpid)),1,20),
         nvl(mp.quantity,0)
   order by sp.item, mpqty desc,
            substr(zedi.get_sscc18_code(oh.custid,
                  decode(nvl(trim(in_count_lots_yn),'N'),
                            'M', '?',
                            decode(oh.shiptype,'S','0','1')),
                  nvl(sp.parentlpid,sp.lpid)),1,20);

cursor curShippingPlateLineOLD(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30) as trackingno,
         substr(zim5.shipplate_rmatrackingno(nvl(parentlpid,lpid)),1,30) as rmatrackingno,
         substr(zedi.get_sscc18_code(oh.custid,decode(oh.shiptype,'S','0','1'), nvl(parentlpid,lpid)),1,20) as ucc128,
         sum(quantity) as qty
    from orderhdr oh, shippingplate sp
   where sp.orderid = in_orderid
     and sp.shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
     and sp.orderid = oh.orderid
     and sp.shipid = oh.shipid
   group by item,
            serialnumber,useritem1,useritem2,useritem3,
            substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30),
            substr(zim5.shipplate_rmatrackingno(nvl(parentlpid,lpid)),1,30),
            substr(zedi.get_sscc18_code(oh.custid,decode(oh.shiptype,'S','0','1'), nvl(parentlpid,lpid)),1,20)
   order by item, qty desc, ucc128;
spli curShippingPlateLine%rowtype;

cursor curShippingPlateLot(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         lotnumber,
         max(serialnumber) as serialnumber,
         max(useritem1) as useritem1,
         max(useritem2) as useritem2,
         max(useritem3) as useritem3,
         max(substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30)) as trackingno,
         max(substr(zim5.shipplate_rmatrackingno(nvl(parentlpid,lpid)),1,30)) as rmatrackingno,
         max(substr(zedi.get_sscc18_code(oh.custid,decode(oh.shiptype,'S','0','1'), nvl(parentlpid,lpid)),1,20)) as ucc128,
         sum(quantity) as qty
    from orderhdr oh, ShippingPlate sp
   where sp.orderid = in_orderid
     and sp.shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
     and sp.orderid = oh.orderid
     and sp.shipid = oh.shipid
   group by item,lotnumber
   order by item,lotnumber;
spl curShippingPlateLot%rowtype;
prevspl curShippingPlateLot%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
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
         nvl(ol.uomentered, od.uomentered) as uomentered,
         nvl(ol.qtyentered, od.qtyentered) as qtyentered
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));

cursor curOrderDtlLineL(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2)
return curOrderDtlLine%rowtype
is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
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
         nvl(ol.uomentered, od.uomentered) as uomentered,
         nvl(ol.qtyentered, od.qtyentered) as qtyentered
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by 2 desc, nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));


ol curOrderDtlLine%rowtype;




cursor curLoad (in_loadno number) is
  select trailer,seal,carrier,billoflading,prono,shiptype
    from loads
   where loadno = in_loadno;
ld curLoad%rowtype;

cursor curPalletHistory (in_loadno number,in_custid varchar2,
                         in_facility varchar2) is
  select orderid,shipid,
         trim(pallettype) as pallettype,
         nvl(outpallets,0) as outpallets
    from pallethistory
   where loadno = in_loadno
     and custid = in_custid
     and facility = in_facility;
ph curPalletHistory%rowtype;

cursor curCustItem(in_custid varchar2,in_item varchar2) is
  select descr
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

cursor curCaseLabels(in_orderid number, in_shipid number,
              in_item varchar2, in_lotnumber varchar2)
is
  select *
    from caselabels
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl( in_lotnumber, '(none)')
   order by quantity desc, barcode;

csl curCaseLabels%rowtype;


curSql integer;
cntRows integer;
cntChep integer;
cntWhite integer;
cntTotPallet integer;
cntTotQty integer;
cntLot integer;
cntSequence integer;
cntPrevLineNumber integer;
cntPrevQtyOrder integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
strChepType pallethistory.pallettype%type;
strWhiteType pallethistory.pallettype%type;
cntView integer;
dteTest date;
strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strDescr orderstatus.descr%type;
strUnStatus orderstatus.abbrev%type;
strDmgStatus orderstatus.abbrev%type;
strshipParm orderstatus.abbrev%type;
strMovement orderstatus.abbrev%type;
strReason orderstatus.abbrev%type;
strCarrier loads.carrier%type;
qtyRemain shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
prm licenseplatestatus%rowtype;
dteNull date;
strEquiv_Uom varchar2(4);
intEquiv_Qty number(7);
strDebugYN char(1);
strTrackingNo shippingplate.trackingno%type;
strProNo orderhdr.prono%type;
strProNo_or_TrackingNo orderhdr.prono%type;
strDeliveryService varchar2(10);
strLine_Uom varchar2(4);
intLine_Qty number(7);

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

exception when others then
  null;
end;

procedure compute_equiv_data(in_od curOrderDtl%rowtype, in_qty number) is
begin

select
decode(
mod(zcu.equiv_uom_qty(in_od.custid,in_od.item,in_od.uom,in_qty,
substr(zim14.line_uomentered(in_od.orderid,in_od.shipid,in_od.item,in_od.lotnumber),1,4)),1),
0,substr(zim14.line_uomentered(in_od.orderid,in_od.shipid,in_od.item,in_od.lotnumber),1,4),
in_od.uom),
decode(
mod(zcu.equiv_uom_qty(in_od.custid,in_od.item,in_od.uom,in_qty,
substr(zim14.line_uomentered(in_od.orderid,in_od.shipid,in_od.item,in_od.lotnumber),1,4)),1),
0,zcu.equiv_uom_qty(in_od.custid,in_od.item,in_od.uom,in_qty,
substr(zim14.line_uomentered(in_od.orderid,in_od.shipid,in_od.item,in_od.lotnumber),1,4)),
in_qty)
into strEquiv_Uom, intEquiv_Qty
from dual;

exception when others then
  strEquiv_Uom := in_od.uom;
  intEquiv_Qty := in_qty;
end;

procedure compute_line_data(in_od curOrderDtl%rowtype,
    in_ol curOrderDtlLine%rowtype, in_qty number) is

begin

  strLine_Uom := in_ol.uomentered;
  intLine_Qty := in_qty;

select
decode(
mod(zcu.equiv_uom_qty(in_od.custid,in_od.item,in_od.uom,in_qty,
in_ol.uomentered),1),
    0,in_ol.uomentered,
    in_od.uom),
decode(
mod(zcu.equiv_uom_qty(in_od.custid,in_od.item,in_od.uom,in_qty,
in_ol.uomentered),1),
0,zcu.equiv_uom_qty(in_od.custid,in_od.item,in_od.uom,in_qty,
in_ol.uomentered),
in_qty)
into strLine_Uom, intLine_Qty
from dual;


exception when others then
  strLine_Uom := in_ol.uomentered;
  intLine_Qty := in_qty;
end;

procedure add_dtl_rows_by_line(oh orderhdr%rowtype) is
begin
  debugmsg('add_dtl_rows_by_line');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    debugmsg('od loop top');
    spli := null;
    debugmsg('open sp cursor for item ' || od.item);
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    open curShippingPlateLine(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateLine into spli;

    csl := null;

    open curCaseLabels(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curCaseLabels into csl;

    for ol in curOrderDtlLineL(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      debugmsg('ol loop top--ol line/qty is '  || ol.linenumber || ' ' ||ol.qty);
      qtyRemain := ol.qty;
      qtyLineNumber := 0;

    -- Check if there is enough shipped inventory for this order line
      if nvl(trim(in_count_lots_yn),'N') != 'M'
      or qtyRemain <= od.qtyship then

      od.qtyship := od.qtyship - qtyRemain;

      while (qtyRemain > 0)
      loop
        if spli.qty = 0 then
          fetch curShippingPlateLine into spli;
          if curShippingPlateLine%notfound then
            spli := null;
          end if;
        end if;
        debugmsg('spli.qty is ' || spli.qty || ' remain qty is ' || qtyRemain);
        if spli.item is null then
          exit;
        end if;
        if spli.qty >= qtyRemain then
          qtyLineNumber := qtyLineNumber + qtyRemain;
          spli.qty := spli.qty - qtyRemain;
          qtyRemain := 0;
        else
          qtyLineNumber := qtyLineNumber + spli.qty;
          qtyRemain := qtyRemain - spli.qty;
          spli.qty := 0;
        end if;
      end loop; -- shippingplate
      if qtyRemain <> ol.qty then
         curSql := dbms_sql.open_cursor;
         debugmsg('begin--add dtl row');
         compute_equiv_data(od,qtyLineNumber);
         compute_line_data(od,ol,qtyLineNumber);
         if rtrim(spli.trackingno) is null then
           strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
         else
           strProNo_or_TrackingNo := spli.trackingno;
         end if;

         if nvl(trim(in_count_lots_yn),'N') = 'M' then
            spli.ucc128 := csl.barcode;
            fetch curCaseLabels into csl;
            if curCaseLabels%notFound then
                csl := null;
            end if;

         end if;

         dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
           ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
           ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
           ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
           ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
           ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
           ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
           ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
           ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
           ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
           ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
           ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
           ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
           ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
           ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
           ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:ucc128,:line_uom,:line_qty'||
           ')',
           dbms_sql.native);
         dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
         dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
         dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
         dbms_sql.bind_variable(curSql, ':item', spli.item);
         dbms_sql.bind_variable(curSql, ':serialnumber', spli.serialnumber);
         dbms_sql.bind_variable(curSql, ':trackingno', spli.trackingno);
         dbms_sql.bind_variable(curSql, ':qty', qtyLineNumber);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
         dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
         dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
         dbms_sql.bind_variable(curSql, ':lotcount', 0);
         dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
         dbms_sql.bind_variable(curSql, ':EQUIV_UOM', strEquiv_Uom);
         dbms_sql.bind_variable(curSql, ':EQUIV_QTY', intEquiv_Qty);
         dbms_sql.bind_variable(curSql, ':USERITEM1', spli.useritem1);
         dbms_sql.bind_variable(curSql, ':USERITEM2', spli.useritem2);
         dbms_sql.bind_variable(curSql, ':USERITEM3', spli.useritem3);
         dbms_sql.bind_variable(curSql, ':QTYORDER', ol.qty);
         dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
         dbms_sql.bind_variable(curSql, ':rmatrackingno', spli.rmatrackingno);
         dbms_sql.bind_variable(curSql, ':ucc128', spli.ucc128);
         dbms_sql.bind_variable(curSql, ':LINE_UOM', strLine_Uom);
         dbms_sql.bind_variable(curSql, ':LINE_QTY', intLine_Qty);
         cntRows := dbms_sql.execute(curSql);
         debugmsg('end--add dtl row');
         dbms_sql.close_cursor(curSql);
      end if;

      end if; -- 'M' check for caselabels usage

      if qtyRemain = ol.qty then
        debugmsg('add zero line');
        strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
          ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
          ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
          ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
          ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
          ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
          ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
          ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
          ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
          ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
          ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
          ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:UCC128,:line_uom,:line_qty'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
        dbms_sql.bind_variable(curSql, ':item', od.item);
        dbms_sql.bind_variable(curSql, ':serialnumber','');
        dbms_sql.bind_variable(curSql, ':trackingno','');
        dbms_sql.bind_variable(curSql, ':qty', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
        dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
        dbms_sql.bind_variable(curSql, ':lotcount', 0);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', od.uomentered);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', 0);
        dbms_sql.bind_variable(curSql, ':USERITEM1', '');
        dbms_sql.bind_variable(curSql, ':USERITEM2', '');
        dbms_sql.bind_variable(curSql, ':USERITEM3', '');
        dbms_sql.bind_variable(curSql, ':QTYORDER', ol.qty);
        dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
        dbms_sql.bind_variable(curSql, ':rmatrackingno','');
        dbms_sql.bind_variable(curSql, ':ucc128','');
        dbms_sql.bind_variable(curSql, ':LINE_UOM', od.uomentered);
        dbms_sql.bind_variable(curSql, ':LINE_QTY', 0);
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
      end if;
    end loop; -- orderdtlline
    close curShippingPlateLine;
    close curCaseLabels;
  end loop; -- orderdtl
end;

procedure add_dtl_rows_by_lot(oh orderhdr%rowtype) is
begin
  debugmsg('add_dtl_rows_by_lot');
  dteNull := null;
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    spl := null;
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    open curShippingPlateLot(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateLot into spl;
    prevspl := spl;
    cntLot := 0;
    cntTotQty := 0;
    cntSequence := 1;
    cntPrevLineNumber := -1;
    cntPrevQtyOrder := 0;
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      if cntPrevLineNumber <> -1 then
        if cntLot = 0 then
          curSql := dbms_sql.open_cursor;
          debugmsg('add zero qty row lot');
          dbms_sql.parse(curSql, 'insert into I44_ship_note_lot_' || strSuffix ||
            ' values (:orderid,:shipid,:item,:linenumber,:sequence,:lotnumber,:qty,'||
            ':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
            ':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
            ':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
            ':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
            ':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
            ':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
            ':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
            ':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
            ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
            ':EQUIV_UOM,:EQUIV_QTY,:UOM,:USERITEM1,:USERITEM2,:USERITEM3'||
            ')',
            dbms_sql.native);
          dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
          dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
          dbms_sql.bind_variable(curSql, ':item', od.item);
          dbms_sql.bind_variable(curSql, ':linenumber', cntPrevlinenumber);
          dbms_sql.bind_variable(curSql, ':sequence', 1);
          dbms_sql.bind_variable(curSql, ':lotnumber', '');
          dbms_sql.bind_variable(curSql, ':qty', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', '');
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', dteNull);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', dteNull);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', dteNull);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', dteNull);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', 0);
          dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', 0);
          dbms_sql.bind_variable(curSql, ':EQUIV_UOM', od.uomentered);
          dbms_sql.bind_variable(curSql, ':EQUIV_QTY', 0);
          dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
          dbms_sql.bind_variable(curSql, ':USERITEM1', '');
          dbms_sql.bind_variable(curSql, ':USERITEM2', '');
          dbms_sql.bind_variable(curSql, ':USERITEM3', '');
          cntRows := dbms_sql.execute(curSql);
          dbms_sql.close_cursor(curSql);
        end if;
        debugmsg('add zero qty row dtl1');
        compute_equiv_data(od,cntTotQty);
        compute_line_data(od,ol,cntTotQty);
        if rtrim(prevspl.trackingno) is null then
          strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
        else
          strProNo_or_TrackingNo := prevspl.trackingno;
        end if;
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
          ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
          ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
          ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
          ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
          ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
          ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
          ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
          ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
          ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
          ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
          ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:UCC128,:line_uom,:line_qty'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', cntPrevlinenumber);
        dbms_sql.bind_variable(curSql, ':item', od.item);
        dbms_sql.bind_variable(curSql, ':serialnumber', prevspl.serialnumber);
        dbms_sql.bind_variable(curSql, ':trackingno', prevspl.trackingno);
        dbms_sql.bind_variable(curSql, ':qty', cntTotQty);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', od.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', od.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', od.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', od.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', od.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', od.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', od.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', od.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', od.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', od.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', od.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', od.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', od.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', od.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', od.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', od.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', od.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', od.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', od.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', od.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', od.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', od.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', od.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', od.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', od.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', od.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', od.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', od.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', od.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', od.DTLPASSTHRUNUM10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', od.DTLPASSTHRUDATE01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', od.DTLPASSTHRUDATE02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', od.DTLPASSTHRUDATE03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', od.DTLPASSTHRUDATE04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', od.DTLPASSTHRUDOLL01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', od.DTLPASSTHRUDOLL02);
        dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
        dbms_sql.bind_variable(curSql, ':lotcount', cntLot);
        dbms_sql.bind_variable(curSql, ':uom', od.uom);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', strEquiv_Uom);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', intEquiv_Qty);
        dbms_sql.bind_variable(curSql, ':USERITEM1', prevspl.useritem1);
        dbms_sql.bind_variable(curSql, ':USERITEM2', prevspl.useritem2);
        dbms_sql.bind_variable(curSql, ':USERITEM3', prevspl.useritem3);
        dbms_sql.bind_variable(curSql, ':QTYORDER', cntPrevQtyOrder);
        dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
        dbms_sql.bind_variable(curSql, ':rmatrackingno', prevspl.rmatrackingno);
        dbms_sql.bind_variable(curSql, ':ucc128', prevspl.ucc128);
        dbms_sql.bind_variable(curSql, ':LINE_UOM', strLine_Uom);
        dbms_sql.bind_variable(curSql, ':LINE_QTY', intLine_Qty);
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
      end if;
      cntLot := 0;
      cntTotQty := 0;
      cntSequence := 1;
      cntPrevLineNumber := ol.linenumber;
      cntPrevQtyOrder := ol.qty;
      qtyRemain := ol.qty;
      while (qtyRemain > 0)
      loop
        if spl.qty = 0 then
          fetch curShippingPlateLot into spl;
          if curShippingPlateLot%notfound then
            spl := null;
          else
            prevspl := spl;
          end if;
        end if;
        if spl.item is null then
          exit;
        end if;
        if spl.qty >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := spl.qty;
        end if;
        debugmsg('compute equivs');
        compute_equiv_data(od,qtyLineNumber);
        compute_line_data(od,ol,qtyLineNumber);
        debugmsg('begin--add lot row');
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_ship_note_lot_' || strSuffix ||
          ' values (:orderid,:shipid,:item,:linenumber,:sequence,:lotnumber,:qty,'||
          ':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
          ':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
          ':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
          ':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
          ':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
          ':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
          ':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
          ':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':EQUIV_UOM,:EQUIV_QTY,:UOM,:USERITEM1,:USERITEM2,:USERITEM3'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':item', spl.item);
        dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
        dbms_sql.bind_variable(curSql, ':sequence', cntSequence);
        dbms_sql.bind_variable(curSql, ':lotnumber', spl.lotnumber);
        dbms_sql.bind_variable(curSql, ':qty', qtyLineNumber);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', strEquiv_Uom);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', intEquiv_Qty);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':USERITEM1', spl.useritem1);
        dbms_sql.bind_variable(curSql, ':USERITEM2', spl.useritem2);
        dbms_sql.bind_variable(curSql, ':USERITEM3', spl.useritem3);
        cntRows := dbms_sql.execute(curSql);
        debugmsg('end--add lot row');
        cntLot := cntLot + 1;
        cntSequence := cntSequence + 1;
        cntTotQty := cntTotQty + qtyLineNumber;
        dbms_sql.close_cursor(curSql);
        qtyRemain := qtyRemain - qtyLineNumber;
        spl.qty := spl.qty - qtyLineNumber;
      end loop; -- shippingplate
    end loop; -- orderdtlline
    close curShippingPlateLot;
    if cntPrevLineNumber <> -1 then
      if cntLot = 0 then
        curSql := dbms_sql.open_cursor;
        debugmsg('add zero qty row lot2');
        dbms_sql.parse(curSql, 'insert into I44_ship_note_lot_' || strSuffix ||
          ' values (:orderid,:shipid,:item,:linenumber,:sequence,:lotnumber,:qty,'||
          ':DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
          ':DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
          ':DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
          ':DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
          ':DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
          ':DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
          ':DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
          ':DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':EQUIV_UOM,:EQUIV_QTY,:UOM,:USERITEM1,:USERITEM2,:USERITEM3'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':item', od.item);
        dbms_sql.bind_variable(curSql, ':linenumber', cntPrevlinenumber);
        dbms_sql.bind_variable(curSql, ':sequence', 1);
        dbms_sql.bind_variable(curSql, ':lotnumber', '');
        dbms_sql.bind_variable(curSql, ':qty', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', '');
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', dteNull);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', dteNull);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', dteNull);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', dteNull);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', 0);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', od.uomentered);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', 0);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':USERITEM1', '');
        dbms_sql.bind_variable(curSql, ':USERITEM2', '');
        dbms_sql.bind_variable(curSql, ':USERITEM3', '');
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
      end if;
      curSql := dbms_sql.open_cursor;
      debugmsg('add zero qty row dtl2');
      compute_equiv_data(od,cntTotQty);
      compute_line_data(od,ol,cntTotQty);
      if rtrim(prevspl.trackingno) is null then
        strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
      else
        strProNo_or_TrackingNo := prevspl.trackingno;
      end if;
      dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
        ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
        ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
        ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
        ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
        ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
        ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
        ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
        ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
        ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
        ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
        ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
        ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
        ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
          ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:UCC128,:line_uom,:line_qty'||
        ')',
        dbms_sql.native);
      dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
      dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
      dbms_sql.bind_variable(curSql, ':linenumber', cntPrevlinenumber);
      dbms_sql.bind_variable(curSql, ':item', od.item);
      dbms_sql.bind_variable(curSql, ':serialnumber', prevspl.serialnumber);
      dbms_sql.bind_variable(curSql, ':trackingno', prevspl.trackingno);
      dbms_sql.bind_variable(curSql, ':qty', cntTotQty);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', od.DTLPASSTHRUCHAR01);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', od.DTLPASSTHRUCHAR02);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', od.DTLPASSTHRUCHAR03);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', od.DTLPASSTHRUCHAR04);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', od.DTLPASSTHRUCHAR05);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', od.DTLPASSTHRUCHAR06);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', od.DTLPASSTHRUCHAR07);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', od.DTLPASSTHRUCHAR08);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', od.DTLPASSTHRUCHAR09);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', od.DTLPASSTHRUCHAR10);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', od.DTLPASSTHRUCHAR11);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', od.DTLPASSTHRUCHAR12);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', od.DTLPASSTHRUCHAR13);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', od.DTLPASSTHRUCHAR14);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', od.DTLPASSTHRUCHAR15);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', od.DTLPASSTHRUCHAR16);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', od.DTLPASSTHRUCHAR17);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', od.DTLPASSTHRUCHAR18);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', od.DTLPASSTHRUCHAR19);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', od.DTLPASSTHRUCHAR20);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', od.DTLPASSTHRUNUM01);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', od.DTLPASSTHRUNUM02);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', od.DTLPASSTHRUNUM03);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', od.DTLPASSTHRUNUM04);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', od.DTLPASSTHRUNUM05);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', od.DTLPASSTHRUNUM06);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', od.DTLPASSTHRUNUM07);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', od.DTLPASSTHRUNUM08);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', od.DTLPASSTHRUNUM09);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', od.DTLPASSTHRUNUM10);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', od.DTLPASSTHRUDATE01);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', od.DTLPASSTHRUDATE02);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', od.DTLPASSTHRUDATE03);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', od.DTLPASSTHRUDATE04);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', od.DTLPASSTHRUDOLL01);
      dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', od.DTLPASSTHRUDOLL02);
      dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
      dbms_sql.bind_variable(curSql, ':lotcount', cntLot);
      dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
      dbms_sql.bind_variable(curSql, ':EQUIV_UOM', strEquiv_Uom);
      dbms_sql.bind_variable(curSql, ':EQUIV_QTY', intEquiv_Qty);
      dbms_sql.bind_variable(curSql, ':USERITEM1', prevspl.useritem1);
      dbms_sql.bind_variable(curSql, ':USERITEM2', prevspl.useritem2);
      dbms_sql.bind_variable(curSql, ':USERITEM3', prevspl.useritem3);
      dbms_sql.bind_variable(curSql, ':QTYORDER', cntPrevQtyOrder);
      dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
      dbms_sql.bind_variable(curSql, ':rmatrackingno', prevspl.rmatrackingno);
      dbms_sql.bind_variable(curSql, ':UCC128', prevspl.ucc128);
      dbms_sql.bind_variable(curSql, ':LINE_UOM', strLine_Uom);
      dbms_sql.bind_variable(curSql, ':LINE_QTY', intLine_Qty);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
    end if;
  end loop; -- orderdtl
end;

procedure add_dtl_rows(oh orderhdr%rowtype) is
begin
  debugmsg('add_dtl_rows');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
  --      zut.prt('od loop top');
    sp := null;
  --      zut.prt('open sp cursor for item ' || od.item);
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    open curShippingPlate(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlate into sp;
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
  --        zut.prt('ol loop top--ol line/qty is '  || ol.linenumber || ' ' ||ol.qty);
      qtyRemain := ol.qty;
      while (qtyRemain > 0)
      loop
  --          zut.prt('sp.qty is ' || sp.qty || ' remain qty is ' || qtyRemain);
        if sp.qty = 0 then
          fetch curShippingPlate into sp;
          if curShippingPlate%notfound then
            sp := null;
          end if;
        end if;
        if sp.item is null then
          exit;
        end if;
        if sp.qty >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := sp.qty;
        end if;
        debugmsg('add row dtl');
        compute_equiv_data(od,qtyLineNumber);
        compute_line_data(od,ol,qtyLineNumber);
        if rtrim(sp.trackingno) is null then
          strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
        else
          strProNo_or_TrackingNo := sp.trackingno;
        end if;
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
          ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
          ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
          ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
          ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
          ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
          ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
          ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
          ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
          ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
          ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
          ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:UCC128,:line_uom,:line_qty'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
        dbms_sql.bind_variable(curSql, ':item', sp.item);
        dbms_sql.bind_variable(curSql, ':serialnumber', sp.serialnumber);
        dbms_sql.bind_variable(curSql, ':trackingno', sp.trackingno);
        dbms_sql.bind_variable(curSql, ':qty', qtyLineNumber);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', ol.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', ol.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', ol.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', ol.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', ol.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', ol.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', ol.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', ol.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', ol.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', ol.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', ol.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', ol.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', ol.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', ol.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', ol.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', ol.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', ol.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', ol.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', ol.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', ol.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', ol.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', ol.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', ol.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', ol.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', ol.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', ol.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', ol.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', ol.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', ol.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', ol.DTLPASSTHRUNUM10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', ol.DTLPASSTHRUDATE01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', ol.DTLPASSTHRUDATE02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', ol.DTLPASSTHRUDATE03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', ol.DTLPASSTHRUDATE04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', ol.DTLPASSTHRUDOLL01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', ol.DTLPASSTHRUDOLL02);
        dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
        dbms_sql.bind_variable(curSql, ':lotcount', 0);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', strEquiv_Uom);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', intEquiv_Qty);
        dbms_sql.bind_variable(curSql, ':USERITEM1', sp.useritem1);
        dbms_sql.bind_variable(curSql, ':USERITEM2', sp.useritem2);
        dbms_sql.bind_variable(curSql, ':USERITEM3', sp.useritem3);
        dbms_sql.bind_variable(curSql, ':QTYORDER', ol.qty);
        dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
        dbms_sql.bind_variable(curSql, ':rmatrackingno', sp.rmatrackingno);
        dbms_sql.bind_variable(curSql, ':ucc128', sp.ucc128);
        dbms_sql.bind_variable(curSql, ':LINE_UOM', strLine_Uom);
        dbms_sql.bind_variable(curSql, ':LINE_QTY', intLine_Qty);
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
        qtyRemain := qtyRemain - qtyLineNumber;
        sp.qty := sp.qty - qtyLineNumber;
      end loop; -- shippingplate
      if qtyRemain = ol.qty then
        debugmsg('add zero qty row dtl3');
        strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
          ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
          ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
          ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
          ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
          ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
          ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
          ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
          ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
          ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
          ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
          ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:UCC128,:line_uom,:line_qty'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
        dbms_sql.bind_variable(curSql, ':item', od.item);
        dbms_sql.bind_variable(curSql, ':serialnumber','');
        dbms_sql.bind_variable(curSql, ':trackingno','');
        dbms_sql.bind_variable(curSql, ':qty', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', od.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', od.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', od.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', od.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', od.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', od.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', od.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', od.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', od.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', od.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', od.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', od.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', od.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', od.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', od.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', od.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', od.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', od.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', od.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', od.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', od.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', od.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', od.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', od.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', od.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', od.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', od.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', od.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', od.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', od.DTLPASSTHRUNUM10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', od.DTLPASSTHRUDATE01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', od.DTLPASSTHRUDATE02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', od.DTLPASSTHRUDATE03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', od.DTLPASSTHRUDATE04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', od.DTLPASSTHRUDOLL01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', od.DTLPASSTHRUDOLL02);
        dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
        dbms_sql.bind_variable(curSql, ':lotcount', 0);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', od.uomentered);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', 0);
        dbms_sql.bind_variable(curSql, ':USERITEM1', '');
        dbms_sql.bind_variable(curSql, ':USERITEM2', '');
        dbms_sql.bind_variable(curSql, ':USERITEM3', '');
        dbms_sql.bind_variable(curSql, ':QTYORDER', ol.qty);
        dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
        dbms_sql.bind_variable(curSql, ':rmatrackingno','');
        dbms_sql.bind_variable(curSql, ':ucc128','');
        dbms_sql.bind_variable(curSql, ':LINE_UOM', od.uomentered);
        dbms_sql.bind_variable(curSql, ':LINE_QTY', 0);
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
      end if;
    end loop; -- orderdtlline
    close curShippingPlate;
  end loop; -- orderdtl
end;

procedure add_dtl_rows_by_item(oh orderhdr%rowtype) is
begin
  debugmsg('add_dtl_rows_by_item');
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    debugmsg('od loop top');
    sp := null;
    debugmsg('open sp cursor for item ' || od.item);
    ci := null;
    open curCustItem(oh.custid,od.item);
    fetch curCustItem into ci;
    close curCustItem;
    open curShippingPlateItem(oh.orderid,oh.shipid,od.item,od.lotnumber);
    fetch curShippingPlateItem into sp;
    for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      debugmsg('ol loop top--ol line/qty is '  || ol.linenumber || ' ' ||ol.qty);
      qtyRemain := ol.qty;
      while (qtyRemain > 0)
      loop
        debugmsg('sp.qty is ' || sp.qty || ' remain qty is ' || qtyRemain);
        if sp.qty = 0 then
          fetch curShippingPlateItem into sp;
          if curShippingPlateItem%notfound then
            sp := null;
          end if;
        end if;
        if sp.item is null then
          exit;
        end if;
        if sp.qty >= qtyRemain then
          qtyLineNumber := qtyRemain;
        else
          qtyLineNumber := sp.qty;
        end if;
        curSql := dbms_sql.open_cursor;
        debugmsg('begin--add dtl row');
        compute_equiv_data(od,qtyLineNumber);
        compute_line_data(od,ol,qtyLineNumber);
        if rtrim(sp.trackingno) is null then
          strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
        else
          strProNo_or_TrackingNo := sp.trackingno;
        end if;
        dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
          ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
          ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
          ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
          ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
          ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
          ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
          ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
          ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
          ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
          ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
          ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:ucc128,:line_uom,:line_qty'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
        dbms_sql.bind_variable(curSql, ':item', sp.item);
        dbms_sql.bind_variable(curSql, ':serialnumber', sp.serialnumber);
        dbms_sql.bind_variable(curSql, ':trackingno', sp.trackingno);
        dbms_sql.bind_variable(curSql, ':qty', qtyLineNumber);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', od.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', od.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', od.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', od.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', od.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', od.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', od.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', od.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', od.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', od.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', od.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', od.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', od.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', od.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', od.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', od.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', od.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', od.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', od.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', od.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', od.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', od.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', od.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', od.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', od.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', od.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', od.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', od.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', od.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', od.DTLPASSTHRUNUM10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', od.DTLPASSTHRUDATE01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', od.DTLPASSTHRUDATE02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', od.DTLPASSTHRUDATE03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', od.DTLPASSTHRUDATE04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', od.DTLPASSTHRUDOLL01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', od.DTLPASSTHRUDOLL02);
        dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
        dbms_sql.bind_variable(curSql, ':lotcount', 0);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', strEquiv_Uom);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', intEquiv_Qty);
        dbms_sql.bind_variable(curSql, ':USERITEM1', sp.useritem1);
        dbms_sql.bind_variable(curSql, ':USERITEM2', sp.useritem2);
        dbms_sql.bind_variable(curSql, ':USERITEM3', sp.useritem3);
        dbms_sql.bind_variable(curSql, ':QTYORDER', ol.qty);
        dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
        dbms_sql.bind_variable(curSql, ':rmatrackingno', sp.rmatrackingno);
        dbms_sql.bind_variable(curSql, ':ucc128', sp.ucc128);
        dbms_sql.bind_variable(curSql, ':LINE_UOM', strLine_Uom);
        dbms_sql.bind_variable(curSql, ':LINE_QTY', intLine_Qty);
        cntRows := dbms_sql.execute(curSql);
        debugmsg('end--add dtl row');
        dbms_sql.close_cursor(curSql);
        qtyRemain := qtyRemain - qtyLineNumber;
        sp.qty := sp.qty - qtyLineNumber;
      end loop; -- shippingplate
      if qtyRemain = ol.qty then
        debugmsg('add zero line');
        strProNo_or_TrackingNo := nvl(oh.prono,ld.prono);
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_ship_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02'||
          ',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05'||
          ',:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08'||
          ',:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11'||
          ',:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14'||
          ',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17'||
          ',:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20'||
          ',:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03'||
          ',:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06'||
          ',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,'||
          ':DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
          ':DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02,'||
          ':itemdescr,:lotcount,:uom,:EQUIV_UOM,:EQUIV_QTY,:USERITEM1,:USERITEM2,:USERITEM3,:QTYORDER,'||
          ':PRONO_OR_TRACKINGNO,:RMATRACKINGNO,:UCC128,:line_uom,:line_qty'||
          ')',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
        dbms_sql.bind_variable(curSql, ':item', od.item);
        dbms_sql.bind_variable(curSql, ':serialnumber','');
        dbms_sql.bind_variable(curSql, ':trackingno','');
        dbms_sql.bind_variable(curSql, ':qty', 0);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', od.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', od.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', od.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', od.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', od.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', od.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', od.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', od.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', od.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', od.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', od.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', od.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', od.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', od.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', od.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', od.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', od.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', od.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', od.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', od.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', od.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', od.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', od.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', od.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', od.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', od.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', od.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', od.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', od.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', od.DTLPASSTHRUNUM10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE01', od.DTLPASSTHRUDATE01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE02', od.DTLPASSTHRUDATE02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE03', od.DTLPASSTHRUDATE03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDATE04', od.DTLPASSTHRUDATE04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL01', od.DTLPASSTHRUDOLL01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUDOLL02', od.DTLPASSTHRUDOLL02);
        dbms_sql.bind_variable(curSql, ':itemdescr', ci.descr);
        dbms_sql.bind_variable(curSql, ':lotcount', 0);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':EQUIV_UOM', od.uomentered);
        dbms_sql.bind_variable(curSql, ':EQUIV_QTY', 0);
        dbms_sql.bind_variable(curSql, ':USERITEM1', '');
        dbms_sql.bind_variable(curSql, ':USERITEM2', '');
        dbms_sql.bind_variable(curSql, ':USERITEM3', '');
        dbms_sql.bind_variable(curSql, ':QTYORDER', ol.qty);
        dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
        dbms_sql.bind_variable(curSql, ':rmatrackingno','');
        dbms_sql.bind_variable(curSql, ':ucc128','');
        dbms_sql.bind_variable(curSql, ':LINE_UOM', od.uomentered);
        dbms_sql.bind_variable(curSql, ':LINE_QTY', 0);
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
      end if;
    end loop; -- orderdtlline
    close curShippingPlateItem;
  end loop; -- orderdtl
end;

procedure add_hdr_rows(oh orderhdr%rowtype) is
begin
  debugmsg('add_hdr_rows');
  if (upper(in_edi_orders_only_yn) = 'Y') and
     (oh.source != 'EDI') then
    debugmsg('not an edi order');
    return;
  end if;
  zmi3.get_cust_parm_value(oh.custid,'REGORDTYPES',prm.descr,prm.abbrev);
  debugmsg('parm descr is ' || prm.descr);
  debugmsg('parm abbrev is ' || prm.abbrev);
  debugmsg('ordertype is ' || oh.ordertype);
  if instr(prm.abbrev,oh.ordertype) <> 0 then
    ld := null;
    open curLoad(oh.loadno);
    fetch curLoad into ld;
    close curLoad;
    if ld.carrier is null then
      debugmsg('carrier from orderhdr ' || oh.carrier);
      ld.carrier := oh.carrier;
    end if;
    cntChep := 0;
    cntWhite := 0;
    cntTotPallet := 0;
    strChepType := trim(substr(zci.default_value('PALLETTYPECHEP'),1,12));
    strWhiteType := trim(substr(zci.default_value('PALLETTYPEWHITEBOARD'),1,12));
    debugmsg('begin pallet history loop');
    for ph in curPalletHistory(oh.loadno,oh.custid,oh.fromfacility)
    loop
      if ph.orderid = oh.orderid and
         ph.shipid = oh.shipid then
        if ph.pallettype = strChepType then
          cntChep := cntChep + ph.outpallets;
        elsif ph.pallettype = strWhiteType then
          cntWhite := cntWhite + ph.outpallets;
        end if;
        cntTotPallet := cntTotPallet + ph.outpallets;
      end if;
    end loop;
    strTrackingNo := substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30);
    strProNo := nvl(oh.prono,ld.prono);
    if rtrim(strTrackingNo) is null then
      strProNo_or_TrackingNo := strProNo;
    else
      strProNo_or_TrackingNo := strTrackingNo;
    end if;
    strDeliveryService := substr(zim14.delivery_service(oh.orderid,oh.shipid,null,null),1,10);
    debugmsg('begin hdr insert');
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into I44_ship_note_hdr_' || strSuffix ||
' values (:CUSTID,:LOADNO,:ORDERID,:SHIPID,:PO,:STATUSUPDATE,:REFERENCE,:SHIPTONAME,' ||
':SHIPTOCONTACT,:SHIPTOADDR1,:SHIPTOADDR2,:SHIPTOCITY,:SHIPTOSTATE,:SHIPTOPOSTALCODE,' ||
':SHIPTOCOUNTRYCODE,:HDRPASSTHRUCHAR01,:HDRPASSTHRUCHAR02,:HDRPASSTHRUCHAR03,' ||
':HDRPASSTHRUCHAR04,:HDRPASSTHRUCHAR05,:HDRPASSTHRUCHAR06,:HDRPASSTHRUCHAR07,' ||
':HDRPASSTHRUCHAR08,:HDRPASSTHRUCHAR09,:HDRPASSTHRUCHAR10,:HDRPASSTHRUCHAR11,' ||
':HDRPASSTHRUCHAR12,:HDRPASSTHRUCHAR13,:HDRPASSTHRUCHAR14,:HDRPASSTHRUCHAR15,' ||
':HDRPASSTHRUCHAR16,:HDRPASSTHRUCHAR17,:HDRPASSTHRUCHAR18,:HDRPASSTHRUCHAR19,' ||
':HDRPASSTHRUCHAR20,:HDRPASSTHRUNUM01,:HDRPASSTHRUNUM02,:HDRPASSTHRUNUM03,' ||
':HDRPASSTHRUNUM04,:HDRPASSTHRUNUM05,:HDRPASSTHRUNUM06,:HDRPASSTHRUNUM07,' ||
':HDRPASSTHRUNUM08,:HDRPASSTHRUNUM09,:HDRPASSTHRUNUM10,:ORDERSTATUS,' ||
':QTYSHIP,:WEIGHTSHIP,:CUBESHIP,:CARRIER,:SHIPTO,:TRAILER,:SEAL,:CHEPCOUNT,' ||
':WHITECOUNT,:TOTPALLETCOUNT,:BILLOFLADING,:ORDERTYPE,:PRONO,:TRACKINGNO,:DELIVERY_REQUESTED,' ||
':REQUESTED_SHIP,:SHIP_NOT_BEFORE,:SHIP_NO_LATER,:CANCEL_IF_NOT_DELIVERED_BY,'||
':DO_NOT_DELIVER_AFTER,:DO_NOT_DELIVER_BEFORE,:HDRPASSTHRUDATE01,:HDRPASSTHRUDATE02,'||
':HDRPASSTHRUDATE03,:HDRPASSTHRUDATE04,:HDRPASSTHRUDOLL01,:HDRPASSTHRUDOLL02,:FROMFACILITY,' ||
':SHIPTOFAX,:SHIPTOEMAIL,:SHIPTOPHONE,:DELIVERYSERVICE,:PRONO_OR_TRACKINGNO,'||
':SHIPTYPE,:CUSTOMBOL)',
    dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':CUSTID', oh.CUSTID);
    dbms_sql.bind_variable(curSql, ':LOADNO', oh.LOADNO);
    dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
    dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
    dbms_sql.bind_variable(curSql, ':PO', oh.PO);
    dbms_sql.bind_variable(curSql, ':STATUSUPDATE', oh.STATUSUPDATE);
    dbms_sql.bind_variable(curSql, ':REFERENCE', oh.REFERENCE);
    dbms_sql.bind_variable(curSql, ':SHIPTONAME', oh.SHIPTONAME);
    dbms_sql.bind_variable(curSql, ':SHIPTOCONTACT', oh.SHIPTOCONTACT);
    dbms_sql.bind_variable(curSql, ':SHIPTOADDR1', oh.SHIPTOADDR1);
    dbms_sql.bind_variable(curSql, ':SHIPTOADDR2', oh.SHIPTOADDR2);
    dbms_sql.bind_variable(curSql, ':SHIPTOCITY', oh.SHIPTOCITY);
    dbms_sql.bind_variable(curSql, ':SHIPTOSTATE', oh.SHIPTOSTATE);
    dbms_sql.bind_variable(curSql, ':SHIPTOPOSTALCODE', oh.SHIPTOPOSTALCODE);
    dbms_sql.bind_variable(curSql, ':SHIPTOCOUNTRYCODE', oh.SHIPTOCOUNTRYCODE);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR01', oh.HDRPASSTHRUCHAR01);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR02', oh.HDRPASSTHRUCHAR02);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR03', oh.HDRPASSTHRUCHAR03);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR04', oh.HDRPASSTHRUCHAR04);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR05', oh.HDRPASSTHRUCHAR05);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR06', oh.HDRPASSTHRUCHAR06);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR07', oh.HDRPASSTHRUCHAR07);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR08', oh.HDRPASSTHRUCHAR08);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR09', oh.HDRPASSTHRUCHAR09);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR10', oh.HDRPASSTHRUCHAR10);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR11', oh.HDRPASSTHRUCHAR11);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR12', oh.HDRPASSTHRUCHAR12);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR13', oh.HDRPASSTHRUCHAR13);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR14', oh.HDRPASSTHRUCHAR14);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR15', oh.HDRPASSTHRUCHAR15);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR16', oh.HDRPASSTHRUCHAR16);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR17', oh.HDRPASSTHRUCHAR17);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR18', oh.HDRPASSTHRUCHAR18);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR19', oh.HDRPASSTHRUCHAR19);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUCHAR20', oh.HDRPASSTHRUCHAR20);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM01', oh.HDRPASSTHRUNUM01);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM02', oh.HDRPASSTHRUNUM02);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM03', oh.HDRPASSTHRUNUM03);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM04', oh.HDRPASSTHRUNUM04);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM05', oh.HDRPASSTHRUNUM05);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM06', oh.HDRPASSTHRUNUM06);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM07', oh.HDRPASSTHRUNUM07);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM08', oh.HDRPASSTHRUNUM08);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM09', oh.HDRPASSTHRUNUM09);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUNUM10', oh.HDRPASSTHRUNUM10);
    dbms_sql.bind_variable(curSql, ':ORDERSTATUS', oh.ORDERSTATUS);
    dbms_sql.bind_variable(curSql, ':QTYSHIP', oh.QTYSHIP);
    dbms_sql.bind_variable(curSql, ':WEIGHTSHIP', oh.WEIGHTSHIP);
    dbms_sql.bind_variable(curSql, ':CUBESHIP', oh.CUBESHIP);
    dbms_sql.bind_variable(curSql, ':CARRIER', ld.CARRIER);
    dbms_sql.bind_variable(curSql, ':SHIPTO', oh.SHIPTO);
    dbms_sql.bind_variable(curSql, ':trailer', ld.trailer);
    dbms_sql.bind_variable(curSql, ':seal', ld.seal);
    dbms_sql.bind_variable(curSql, ':chepcount', cntChep);
    dbms_sql.bind_variable(curSql, ':whitecount', cntwhite);
    dbms_sql.bind_variable(curSql, ':totpalletcount', cntTotPallet);
    dbms_sql.bind_variable(curSql, ':billoflading',nvl(ld.billoflading,nvl(oh.billoflading,to_char(oh.orderid)||'-'||to_char(oh.shipid))));
    dbms_sql.bind_variable(curSql, ':ORDERTYPE', oh.ORDERTYPE);
    dbms_sql.bind_variable(curSql, ':PRONO', strPRONO);
    dbms_sql.bind_variable(curSql, ':TRACKINGNO', strTRACKINGNO);
    dbms_sql.bind_variable(curSql, ':DELIVERY_REQUESTED', oh.DELIVERY_REQUESTED);
    dbms_sql.bind_variable(curSql, ':REQUESTED_SHIP', oh.REQUESTED_SHIP);
    dbms_sql.bind_variable(curSql, ':SHIP_NOT_BEFORE', oh.SHIP_NOT_BEFORE);
    dbms_sql.bind_variable(curSql, ':SHIP_NO_LATER', oh.SHIP_NO_LATER);
    dbms_sql.bind_variable(curSql, ':CANCEL_IF_NOT_DELIVERED_BY', oh.CANCEL_IF_NOT_DELIVERED_BY);
    dbms_sql.bind_variable(curSql, ':DO_NOT_DELIVER_AFTER', oh.DO_NOT_DELIVER_AFTER);
    dbms_sql.bind_variable(curSql, ':DO_NOT_DELIVER_BEFORE', oh.DO_NOT_DELIVER_BEFORE);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUDATE01', oh.HDRPASSTHRUDATE01);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUDATE02', oh.HDRPASSTHRUDATE02);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUDATE03', oh.HDRPASSTHRUDATE03);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUDATE04', oh.HDRPASSTHRUDATE04);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUDOLL01', oh.HDRPASSTHRUDOLL01);
    dbms_sql.bind_variable(curSql, ':HDRPASSTHRUDOLL02', oh.HDRPASSTHRUDOLL02);
    dbms_sql.bind_variable(curSql, ':FROMFACILITY', oh.FROMFACILITY);
    dbms_sql.bind_variable(curSql, ':SHIPTOFAX', oh.SHIPTOFAX);
    dbms_sql.bind_variable(curSql, ':SHIPTOEMAIL', oh.SHIPTOEMAIL);
    dbms_sql.bind_variable(curSql, ':SHIPTOPHONE', oh.SHIPTOPHONE);
    dbms_sql.bind_variable(curSql, ':DELIVERYSERVICE', strDELIVERYSERVICE);
    dbms_sql.bind_variable(curSql, ':PRONO_OR_TRACKINGNO', strProNo_or_TrackingNo);
    dbms_sql.bind_variable(curSql, ':SHIPTYPE', nvl(ld.shiptype,oh.shiptype));
    dbms_sql.bind_variable(curSql, ':CUSTOMBOL',
                            zedi.get_custom_bol(oh.orderid,oh.shipid));
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
    debugmsg('end header insert');
    if nvl(trim(in_count_lots_yn),'N') = 'Y' then
      add_dtl_rows_by_lot(oh);
    elsif nvl(trim(in_count_lots_yn),'N') = 'I' then
      add_dtl_rows_by_item(oh);
    elsif nvl(trim(in_count_lots_yn),'N') in ('L','M') then
      add_dtl_rows_by_line(oh);
    else
      add_dtl_rows(oh);
    end if;
  end if;
end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
  debugmsg('debug is on');
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

debugmsg('get view number');
cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'I44_SHIP_NOTE_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

debugmsg('create hdr table');
cmdSql := 'create table I44_ship_note_hdr_' || strSuffix ||
'(custid varchar2(10)' ||
',LOADNO NUMBER(7)' ||
',orderid number(9)' ||
',shipid number(2)' ||
',PO VARCHAR2(20)' ||
',STATUSUPDATE DATE' ||
',REFERENCE VARCHAR2(20)' ||
',SHIPTONAME VARCHAR2(40)' ||
',SHIPTOCONTACT VARCHAR2(40)' ||
',SHIPTOADDR1 VARCHAR2(40)' ||
',SHIPTOADDR2 VARCHAR2(40)' ||
',SHIPTOCITY VARCHAR2(30)' ||
',SHIPTOSTATE VARCHAR2(5)' ||
',SHIPTOPOSTALCODE VARCHAR2(12)' ||
',SHIPTOCOUNTRYCODE VARCHAR2(3)' ||
',HDRPASSTHRUCHAR01 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR02 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR03 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR04 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR05 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR06 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR07 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR08 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR09 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR10 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR11 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR12 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR13 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR14 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR15 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR16 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR17 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR18 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR19 VARCHAR2(255)' ||
',HDRPASSTHRUCHAR20 VARCHAR2(255)' ||
',HDRPASSTHRUNUM01 NUMBER(16,4)' ||
',HDRPASSTHRUNUM02 NUMBER(16,4)' ||
',HDRPASSTHRUNUM03 NUMBER(16,4)' ||
',HDRPASSTHRUNUM04 NUMBER(16,4)' ||
',HDRPASSTHRUNUM05 NUMBER(16,4)' ||
',HDRPASSTHRUNUM06 NUMBER(16,4)' ||
',HDRPASSTHRUNUM07 NUMBER(16,4)' ||
',HDRPASSTHRUNUM08 NUMBER(16,4)' ||
',HDRPASSTHRUNUM09 NUMBER(16,4)' ||
',HDRPASSTHRUNUM10 NUMBER(16,4)' ||
',ORDERSTATUS VARCHAR2(1)' ||
',QTYSHIP NUMBER(7)' ||
',WEIGHTSHIP NUMBER(17,8)' ||
',CUBESHIP NUMBER(10,4)' ||
',CARRIER VARCHAR2(10)' ||
',SHIPTO VARCHAR2(10)' ||
',TRAILER VARCHAR2(12)' ||
',SEAL VARCHAR2(15)' ||
',CHEPCOUNT NUMBER(7)' ||
',WHITECOUNT NUMBER(7)' ||
',TOTPALLETCOUNT NUMBER(7)' ||
',BILLOFLADING VARCHAR2(40)' ||
',ORDERTYPE VARCHAR2(1),PRONO VARCHAR2(20),' ||
' TRACKINGNO VARCHAR2(30),DELIVERY_REQUESTED DATE,REQUESTED_SHIP DATE,' ||
' SHIP_NOT_BEFORE DATE,SHIP_NO_LATER DATE,CANCEL_IF_NOT_DELIVERED_BY DATE,' ||
' DO_NOT_DELIVER_AFTER DATE,DO_NOT_DELIVER_BEFORE DATE,HDRPASSTHRUDATE01 DATE,' ||
' HDRPASSTHRUDATE02 DATE,HDRPASSTHRUDATE03 DATE,HDRPASSTHRUDATE04 DATE,' ||
' HDRPASSTHRUDOLL01 NUMBER(10,2),HDRPASSTHRUDOLL02 NUMBER(10,2),FROMFACILITY VARCHAR2(3),' ||
' SHIPTOFAX VARCHAR2(25),SHIPTOEMAIL VARCHAR2(255),SHIPTOPHONE VARCHAR2(25),DELIVERYSERVICE VARCHAR2(255),' ||
' prono_or_trackingno varchar2(30), shiptype varchar2(1), custombol varchar2(100) ' ||
')';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create table dtl');
cmdSql := 'create table I44_ship_note_dtl_' || strSuffix ||
' (orderid number(9),shipid number(2),linenumber number(7),' ||
' item varchar2(50),serialnumber varchar2(30), ' ||
' trackingno varchar2(30),qty number(7) ' ||
',DTLPASSTHRUCHAR01 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR02 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR03 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR04 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR05 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR06 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR07 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR08 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR09 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR10 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR11 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR12 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR13 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR14 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR15 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR16 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR17 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR18 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR19 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR20 VARCHAR2(255)' ||
',DTLPASSTHRUNUM01 NUMBER(16,4)' ||
',DTLPASSTHRUNUM02 NUMBER(16,4)' ||
',DTLPASSTHRUNUM03 NUMBER(16,4)' ||
',DTLPASSTHRUNUM04 NUMBER(16,4)' ||
',DTLPASSTHRUNUM05 NUMBER(16,4)' ||
',DTLPASSTHRUNUM06 NUMBER(16,4)' ||
',DTLPASSTHRUNUM07 NUMBER(16,4)' ||
',DTLPASSTHRUNUM08 NUMBER(16,4)' ||
',DTLPASSTHRUNUM09 NUMBER(16,4)' ||
',DTLPASSTHRUNUM10 NUMBER(16,4)' ||
',DTLPASSDATE01 DATE' ||
',DTLPASSDATE02 DATE' ||
',DTLPASSDATE03 DATE' ||
',DTLPASSDATE04 DATE' ||
',DTLPASSTHRUDOLL01 NUMBER(10,2)' ||
',DTLPASSTHRUDOLL02 NUMBER(10,2)' ||
',ITEMDESCR VARCHAR2(255)'||
',LOTCOUNT NUMBER(7)'||
',UOM VARCHAR2(4)'||
',EQUIV_UOM VARCHAR2(4)'||
',EQUIV_QTY NUMBER(7)'||
',USERITEM1 VARCHAR2(255),USERITEM2 VARCHAR2(255),USERITEM3 VARCHAR2(255), qtyorder number(7),' ||
' prono_or_trackingno varchar2(30), rmatrackingno varchar2(30), ' ||
' ucc128 varchar2(20), ' ||
' LINE_UOM VARCHAR2(4),'||
' LINE_QTY NUMBER(7)'||
 ') ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

debugmsg('create dtl lot');
cmdSql := 'create table I44_ship_note_lot_' || strSuffix ||
' (orderid number(9),shipid number(2),item varchar2(50),linenumber number(7)' ||
',sequence number(7)'||
',lotnumber varchar2(30)'||
',qty number(7)'||
',DTLPASSTHRUCHAR01 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR02 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR03 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR04 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR05 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR06 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR07 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR08 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR09 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR10 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR11 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR12 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR13 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR14 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR15 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR16 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR17 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR18 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR19 VARCHAR2(255)' ||
',DTLPASSTHRUCHAR20 VARCHAR2(255)' ||
',DTLPASSTHRUNUM01 NUMBER(16,4)' ||
',DTLPASSTHRUNUM02 NUMBER(16,4)' ||
',DTLPASSTHRUNUM03 NUMBER(16,4)' ||
',DTLPASSTHRUNUM04 NUMBER(16,4)' ||
',DTLPASSTHRUNUM05 NUMBER(16,4)' ||
',DTLPASSTHRUNUM06 NUMBER(16,4)' ||
',DTLPASSTHRUNUM07 NUMBER(16,4)' ||
',DTLPASSTHRUNUM08 NUMBER(16,4)' ||
',DTLPASSTHRUNUM09 NUMBER(16,4)' ||
',DTLPASSTHRUNUM10 NUMBER(16,4)' ||
',DTLPASSDATE01 DATE' ||
',DTLPASSDATE02 DATE' ||
',DTLPASSDATE03 DATE' ||
',DTLPASSDATE04 DATE' ||
',DTLPASSTHRUDOLL01 NUMBER(10,2)' ||
',DTLPASSTHRUDOLL02 NUMBER(10,2)' ||
',EQUIV_UOM VARCHAR2(4)'||
',EQUIV_QTY NUMBER(7)'||
',UOM CHAR(3),USERITEM1 VARCHAR2(255),USERITEM2 VARCHAR2(255),USERITEM3 VARCHAR2(255)' ||
') ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

if in_orderid != 0 then
  debugmsg('orderhdr select');
  if upper(rtrim(in_include_cancelled_orders_yn)) = 'Y' then
    debugmsg('orderhdr with cancels ' || in_custid || ' ' ||
      in_orderid || '-' || in_shipid);
    for oh in curOrderHdr_with_cancels
    loop
      debugmsg('call add hdr rows');
      add_hdr_rows(oh);
    end loop;
  else
    debugmsg('orderhdr NO cancels');
    for oh in curOrderHdr
    loop
      add_hdr_rows(oh);
    end loop;
  end if;
elsif in_loadno != 0 then
  debugmsg('load select');
  if upper(rtrim(in_include_cancelled_orders_yn)) = 'Y' then
    debugmsg('load with cancels');
    for oh in curOrderHdrByLoad_with_cancels
    loop
      add_hdr_rows(oh);
    end loop;
  else
    debugmsg('load NO cancels');
    for oh in curOrderHdrByLoad
    loop
      add_hdr_rows(oh);
    end loop;
  end if;
elsif rtrim(in_begdatestr) is not null then
  debugmsg('date range select');
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
  if upper(rtrim(in_include_cancelled_orders_yn)) = 'Y' then
    for oh in curOrderHdrByShipDate_cancels
    loop
      add_hdr_rows(oh);
    end loop;
  else
    for oh in curOrderHdrByShipDate
    loop
      add_hdr_rows(oh);
    end loop;
  end if;
end if;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbI44sn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_I44_ship_note;

procedure end_I44_ship_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop table I44_ship_note_dtl_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table I44_ship_note_lot_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table I44_ship_note_hdr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zeI44sn ' || sqlerrm;
  out_errorno := sqlcode;
end end_I44_ship_note;

procedure begin_I44_rcpt_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = 'R'
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = 'R'
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = 'R'
     and loadno = in_loadno;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select item,
         lotnumber,
         nvl(dtlpassthrunum10,0) as linenumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderDtlRcpt(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         inventoryclass,
         sum(qtyrcvd) as qty
    from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
   group by item,inventoryclass;
rc curOrderDtlRcpt%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
dteTest date;
strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strDescr orderstatus.descr%type;
strUnStatus orderstatus.abbrev%type;
strDmgStatus orderstatus.abbrev%type;
strshipParm orderstatus.abbrev%type;
strMovement orderstatus.abbrev%type;
strReason orderstatus.abbrev%type;
strCarrier loads.carrier%type;
qtyRemain shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
prm licenseplatestatus%rowtype;

procedure add_dtl_rows(oh orderhdr%rowtype) is
begin
  zmi3.get_cust_parm_value(oh.custid,'RETORDTYPES',prm.descr,prm.abbrev);
  if instr(prm.abbrev,oh.ordertype) <> 0 then
    for od in curOrderDtl(oh.orderid,oh.shipid)
    loop
      qtyLineNumber := 0;
      for rc in curOrderDtlRcpt(oh.orderid,oh.shipid,od.item,od.lotnumber)
      loop
        zmi3.get_whse(oh.custid,rc.inventoryclass,strWhse,strRegWhse,strRetWhse);
/* should "OP" be included ???sap
        if nvl(strWhse,'x') != nvl(strRetWhse,'y') then
          goto continue_rc_loop;
        end if;
*/
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_rcpt_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty)',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', od.linenumber);
        dbms_sql.bind_variable(curSql, ':item', rc.item);
        dbms_sql.bind_variable(curSql, ':serialnumber', '');
        dbms_sql.bind_variable(curSql, ':trackingno', '');
        dbms_sql.bind_variable(curSql, ':qty', rc.qty);
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
        qtyLineNumber := qtyLineNumber + rc.qty;
      << continue_rc_loop >>
        null;
      end loop; -- orderdtlrcpt
      if qtyLineNumber = 0 then
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into I44_rcpt_note_dtl_' || strSuffix ||
          ' values (:orderid,:shipid,:linenumber,:item,:serialnumber,' ||
          ':trackingno,:qty)',
          dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
        dbms_sql.bind_variable(curSql, ':linenumber', od.linenumber);
        dbms_sql.bind_variable(curSql, ':item', od.item);
        dbms_sql.bind_variable(curSql, ':serialnumber','');
        dbms_sql.bind_variable(curSql, ':trackingno','');
        dbms_sql.bind_variable(curSql, ':qty', 0);
      end if;
    end loop; -- orderdtl
  end if;
end;

begin

out_errorno := 0;
out_msg := '';

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'I44_RCPT_NOTE_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cmdSql := 'create table I44_rcpt_note_dtl_' || strSuffix ||
 ' (orderid number(9),shipid number(2),linenumber number(7),' ||
 ' item varchar2(50),serialnumber varchar2(30), ' ||
 ' trackingno varchar2(30),qty number(7) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create view I44_rcpt_note_hdr_' || strSuffix ||
 ' (custid,loadno,orderid,shipid,po,statusupdate,reference,' ||
 ' shiptoname,shiptoaddr1,shiptoaddr2,shiptocity,shiptostate,' ||
 ' shiptopostalcode,shiptocountrycode,' ||
 ' hdrpassthruchar01,hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,' ||
 ' hdrpassthruchar05,hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,' ||
 ' hdrpassthruchar09,hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,' ||
 ' hdrpassthruchar13,hdrpassthruchar14,hdrpassthruchar15,hdrpassthruchar16,' ||
 ' hdrpassthruchar17,hdrpassthruchar18,hdrpassthruchar19,hdrpassthruchar20,' ||
 ' hdrpassthrunum01,hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,' ||
 ' hdrpassthrunum05,hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,' ||
 ' hdrpassthrunum09,hdrpassthrunum10,rma,process_type) ' ||
 ' as select custid,loadno,oh.orderid,oh.shipid,po,statusupdate,reference,' ||
 ' decode(oh.shipto,null,oh.shiptoname,cn.name),' ||
 ' decode(oh.shipto,null,oh.shiptoaddr1,cn.addr1),' ||
 ' decode(oh.shipto,null,oh.shiptoaddr2,cn.addr2),' ||
 ' decode(oh.shipto,null,oh.shiptocity,cn.city),' ||
 ' decode(oh.shipto,null,oh.shiptostate,cn.state),' ||
 ' decode(oh.shipto,null,oh.shiptopostalcode,cn.postalcode),' ||
 ' decode(oh.shipto,null,oh.shiptocountrycode,cn.countrycode),' ||
 ' hdrpassthruchar01,hdrpassthruchar02,hdrpassthruchar03,hdrpassthruchar04,' ||
 ' hdrpassthruchar05,hdrpassthruchar06,hdrpassthruchar07,hdrpassthruchar08,' ||
 ' hdrpassthruchar09,hdrpassthruchar10,hdrpassthruchar11,hdrpassthruchar12,' ||
 ' hdrpassthruchar13,hdrpassthruchar14,hdrpassthruchar15,hdrpassthruchar16,' ||
 ' hdrpassthruchar17,hdrpassthruchar18,hdrpassthruchar19,hdrpassthruchar20,' ||
 ' hdrpassthrunum01,hdrpassthrunum02,hdrpassthrunum03,hdrpassthrunum04,' ||
 ' hdrpassthrunum05,hdrpassthrunum06,hdrpassthrunum07,hdrpassthrunum08,' ||
 ' hdrpassthrunum09,hdrpassthrunum10,rma,' ||
 ' decode((select count(1) from orderhdr where custid=oh.custid ' ||
 '   and reference=oh.hdrpassthruchar02 and ordertype=''O''), 0, ''OP'', ''IP'') ' ||
 '  from consignee cn, orderhdr oh ' ||
 ' where oh.orderstatus = ''R'' ' ||
 ' and oh.custid = ''' || rtrim(in_custid) || '''' ||
 ' and oh.shipto = cn.consignee(+) ' ||
 ' and exists (select * from i44_rcpt_note_dtl_' || strSuffix || ' i44 ' ||
 ' where oh.orderid = i44.orderid and oh.shipid = i44.shipid)';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    add_dtl_rows(oh);
  end loop;
elsif in_loadno != 0 then
  for oh in curOrderHdrByLoad
  loop
    add_dtl_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
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
    add_dtl_rows(oh);
  end loop;
end if;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbI44rn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_I44_rcpt_note;

procedure end_I44_rcpt_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop view I44_rcpt_note_hdr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table I44_rcpt_note_dtl_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zeI44sn ' || sqlerrm;
  out_errorno := sqlcode;
end end_I44_rcpt_note;

procedure begin_I9_ship_note
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByShipDate is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and loadno = in_loadno;

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
od curOrderDtl%rowtype;

cursor curShippingPlate(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select item,
         invstatus,
         inventoryclass,
         fromlpid,
         sum(quantity) as qty
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH'
   group by item,
            invstatus,
            inventoryclass,
            fromlpid;
sp curShippingPlate%rowtype;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));
ol curOrderDtlLine%rowtype;

cursor curLoads is
  select carrier,billoflading
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
dteTest date;
strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strDescr orderstatus.descr%type;
strUnStatus orderstatus.abbrev%type;
strDmgStatus orderstatus.abbrev%type;
strTranParm orderstatus.abbrev%type;
strOverrideMovement orderstatus.abbrev%type;
strMovement orderstatus.abbrev%type;
strSpecialStock orderstatus.abbrev%type;
strOtherMovement orderstatus.abbrev%type;
strReason orderstatus.abbrev%type;
strCarrier loads.carrier%type;
strAbbrev orderstatus.abbrev%type;
prm licenseplatestatus%rowtype;
qtyRemain integer;
qtyLineNumber integer;
strDOAyn varchar2(1);
strMsg varchar2(255);
strIsCustomerReturn orderhdr.rma%type;
intCtoStoNumber integer;
strFromStorageLoc orderstatus.abbrev%type;
strToStorageLoc orderstatus.abbrev%type;

procedure get_next_shiplip(oh orderhdr%rowtype) is
begin
  while(1=1)
  loop
/*
    zms.log_msg('ImpExp', '', oh.custid,
      'get_next_shiplip',
      'T', 'IMPEXP', strMsg);
    commit;
*/
    fetch curShippingPlate into sp;
    if curShippingPlate%notfound then
      sp := null;
      exit;
    end if;
    zmi3.get_whse(oh.custid,sp.inventoryclass,strWhse,strRegWhse,strRetWhse);
/*
    zms.log_msg('ImpExp', '', oh.custid,
      'get_whse '  || strWhse,
      'T', 'IMPEXP', strMsg);
    commit;
*/
    if strWhse is not null then
      exit;
    end if;
  end loop;
exception when others then
  sp := null;
/*
    zms.log_msg('ImpExp', '', oh.custid,
      'get_next_shiplip exception '  || sqlerrm,
      'T', 'IMPEXP', strMsg);
    commit;
*/
end;

procedure add_dtl_rows(oh orderhdr%rowtype) is
begin
  zmi3.get_cust_parm_value(oh.custid,'RETORDTYPES',prm.descr,prm.abbrev);
/*
  zms.log_msg('ImpExp', '', oh.custid,
      'add_dtl_rows ' || oh.ordertype,
      'T', 'IMPEXP', strMsg);
  commit;
*/
  if instr(prm.abbrev,oh.ordertype) <> 0 then
    ld := null;
    open curLoads;
    fetch curLoads into ld;
    close curLoads;
    strCarrier := nvl(ld.carrier,oh.carrier);
    strReason := 'NA';
    zmi3.get_cust_parm_value(oh.custid,'DMGSTATUS',strDescr,strDmgStatus);
    for od in curOrderDtl(oh.orderid,oh.shipid)
    loop
/*
      zms.log_msg('ImpExp', '', oh.custid,
      'od loop ' || od.item,
      'T', 'IMPEXP', strMsg);
      commit;
*/
      sp := null;
      open curShippingPlate(oh.orderid,oh.shipid,od.item,od.lotnumber);
      get_next_shiplip(oh);
/*
      zms.log_msg('ImpExp', '', oh.custid,
      'begin ol loop ' || sp.item || ' ' || sp.qty,
      'T', 'IMPEXP', strMsg);
      commit;
*/
      for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
      loop
        qtyRemain := ol.qty;
/*
        zms.log_msg('ImpExp', '', oh.custid,
        'ol qty is ' || ol.qty,
        'T', 'IMPEXP', strMsg);
        commit;
*/
        while (qtyRemain > 0)
        loop
/*
          zms.log_msg('ImpExp', '', oh.custid,
          'qtyRemain is ' || qtyRemain,
          'T', 'IMPEXP', strMsg);
          commit;
          zms.log_msg('ImpExp', '', oh.custid,
          'sp.qty is ' || sp.qty,
          'T', 'IMPEXP', strMsg);
          commit;
*/
          if sp.qty = 0 then
            get_next_shiplip(oh);
          end if;
/*
          zms.log_msg('ImpExp', '', oh.custid,
          'sp is ' || sp.inventoryclass || ' ' || sp.item || ' ' || sp.qty,
          'T', 'IMPEXP', strMsg);
          commit;
*/
          if sp.item is null then
            exit;
          end if;
          if sp.qty >= qtyRemain then
            qtyLineNumber := qtyRemain;
          else
            qtyLineNumber := sp.qty;
          end if;
          zmi3.get_whse(oh.custid,sp.inventoryclass,strWhse,strRegWhse,strRetWhse);
          strTranParm := 'GI-OTHER';
          zmi3.get_whse_parm_value(oh.custid,strWhse,strTranParm,strDescr,strAbbrev);
          if strAbbrev is null then  -- no interface for this warehouse loc
            sp.qty := 0;
            goto continue_sp_loop;
          end if;
          strOtherMovement := substr(strAbbrev,1,3);
          strTranParm := 'GI-' || rtrim(sp.invstatus);
          zmi3.get_whse_parm_value(oh.custid,strWhse,strTranParm,strDescr,strAbbrev);
          if strAbbrev is null then
            strMovement := strOtherMovement;
          else
            strMovement := substr(strAbbrev,1,3);
          end if;
          zmi3.check_for_shipto_override(oh.custid,oh.shipto,strOverrideMovement);
          if strOverrideMovement is not null then
            strMovement := strOverrideMovement;
          end if;
/*
          zms.log_msg('ImpExp', '', oh.custid,
          'strMovement is  ' || strMovement || ' ' || strTranParm,
          'T', 'IMPEXP', strMsg);
          commit;
*/
          strToStorageLoc := null;
          zmi3.check_for_customer_return(sp.fromlpid,sp.inventoryclass,strIsCustomerReturn);
          zmi3.get_cust_parm_value(oh.custid,'UNSTATUS',strDescr,strUnStatus);
          if (instr(strUnStatus,sp.invstatus) != 0) and
             (strIsCustomerReturn <> 'Y') then -- not a customer return, check for override
            strSpecialStock := 'K';
            strTranParm := 'NC-' || strMovement;
            zmi3.get_whse_parm_value(oh.custid,strWhse,strTranParm,strDescr,strAbbrev);
            if strAbbrev is not null then
              strMovement := substr(strAbbrev,1,3);
            end if;
            strFromStorageLoc := strWhse;
          else -- customer return
            if instr(strDmgStatus,sp.invstatus) != 0 then
              strSpecialStock := 'K';
              strFromStorageLoc := strWhse;
            else
              strSpecialStock := '';
              strFromStorageLoc := strRetWhse;
            end if;
          end if;
          zmi3.get_cto_sto_prefix(oh.custid,sp.item,intCtoStoNumber);
          intCtoStoNumber := intCtoStoNumber + oh.loadno;
          curSql := dbms_sql.open_cursor;
          dbms_sql.parse(curSql, 'insert into i9_ship_note_lips_' || strSuffix ||
            ' values (:custid,:loadno,:orderid,:shipid,:reference,:ctostonumber,:orderitem,:orderlot,' ||
            ':po,:linenumber,:carrier,:billoflading,:statusupdate,:movement,:specialstock,:reason,' ||
            ':item,:fromstorageloc,:tostorageloc,:qty)',
            dbms_sql.native);
          dbms_sql.bind_variable(curSql, ':custid', oh.custid);
          dbms_sql.bind_variable(curSql, ':loadno', oh.loadno);
          dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
          dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
          dbms_sql.bind_variable(curSql, ':reference', oh.reference);
          dbms_sql.bind_variable(curSql, ':ctostonumber', intCtoStoNumber);
          dbms_sql.bind_variable(curSql, ':orderitem', od.item);
          dbms_sql.bind_variable(curSql, ':orderlot', od.lotnumber);
          dbms_sql.bind_variable(curSql, ':po', oh.po);
          dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
          dbms_sql.bind_variable(curSql, ':carrier', strCarrier);
          dbms_sql.bind_variable(curSql, ':billoflading', oh.billoflading);
          dbms_sql.bind_variable(curSql, ':statusupdate', oh.statusupdate);
          dbms_sql.bind_variable(curSql, ':movement', strMovement);
          dbms_sql.bind_variable(curSql, ':specialstock', nvl(rtrim(strSpecialStock),'x'));
          dbms_sql.bind_variable(curSql, ':reason', strReason);
          dbms_sql.bind_variable(curSql, ':item', sp.item);
          dbms_sql.bind_variable(curSql, ':fromstorageloc', strFromStorageLoc);
          dbms_sql.bind_variable(curSql, ':tostorageloc', strToStorageLoc);
          dbms_sql.bind_variable(curSql, ':qty', qtyLineNumber);
          cntRows := dbms_sql.execute(curSql);
          dbms_sql.close_cursor(curSql);
          qtyRemain := qtyRemain - qtyLineNumber;
          sp.qty := sp.qty - qtyLineNumber;
        <<continue_sp_loop>>
          null;
        end loop; -- shippingplate
        close curShippingPlate;
        if qtyRemain = ol.qty then
          zmi3.get_whse(oh.custid,'XX',strWhse,strRegWhse,strRetWhse);
          strToStorageLoc := null;
          strWhse := strRetWhse;
          strFromStorageLoc := strRetWhse;
          strTranParm := 'GI-OTHER';
          zmi3.get_whse_parm_value(oh.custid,strWhse,strTranParm,strDescr,strAbbrev);
          if strAbbrev is not null then
            strMovement := substr(strAbbrev,1,3);
            strSpecialStock := '';
            zmi3.check_for_shipto_override(oh.custid,oh.shipto,strOverrideMovement);
            if strOverrideMovement is not null then
              strMovement := strOverrideMovement;
            end if;
            zmi3.get_cto_sto_prefix(oh.custid,sp.item,intCtoStoNumber);
            intCtoStoNumber := intCtoStoNumber + oh.loadno;
            curSql := dbms_sql.open_cursor;
            dbms_sql.parse(curSql, 'insert into i9_ship_note_lips_' || strSuffix ||
              ' values (:custid,:loadno,:orderid,:shipid,:reference,:ctostonumber,:orderitem,:orderlot,' ||
              ':po,:linenumber,:carrier,:billoflading,:statusupdate,:movement,:specialstock,:reason,' ||
              ':item,:fromstorageloc,:tostorageloc,:qty)',
              dbms_sql.native);
            dbms_sql.bind_variable(curSql, ':custid', oh.custid);
            dbms_sql.bind_variable(curSql, ':loadno', oh.loadno);
            dbms_sql.bind_variable(curSql, ':orderid', oh.orderid);
            dbms_sql.bind_variable(curSql, ':shipid', oh.shipid);
            dbms_sql.bind_variable(curSql, ':reference', oh.reference);
            dbms_sql.bind_variable(curSql, ':ctostonumber', intCtoStoNumber);
            dbms_sql.bind_variable(curSql, ':orderitem', od.item);
            dbms_sql.bind_variable(curSql, ':orderlot', od.lotnumber);
            dbms_sql.bind_variable(curSql, ':po', oh.po);
            dbms_sql.bind_variable(curSql, ':linenumber', ol.linenumber);
            dbms_sql.bind_variable(curSql, ':carrier', strCarrier);
            dbms_sql.bind_variable(curSql, ':billoflading', oh.billoflading);
            dbms_sql.bind_variable(curSql, ':statusupdate', oh.statusupdate);
            dbms_sql.bind_variable(curSql, ':movement', strMovement);
            dbms_sql.bind_variable(curSql, ':specialstock', nvl(rtrim(strSpecialStock),'x'));
            dbms_sql.bind_variable(curSql, ':reason', strReason);
            dbms_sql.bind_variable(curSql, ':item', od.item);
            dbms_sql.bind_variable(curSql, ':fromstorageloc', strfromstorageloc);
            dbms_sql.bind_variable(curSql, ':tostorageloc', strtostorageloc);
            dbms_sql.bind_variable(curSql, ':qty', 0);
            cntRows := dbms_sql.execute(curSql);
            dbms_sql.close_cursor(curSql);
          end if;
        end if;
      end loop; -- orderdtlline
    end loop; -- orderdtl
  end if;
end;

begin

out_errorno := 0;
out_msg := '';

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'I9_SHIP_NOTE_LIPS_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cmdSql := 'create table I9_SHIP_NOTE_LIPS_' || strSuffix ||
 ' (custid varchar2(10),loadno number(7),orderid number(9), ' ||
 ' shipid number(2),reference varchar2(20),ctostonumber number(8),orderitem varchar2(50),orderlot varchar2(30), ' ||
 ' po varchar2(20),linenumber number(5),carrier varchar2(4), ' ||
 ' billoflading varchar2(40),statusupdate date,movement varchar2(12),specialstock varchar2(12),reason varchar2(12), ' ||
 ' item varchar2(50),fromstorageloc varchar2(12),tostorageloc varchar2(12),qty number(7) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create view I9_ship_note_dtl_' || strSuffix ||
 ' (custid,loadno,orderid,shipid,reference,ctostonumber,orderitem,orderlot,po, ' ||
 ' linenumber,carrier,billoflading,statusupdate,movement,specialstock,reason, ' ||
 ' item,fromstorageloc,tostorageloc,qty) ' ||
 ' as select custid,loadno,orderid,shipid,reference,ctostonumber,orderitem, ' ||
 ' orderlot,po,linenumber,carrier,billoflading,statusupdate,movement,specialstock, ' ||
 ' reason,item,fromstorageloc,tostorageloc,sum(qty) from I9_ship_note_lips_' || strSuffix ||
 ' group by custid,loadno,orderid,shipid,reference,ctostonumber,orderitem,orderlot,po, ' ||
 ' linenumber,carrier,billoflading,statusupdate,movement,specialstock,reason, ' ||
 ' item,fromstorageloc,tostorageloc ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create view I9_ship_note_HDR_' || strSuffix ||
 ' (custid,loadno,orderid,shipid,reference,ctostonumber,orderitem,orderlot,po ' ||
 ' ,linenumber,carrier,billoflading,statusupdate,movement,specialstock,reason) ' ||
 ' as select distinct custid,loadno,orderid,shipid,reference,ctostonumber,orderitem, ' ||
 ' orderlot,po,linenumber,carrier,billoflading,statusupdate,movement, ' ||
 ' specialstock,reason from I9_ship_note_dtl_' || strSuffix;
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    add_dtl_rows(oh);
  end loop;
elsif in_loadno != 0 then
  for oh in curOrderHdrByLoad
  loop
    add_dtl_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
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
    add_dtl_rows(oh);
  end loop;
end if;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbi9sn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_I9_ship_note;

procedure end_I9_ship_note
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop view I9_ship_note_HDR_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop view I9_ship_note_DTL_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table I9_ship_note_lips_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zei9sn ' || sqlerrm;
  out_errorno := sqlcode;
end end_I9_ship_note;

FUNCTION max_rmatrackingno
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

out_rmatrackingno shippingplate.rmatrackingno%type;

begin

out_rmatrackingno := '';

select max(rmatrackingno)
  into out_rmatrackingno
  from shippingplate
 where orderid = in_orderid
   and shipid = in_shipid
   and parentlpid is null
   and rmatrackingno is not null
   and type in ('M','C');

return out_rmatrackingno;

exception when others then
  return out_rmatrackingno;
end max_rmatrackingno;

FUNCTION shipplate_rmatrackingno
(in_lpid IN varchar2
) return varchar2 is

out_rmatrackingno shippingplate.rmatrackingno%type;

begin

select rmatrackingno
  into out_rmatrackingno
  from shippingplate
 where lpid = in_lpid;

return out_rmatrackingno;

exception when others then
  return null;
end shipplate_rmatrackingno;

procedure begin_855_confirm
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdrByImportFileId is
  select *
    from orderhdr
   where importfileid = upper(in_importfileid);

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderHdrByConfirmDate is
  select *
    from orderhdr
   where custid = in_custid
     and confirmed >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and confirmed <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curOrderDtl(in_orderid number,in_shipid number) is
  select ORDERID,
          SHIPID,
          ITEM,
          CUSTID,
          FROMFACILITY,
          UOM,
          LINESTATUS,
          COMMITSTATUS,
          QTYENTERED,
          ITEMENTERED,
          UOMENTERED,
          QTYORDER,
          WEIGHTORDER,
          CUBEORDER,
          AMTORDER,
          QTYCOMMIT,
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
          QTYRCVDGOOD,
          WEIGHTRCVDGOOD,
          CUBERCVDGOOD,
          AMTRCVDGOOD,
          QTYRCVDDMGD,
          WEIGHTRCVDDMGD,
          CUBERCVDDMGD,
          AMTRCVDDMGD,
          STATUSUSER,
          STATUSUPDATE,
          LASTUSER,
          LASTUPDATE,
          PRIORITY,
          LOTNUMBER,
          BACKORDER,
          ALLOWSUB,
          QTYTYPE,
          INVSTATUSIND,
          INVSTATUS,
          INVCLASSIND,
          INVENTORYCLASS,
          QTYPICK,
          WEIGHTPICK,
          CUBEPICK,
          AMTPICK,
          CONSIGNEESKU,
          CHILDORDERID,
          CHILDSHIPID,
          STAFFHRS,
          QTY2SORT,
          WEIGHT2SORT,
          CUBE2SORT,
          AMT2SORT,
          QTY2PACK,
          WEIGHT2PACK,
          CUBE2PACK,
          AMT2PACK,
          QTY2CHECK,
          WEIGHT2CHECK,
          CUBE2CHECK,
          AMT2CHECK,
          DTLPASSTHRUCHAR01,
          DTLPASSTHRUCHAR02,
          DTLPASSTHRUCHAR03,
          DTLPASSTHRUCHAR04,
          DTLPASSTHRUCHAR05,
          DTLPASSTHRUCHAR06,
          DTLPASSTHRUCHAR07,
          DTLPASSTHRUCHAR08,
          DTLPASSTHRUCHAR09,
          DTLPASSTHRUCHAR10,
          DTLPASSTHRUCHAR11,
          DTLPASSTHRUCHAR12,
          DTLPASSTHRUCHAR13,
          DTLPASSTHRUCHAR14,
          DTLPASSTHRUCHAR15,
          DTLPASSTHRUCHAR16,
          DTLPASSTHRUCHAR17,
          DTLPASSTHRUCHAR18,
          DTLPASSTHRUCHAR19,
          DTLPASSTHRUCHAR20,
          DTLPASSTHRUNUM01,
          DTLPASSTHRUNUM02,
          DTLPASSTHRUNUM03,
          DTLPASSTHRUNUM04,
          DTLPASSTHRUNUM05,
          DTLPASSTHRUNUM06,
          DTLPASSTHRUNUM07,
          DTLPASSTHRUNUM08,
          DTLPASSTHRUNUM09,
          DTLPASSTHRUNUM10,
          ASNVARIANCE,
          CANCELREASON,
          RFAUTODISPLAY,
          XDOCKORDERID,
          XDOCKSHIPID,
          XDOCKLOCID
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderDtlLine(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(OL.xdock,'N') = 'N'
   order by nvl(ol.dtlpassthrunum10,nvl(od.dtlpassthrunum10,0));
ol curOrderDtlLine%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
dteTest date;
strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strDescr orderstatus.descr%type;
strUnStatus orderstatus.abbrev%type;
strDmgStatus orderstatus.abbrev%type;
strshipParm orderstatus.abbrev%type;
strMovement orderstatus.abbrev%type;
strReason orderstatus.abbrev%type;
strCarrier loads.carrier%type;
qtyRemain shippingplate.quantity%type;
qtyLineNumber shippingplate.quantity%type;
prm licenseplatestatus%rowtype;
qtyConfirm orderdtl.qtyorder%type;

procedure add_dtl_rows(oh orderhdr%rowtype) is
begin
--  zut.prt('add detail rows');
  zmi3.get_cust_parm_value(oh.custid,'REGORDTYPES',prm.descr,prm.abbrev);
  if instr(prm.abbrev,oh.ordertype) <> 0 then
    for od in curOrderDtl(oh.orderid,oh.shipid)
    loop
      qtyConfirm := nvl(od.qtycommit,0) + nvl(od.qtypick,0);
      for ol in curOrderDtlLine(oh.orderid,oh.shipid,od.item,od.lotnumber)
      loop
        if qtyConfirm >= ol.qty then
          qtyLineNumber := ol.qty;
        else
          qtyLineNumber := qtyConfirm;
        end if;
        curSql := dbms_sql.open_cursor;
        dbms_sql.parse(curSql, 'insert into confirm_855_line_' || strSuffix ||
          ' values (:ORDERID,:SHIPID,:ITEM,:CUSTID,:FROMFACILITY,:UOM' ||
',:LINESTATUS,:COMMITSTATUS,:QTYENTERED,:ITEMENTERED,:UOMENTERED,:QTYORDER' ||
',:WEIGHTORDER,:CUBEORDER,:AMTORDER,:QTYCOMMIT,:WEIGHTCOMMIT,:CUBECOMMIT' ||
',:AMTCOMMIT,:QTYSHIP,:WEIGHTSHIP,:CUBESHIP,:AMTSHIP,:QTYTOTCOMMIT' ||
',:WEIGHTTOTCOMMIT,:CUBETOTCOMMIT,:AMTTOTCOMMIT,:QTYRCVD,:WEIGHTRCVD' ||
',:CUBERCVD,:AMTRCVD,:QTYRCVDGOOD,:WEIGHTRCVDGOOD,:CUBERCVDGOOD' ||
',:AMTRCVDGOOD,:QTYRCVDDMGD,:WEIGHTRCVDDMGD,:CUBERCVDDMGD,:AMTRCVDDMGD' ||
',:STATUSUSER,:STATUSUPDATE,:LASTUSER,:LASTUPDATE,:PRIORITY' ||
',:LOTNUMBER,:BACKORDER,:ALLOWSUB,:QTYTYPE,:INVSTATUSIND,:INVSTATUS' ||
',:INVCLASSIND,:INVENTORYCLASS,:QTYPICK,:WEIGHTPICK,:CUBEPICK,:AMTPICK' ||
',:CONSIGNEESKU,:CHILDORDERID,:CHILDSHIPID,:STAFFHRS,:QTY2SORT,:WEIGHT2SORT' ||
',:CUBE2SORT,:AMT2SORT,:QTY2PACK,:WEIGHT2PACK,:CUBE2PACK,:AMT2PACK,:QTY2CHECK' ||
',:WEIGHT2CHECK,:CUBE2CHECK,:AMT2CHECK,:DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02' ||
',:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,:DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06' ||
',:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,:DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10' ||
',:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,:DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14' ||
',:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,:DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18' ||
',:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,:DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02' ||
',:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,:DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06' ||
',:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,:DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10' ||
',:ASNVARIANCE,:CANCELREASON,:RFAUTODISPLAY,:XDOCKORDERID,:XDOCKSHIPID' ||
',:XDOCKLOCID)',dbms_sql.native);
        dbms_sql.bind_variable(curSql, ':orderid', od.orderid);
        dbms_sql.bind_variable(curSql, ':shipid', od.shipid);
        dbms_sql.bind_variable(curSql, ':ITEM', od.ITEM);
        dbms_sql.bind_variable(curSql, ':CUSTID', od.CUSTID);
        dbms_sql.bind_variable(curSql, ':FROMFACILITY', od.FROMFACILITY);
        dbms_sql.bind_variable(curSql, ':UOM', od.UOM);
        dbms_sql.bind_variable(curSql, ':LINESTATUS', od.LINESTATUS);
        dbms_sql.bind_variable(curSql, ':COMMITSTATUS', od.COMMITSTATUS);
        dbms_sql.bind_variable(curSql, ':QTYENTERED', od.QTYENTERED);
        dbms_sql.bind_variable(curSql, ':ITEMENTERED', od.ITEMENTERED);
        dbms_sql.bind_variable(curSql, ':UOMENTERED', od.UOMENTERED);
        dbms_sql.bind_variable(curSql, ':QTYORDER', ol.qty);
        dbms_sql.bind_variable(curSql, ':WEIGHTORDER', od.WEIGHTORDER);
        dbms_sql.bind_variable(curSql, ':CUBEORDER', od.CUBEORDER);
        dbms_sql.bind_variable(curSql, ':AMTORDER', od.AMTORDER);
        dbms_sql.bind_variable(curSql, ':QTYCOMMIT', qtyLineNumber);
        dbms_sql.bind_variable(curSql, ':WEIGHTCOMMIT', od.WEIGHTCOMMIT);
        dbms_sql.bind_variable(curSql, ':CUBECOMMIT', od.CUBECOMMIT);
        dbms_sql.bind_variable(curSql, ':AMTCOMMIT', od.AMTCOMMIT);
        dbms_sql.bind_variable(curSql, ':QTYSHIP', od.QTYSHIP);
        dbms_sql.bind_variable(curSql, ':WEIGHTSHIP', od.WEIGHTSHIP);
        dbms_sql.bind_variable(curSql, ':CUBESHIP', od.CUBESHIP);
        dbms_sql.bind_variable(curSql, ':AMTSHIP', od.AMTSHIP);
        dbms_sql.bind_variable(curSql, ':QTYTOTCOMMIT', od.QTYTOTCOMMIT);
        dbms_sql.bind_variable(curSql, ':WEIGHTTOTCOMMIT', od.WEIGHTTOTCOMMIT);
        dbms_sql.bind_variable(curSql, ':CUBETOTCOMMIT', od.CUBETOTCOMMIT);
        dbms_sql.bind_variable(curSql, ':AMTTOTCOMMIT', od.AMTTOTCOMMIT);
        dbms_sql.bind_variable(curSql, ':QTYRCVD', od.QTYRCVD);
        dbms_sql.bind_variable(curSql, ':WEIGHTRCVD', od.WEIGHTRCVD);
        dbms_sql.bind_variable(curSql, ':CUBERCVD', od.CUBERCVD);
        dbms_sql.bind_variable(curSql, ':AMTRCVD', od.AMTRCVD);
        dbms_sql.bind_variable(curSql, ':QTYRCVDGOOD', od.QTYRCVDGOOD);
        dbms_sql.bind_variable(curSql, ':WEIGHTRCVDGOOD', od.WEIGHTRCVDGOOD);
        dbms_sql.bind_variable(curSql, ':CUBERCVDGOOD', od.CUBERCVDGOOD);
        dbms_sql.bind_variable(curSql, ':AMTRCVDGOOD', od.AMTRCVDGOOD);
        dbms_sql.bind_variable(curSql, ':QTYRCVDDMGD', od.QTYRCVDDMGD);
        dbms_sql.bind_variable(curSql, ':WEIGHTRCVDDMGD', od.WEIGHTRCVDDMGD);
        dbms_sql.bind_variable(curSql, ':CUBERCVDDMGD', od.CUBERCVDDMGD);
        dbms_sql.bind_variable(curSql, ':AMTRCVDDMGD', od.AMTRCVDDMGD);
        dbms_sql.bind_variable(curSql, ':STATUSUSER', od.STATUSUSER);
        dbms_sql.bind_variable(curSql, ':STATUSUPDATE', od.STATUSUPDATE);
        dbms_sql.bind_variable(curSql, ':LASTUSER', od.LASTUSER);
        dbms_sql.bind_variable(curSql, ':LASTUPDATE', od.LASTUPDATE);
        dbms_sql.bind_variable(curSql, ':PRIORITY', od.PRIORITY);
        dbms_sql.bind_variable(curSql, ':LOTNUMBER', od.LOTNUMBER);
        dbms_sql.bind_variable(curSql, ':BACKORDER', od.BACKORDER);
        dbms_sql.bind_variable(curSql, ':ALLOWSUB', od.ALLOWSUB);
        dbms_sql.bind_variable(curSql, ':QTYTYPE', od.QTYTYPE);
        dbms_sql.bind_variable(curSql, ':INVSTATUSIND', od.INVSTATUSIND);
        dbms_sql.bind_variable(curSql, ':INVSTATUS', od.INVSTATUS);
        dbms_sql.bind_variable(curSql, ':INVCLASSIND', od.INVCLASSIND);
        dbms_sql.bind_variable(curSql, ':INVENTORYCLASS', od.INVENTORYCLASS);
        dbms_sql.bind_variable(curSql, ':QTYPICK', od.QTYPICK);
        dbms_sql.bind_variable(curSql, ':WEIGHTPICK', od.WEIGHTPICK);
        dbms_sql.bind_variable(curSql, ':CUBEPICK', od.CUBEPICK);
        dbms_sql.bind_variable(curSql, ':AMTPICK', od.AMTPICK);
        dbms_sql.bind_variable(curSql, ':CONSIGNEESKU', od.CONSIGNEESKU);
        dbms_sql.bind_variable(curSql, ':CHILDORDERID', od.CHILDORDERID);
        dbms_sql.bind_variable(curSql, ':CHILDSHIPID', od.CHILDSHIPID);
        dbms_sql.bind_variable(curSql, ':STAFFHRS', od.STAFFHRS);
        dbms_sql.bind_variable(curSql, ':QTY2SORT', od.QTY2SORT);
        dbms_sql.bind_variable(curSql, ':WEIGHT2SORT', od.WEIGHT2SORT);
        dbms_sql.bind_variable(curSql, ':CUBE2SORT', od.CUBE2SORT);
        dbms_sql.bind_variable(curSql, ':AMT2SORT', od.AMT2SORT);
        dbms_sql.bind_variable(curSql, ':QTY2PACK', od.QTY2PACK);
        dbms_sql.bind_variable(curSql, ':WEIGHT2PACK', od.WEIGHT2PACK);
        dbms_sql.bind_variable(curSql, ':CUBE2PACK', od.CUBE2PACK);
        dbms_sql.bind_variable(curSql, ':AMT2PACK', od.AMT2PACK);
        dbms_sql.bind_variable(curSql, ':QTY2CHECK', od.QTY2CHECK);
        dbms_sql.bind_variable(curSql, ':WEIGHT2CHECK', od.WEIGHT2CHECK);
        dbms_sql.bind_variable(curSql, ':CUBE2CHECK', od.CUBE2CHECK);
        dbms_sql.bind_variable(curSql, ':AMT2CHECK', od.AMT2CHECK);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR01', od.DTLPASSTHRUCHAR01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR02', od.DTLPASSTHRUCHAR02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR03', od.DTLPASSTHRUCHAR03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR04', od.DTLPASSTHRUCHAR04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR05', od.DTLPASSTHRUCHAR05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR06', od.DTLPASSTHRUCHAR06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR07', od.DTLPASSTHRUCHAR07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR08', od.DTLPASSTHRUCHAR08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR09', od.DTLPASSTHRUCHAR09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR10', od.DTLPASSTHRUCHAR10);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR11', od.DTLPASSTHRUCHAR11);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR12', od.DTLPASSTHRUCHAR12);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR13', od.DTLPASSTHRUCHAR13);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR14', od.DTLPASSTHRUCHAR14);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR15', od.DTLPASSTHRUCHAR15);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR16', od.DTLPASSTHRUCHAR16);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR17', od.DTLPASSTHRUCHAR17);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR18', od.DTLPASSTHRUCHAR18);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR19', od.DTLPASSTHRUCHAR19);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUCHAR20', od.DTLPASSTHRUCHAR20);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM01', od.DTLPASSTHRUNUM01);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM02', od.DTLPASSTHRUNUM02);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM03', od.DTLPASSTHRUNUM03);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM04', od.DTLPASSTHRUNUM04);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM05', od.DTLPASSTHRUNUM05);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM06', od.DTLPASSTHRUNUM06);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM07', od.DTLPASSTHRUNUM07);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM08', od.DTLPASSTHRUNUM08);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM09', od.DTLPASSTHRUNUM09);
        dbms_sql.bind_variable(curSql, ':DTLPASSTHRUNUM10', ol.linenumber);
        dbms_sql.bind_variable(curSql, ':ASNVARIANCE', od.ASNVARIANCE);
        dbms_sql.bind_variable(curSql, ':CANCELREASON', od.CANCELREASON);
        dbms_sql.bind_variable(curSql, ':RFAUTODISPLAY', od.RFAUTODISPLAY);
        dbms_sql.bind_variable(curSql, ':XDOCKORDERID', od.XDOCKORDERID);
        dbms_sql.bind_variable(curSql, ':XDOCKSHIPID', od.XDOCKSHIPID);
        dbms_sql.bind_variable(curSql, ':XDOCKLOCID', od.XDOCKLOCID);
        cntRows := dbms_sql.execute(curSql);
        dbms_sql.close_cursor(curSql);
        qtyConfirm := qtyConfirm - qtyLineNumber;
      end loop; -- orderdtlline
    end loop; -- orderdtl
  end if;
end;

begin

out_errorno := 0;
out_msg := '';

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'CONFIRM_855_LINE_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

--zut.prt('create table i44');
cmdSql := 'create table CONFIRM_855_LINE_' || strSuffix ||
'(ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null ' ||
',item varchar2(50) not null,CUSTID VARCHAR2(10),FROMFACILITY VARCHAR2(3) ' ||
',UOM VARCHAR2(4),LINESTATUS VARCHAR2(1),COMMITSTATUS VARCHAR2(1) ' ||
',QTYENTERED NUMBER(7),ITEMENTERED VARCHAR2(20),UOMENTERED VARCHAR2(4) ' ||
',QTYORDER NUMBER(7),WEIGHTORDER NUMBER(17,8),CUBEORDER NUMBER(10,4) ' ||
',AMTORDER NUMBER(10,2),QTYCOMMIT NUMBER(7),WEIGHTCOMMIT NUMBER(17,8) ' ||
',CUBECOMMIT NUMBER(10,4),AMTCOMMIT NUMBER(10,2),QTYSHIP NUMBER(7) ' ||
',WEIGHTSHIP NUMBER(17,8),CUBESHIP NUMBER(10,4),AMTSHIP NUMBER(10,2) ' ||
',QTYTOTCOMMIT NUMBER(7),WEIGHTTOTCOMMIT NUMBER(17,8) ' ||
',CUBETOTCOMMIT NUMBER(10,4),AMTTOTCOMMIT NUMBER(10,2),QTYRCVD NUMBER(7) ' ||
',WEIGHTRCVD NUMBER(17,8),CUBERCVD NUMBER(10,4),AMTRCVD NUMBER(10,2) ' ||
',QTYRCVDGOOD NUMBER(7),WEIGHTRCVDGOOD NUMBER(17,8),CUBERCVDGOOD NUMBER(10,4) ' ||
',AMTRCVDGOOD NUMBER(10,2),QTYRCVDDMGD NUMBER(7),WEIGHTRCVDDMGD NUMBER(17,8) ' ||
',CUBERCVDDMGD NUMBER(10,4),AMTRCVDDMGD NUMBER(10,2) ' ||
',STATUSUSER VARCHAR2(12),STATUSUPDATE DATE,LASTUSER VARCHAR2(12), ' ||
' LASTUPDATE DATE,PRIORITY VARCHAR2(1),LOTNUMBER VARCHAR2(30) ' ||
',BACKORDER VARCHAR2(2),ALLOWSUB VARCHAR2(1),QTYTYPE VARCHAR2(1) ' ||
',INVSTATUSIND VARCHAR2(1),INVSTATUS VARCHAR2(255),INVCLASSIND VARCHAR2(1) ' ||
',INVENTORYCLASS VARCHAR2(255),QTYPICK NUMBER(7),WEIGHTPICK NUMBER(17,8) ' ||
',CUBEPICK NUMBER(10,4),AMTPICK NUMBER(10,2),CONSIGNEESKU VARCHAR2(20) ' ||
',CHILDORDERID NUMBER(9),CHILDSHIPID NUMBER(2),STAFFHRS NUMBER(10,4) ' ||
',QTY2SORT NUMBER(7),WEIGHT2SORT NUMBER(17,8),CUBE2SORT NUMBER(10,4) ' ||
',AMT2SORT NUMBER(10,2),QTY2PACK NUMBER(7),WEIGHT2PACK NUMBER(17,8) ' ||
',CUBE2PACK NUMBER(10,4),AMT2PACK NUMBER(10,2),QTY2CHECK NUMBER(7) ' ||
',WEIGHT2CHECK NUMBER(17,8),CUBE2CHECK NUMBER(10,4),AMT2CHECK NUMBER(10,2) ' ||
',DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255) ' ||
',DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255) ' ||
',DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4) ' ||
',DTLPASSTHRUNUM03 NUMBER(16,4),DTLPASSTHRUNUM04 NUMBER(16,4) ' ||
',DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4) ' ||
',DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4) ' ||
',DTLPASSTHRUNUM09 NUMBER(16,4),DTLPASSTHRUNUM10 NUMBER(16,4) ' ||
',ASNVARIANCE CHAR(1),CANCELREASON VARCHAR2(12),RFAUTODISPLAY VARCHAR2(1) ' ||
',XDOCKORDERID NUMBER(9),XDOCKSHIPID NUMBER(2),XDOCKLOCID VARCHAR2(10)) ';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'create view CONFIRM_855_HDR_' || strSuffix ||
 ' (ORDERID,SHIPID,CUSTID,ORDERTYPE,ENTRYDATE,APPTDATE,SHIPDATE,PO,RMA,' ||
 ' ORDERSTATUS,COMMITSTATUS,FROMFACILITY,TOFACILITY,LOADNO,STOPNO,' ||
 ' SHIPNO,SHIPTO,DELAREA,QTYORDER,WEIGHTORDER,CUBEORDER,AMTORDER,' ||
 ' QTYCOMMIT,WEIGHTCOMMIT,CUBECOMMIT,AMTCOMMIT,QTYSHIP,WEIGHTSHIP,CUBESHIP,' ||
 ' AMTSHIP,QTYTOTCOMMIT,WEIGHTTOTCOMMIT,CUBETOTCOMMIT,AMTTOTCOMMIT,' ||
 ' QTYRCVD,WEIGHTRCVD,CUBERCVD,AMTRCVD,STATUSUSER,STATUSUPDATE,' ||
 ' LASTUSER,LASTUPDATE,BILLOFLADING,PRIORITY,SHIPPER,ARRIVALDATE,' ||
 ' CONSIGNEE,SHIPTYPE,CARRIER,REFERENCE,SHIPTERMS,WAVE,STAGELOC,' ||
 ' QTYPICK,WEIGHTPICK,CUBEPICK,AMTPICK,SHIPTONAME,SHIPTOCONTACT,' ||
 ' SHIPTOADDR1,SHIPTOADDR2,SHIPTOCITY,SHIPTOSTATE,SHIPTOPOSTALCODE,' ||
 ' SHIPTOCOUNTRYCODE,SHIPTOPHONE,SHIPTOFAX,SHIPTOEMAIL,BILLTONAME,' ||
 ' BILLTOCONTACT,BILLTOADDR1,BILLTOADDR2,BILLTOCITY,BILLTOSTATE,' ||
 ' BILLTOPOSTALCODE,BILLTOCOUNTRYCODE,BILLTOPHONE,BILLTOFAX,' ||
 ' BILLTOEMAIL,PARENTORDERID,PARENTSHIPID,PARENTORDERITEM,PARENTORDERLOT,' ||
 ' WORKORDERSEQ,STAFFHRS,QTY2SORT,WEIGHT2SORT,CUBE2SORT,AMT2SORT,' ||
 ' QTY2PACK,WEIGHT2PACK,CUBE2PACK,AMT2PACK,QTY2CHECK,WEIGHT2CHECK,' ||
 ' CUBE2CHECK,AMT2CHECK,IMPORTFILEID,HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,' ||
 ' HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,' ||
 ' HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,' ||
 ' HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,' ||
 ' HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,' ||
 ' HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,' ||
 ' HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,' ||
 ' HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,' ||
 ' CONFIRMED,rejectcode,rejecttext,dateshipped,linecount,' ||
 ' packlistshipdate,edicancelpending,deliveryservice,saturdaydelivery) ' ||
 ' as select distinct oh.ORDERID,oh.SHIPID,oh.CUSTID,oh.ORDERTYPE,' ||
 'ENTRYDATE,oh.APPTDATE,oh.SHIPDATE,oh.PO,oh.RMA,oh.ORDERSTATUS,oh.COMMITSTATUS,oh.FROMFACILITY,oh.' ||
 'TOFACILITY,oh.LOADNO,oh.STOPNO,oh.SHIPNO,oh.SHIPTO,oh.DELAREA,oh.QTYORDER,oh.WEIGHTORDER,oh.' ||
 'CUBEORDER,oh.AMTORDER,oh.QTYCOMMIT,oh.WEIGHTCOMMIT,oh.CUBECOMMIT,oh.AMTCOMMIT,oh.QTYSHIP,oh.' ||
 'WEIGHTSHIP,oh.CUBESHIP,oh.AMTSHIP,oh.QTYTOTCOMMIT,oh.WEIGHTTOTCOMMIT,oh.CUBETOTCOMMIT,oh.' ||
 'AMTTOTCOMMIT,oh.QTYRCVD,oh.WEIGHTRCVD,oh.CUBERCVD,oh.AMTRCVD,oh.STATUSUSER,oh.' ||
 'STATUSUPDATE,oh.LASTUSER,oh.LASTUPDATE,oh.BILLOFLADING,oh.PRIORITY,oh.SHIPPER,oh.' ||
 'ARRIVALDATE,oh.CONSIGNEE,oh.SHIPTYPE,oh.CARRIER,oh.REFERENCE,oh.SHIPTERMS,oh.WAVE,oh.' ||
 'STAGELOC,oh.QTYPICK,oh.WEIGHTPICK,oh.CUBEPICK,oh.AMTPICK,oh.SHIPTONAME,oh.' ||
 'SHIPTOCONTACT,oh.SHIPTOADDR1,oh.SHIPTOADDR2,oh.SHIPTOCITY,oh.SHIPTOSTATE,oh.' ||
 'SHIPTOPOSTALCODE,oh.SHIPTOCOUNTRYCODE,oh.SHIPTOPHONE,oh.SHIPTOFAX,oh.SHIPTOEMAIL,oh.' ||
 'BILLTONAME,oh.BILLTOCONTACT,oh.BILLTOADDR1,oh.BILLTOADDR2,oh.BILLTOCITY,oh.' ||
 'BILLTOSTATE,oh.BILLTOPOSTALCODE,oh.BILLTOCOUNTRYCODE,oh.BILLTOPHONE,oh.BILLTOFAX,oh.' ||
 'BILLTOEMAIL,oh.PARENTORDERID,oh.PARENTSHIPID,oh.PARENTORDERITEM,oh.PARENTORDERLOT,oh.' ||
 'WORKORDERSEQ,oh.STAFFHRS,oh.QTY2SORT,oh.WEIGHT2SORT,oh.CUBE2SORT,oh.AMT2SORT,oh.QTY2PACK,oh.' ||
 'WEIGHT2PACK,oh.CUBE2PACK,oh.AMT2PACK,oh.QTY2CHECK,oh.WEIGHT2CHECK,oh.CUBE2CHECK,oh.' ||
 'AMT2CHECK,oh.IMPORTFILEID,oh.HDRPASSTHRUCHAR01,oh.HDRPASSTHRUCHAR02,oh.' ||
 'HDRPASSTHRUCHAR03,oh.HDRPASSTHRUCHAR04,oh.HDRPASSTHRUCHAR05,oh.HDRPASSTHRUCHAR06,oh.' ||
 'HDRPASSTHRUCHAR07,oh.HDRPASSTHRUCHAR08,oh.HDRPASSTHRUCHAR09,oh.HDRPASSTHRUCHAR10,oh.' ||
 'HDRPASSTHRUCHAR11,oh.HDRPASSTHRUCHAR12,oh.HDRPASSTHRUCHAR13,oh.HDRPASSTHRUCHAR14,oh.' ||
 'HDRPASSTHRUCHAR15,oh.HDRPASSTHRUCHAR16,oh.HDRPASSTHRUCHAR17,oh.HDRPASSTHRUCHAR18,oh.' ||
 'HDRPASSTHRUCHAR19,oh.HDRPASSTHRUCHAR20,oh.HDRPASSTHRUNUM01,oh.HDRPASSTHRUNUM02,oh.' ||
 'HDRPASSTHRUNUM03,oh.HDRPASSTHRUNUM04,oh.HDRPASSTHRUNUM05,oh.HDRPASSTHRUNUM06,oh.' ||
 'HDRPASSTHRUNUM07,oh.HDRPASSTHRUNUM08,oh.HDRPASSTHRUNUM09,oh.HDRPASSTHRUNUM10,' ||
 'nvl(oh.CONFIRMED,sysdate),oh.rejectcode,oh.rejecttext,oh.dateshipped,' ||
 'zoe.orderdtl_line_count(oh.orderid,oh.shipid),oh.packlistshipdate,' ||
 'nvl(oh.edicancelpending,''N''),oh.deliveryservice,oh.saturdaydelivery ' ||
 '  from orderhdr oh, confirm_855_line_' || strSuffix || ' dtl ' ||
 ' where oh.orderid = dtl.orderid ' ||
 ' and oh.shipid = dtl.shipid';
curSql := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

--zut.prt('view created checking orderid');
if rtrim(in_importfileid) is not null then
  for oh in curOrderHdrByImportFileId
  loop
    add_dtl_rows(oh);
  end loop;
elsif in_orderid != 0 then
  for oh in curOrderHdr
  loop
    add_dtl_rows(oh);
  end loop;
elsif rtrim(in_begdatestr) is not null then
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
  for oh in curOrderHdrByConfirmDate
  loop
    add_dtl_rows(oh);
  end loop;
end if;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zb855l ' || sqlerrm;
  out_errorno := sqlcode;
end begin_855_confirm;

procedure end_855_confirm
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(255);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop view confirm_855_hdr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table confirm_855_line_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'ze855l ' || sqlerrm;
  out_errorno := sqlcode;
end end_855_confirm;

end zimportproc5;
/
show error package body zimportproc5;
exit;

