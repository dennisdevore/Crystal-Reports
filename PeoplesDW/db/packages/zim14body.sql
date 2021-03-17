create or replace package body alps.zimportproc14 as
--
-- $Id$
--

procedure update_confirm_date_by_orderid
(in_orderid IN number
,in_shipid IN number
,in_confirmdate IN date
,in_userid varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

out_msg := '';
out_errorno := 0;

update orderhdr
   set confirmed = in_confirmdate,
       edicancelpending = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

if sql%rowcount != 1 then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
else
  out_errorno := 0;
  out_msg := 'OKAY';
end if;

exception when others then
  out_msg := 'zimucd ' || sqlerrm;
  out_errorno := sqlcode;
end update_confirm_date_by_orderid;

procedure begin_med_inv_adj
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curInvAdjActivity is
  select facility,
         item,
         uom,
         invstatus,
         adjreason,
         adjqty
    from invadjactivity
   where whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and whenoccurred < to_date(in_enddatestr,'yyyymmddhh24miss')
     and custid = in_custid
     and nvl(suppress_edi_yn,'N') != 'Y';

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
dteTest date;
strCategory varchar2(12);
strAdjReason varchar2(12);
strMsg varchar2(255);
qtyGood number(12);
qtyDamaged number(12);
qtyOther number(12);
strSign char(1);

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
   where table_name = upper('med_inv_adj_cat_' || strSuffix);
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

cmdSql := 'create table med_inv_adj_cat_' || strSuffix ||
 ' (FACILITY VARCHAR2(3),CUSTID VARCHAR2(10),'||
 ' item varchar2(50), UOM VARCHAR2(4), category varchar2(12),'||
 ' adjreason varchar2(12), adjsign char(1), qtygood NUMBER(12), qtydamaged NUMBER(12),' ||
 ' qtyother number(12))';
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

for aj in curInvAdjActivity
loop
  cmdSql := 'select substr(abbrev,1,1) from invstatus_category_' || rtrim(in_custid) ||
    ' where code = ''' || aj.invstatus || '''';
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,strCategory,12);
  strCategory := '3';
  cntRows := dbms_sql.execute(curSql);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    if cntRows <= 0 then
      exit;
    end if;
    dbms_sql.column_value(curSql,1,strCategory);
  end loop;
  dbms_sql.close_cursor(curSql);
  begin
    select abbrev
      into strAdjReason
      from adjustmentreasons
     where code = aj.adjreason;
  exception when others then
    strAdjReason := 'Unknown';
  end;
  qtyGood := 0;
  qtyDamaged := 0;
  qtyOther := 0;
  if substr(strCategory,1,1) = '1' then
    qtyGood := aj.adjqty;
  elsif substr(strCategory,1,1) = '2' then
    qtyDamaged := aj.adjqty;
  else
    qtyOther := aj.adjqty;
  end if;
  if aj.adjqty < 0 then
    strSign := '-';
  else
    strSign := '+';
  end if;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, 'insert into med_inv_adj_cat_' || strSuffix ||
    ' values (:facility,:custid,:item,:uom,:category,:adjreason,:adjsign,:qtygood,'||
    ':qtydamaged,:qtyother)',
    dbms_sql.native);
  dbms_sql.bind_variable(curSql, ':facility', aj.facility);
  dbms_sql.bind_variable(curSql, ':custid', in_custid);
  dbms_sql.bind_variable(curSql, ':item', aj.item);
  dbms_sql.bind_variable(curSql, ':uom', aj.uom);
  dbms_sql.bind_variable(curSql, ':category', strCategory);
  dbms_sql.bind_variable(curSql, ':adjreason', strAdjReason);
  dbms_sql.bind_variable(curSql, ':adjsign', strSign);
  dbms_sql.bind_variable(curSql, ':qtygood', qtyGood);
  dbms_sql.bind_variable(curSql, ':qtydamaged', qtyDamaged);
  dbms_sql.bind_variable(curSql, ':qtyother', qtyOther);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
end loop;

cmdSql := 'create view med_inv_adj_dtl_' || strSuffix ||
 '(fromdate,todate,facility,custid,item,strItem,uom,category,adjreason,adjsign,' ||
 ' qtygood,qtydamaged,qtyother,qtynet) ' ||
 ' as select to_date(''' || in_begdatestr || ''',''yyyymmddhh24miss''),' ||
 ' to_date(''' || in_enddatestr || ''',''yyyymmddhh24miss''),' ||
 ' facility, custid, item, ''Item '' || item, uom, category, adjreason, adjsign,' ||
 ' sum(qtygood),sum(qtydamaged),sum(qtyother),sum(qtygood+qtydamaged+qtyother) ' ||
 ' from med_inv_adj_cat_' || strSuffix ||
 ' group by 1,2,facility,custid,item,''Item '' || item,uom,category,adjreason,adjsign';
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

cmdSql := 'create view med_inv_adj_hdr_' || strSuffix ||
 '(fromdate,todate,facility,custid,item,stritem,uom,' ||
 ' qtygood,qtydamaged,qtyother,qtynet)' ||
 ' as select fromdate, todate, facility, custid, item, stritem, uom, ' ||
 ' sum(qtygood),sum(qtydamaged),sum(qtyother),sum(qtynet) ' ||
 ' from med_inv_adj_dtl_' || strSuffix ||
 ' group by fromdate,todate,facility,custid,item,strItem,uom';
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

cmdSql := 'create view med_inv_adj_sum_' || strSuffix ||
 '(fromdate,todate,facility,custid,qtygood,qtydamaged,qtyother,qtynet)' ||
 ' as select fromdate, todate, facility, custid, ' ||
 ' sum(qtygood),sum(qtydamaged),sum(qtyother),sum(qtynet) ' ||
 ' from med_inv_adj_hdr_' || strSuffix ||
 ' group by fromdate,todate,facility,custid';
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

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbmedsn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_med_inv_adj;

procedure end_med_inv_adj
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

cmdSql := 'drop view med_inv_adj_sum_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop view med_inv_adj_hdr_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop view med_inv_adj_dtl_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table med_inv_adj_cat_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zemedsn ' || sqlerrm;
  out_errorno := sqlcode;
end end_med_inv_adj;

procedure begin_med_shipments
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdrs is
  select statusupdate,
         fromfacility,
         custid,
         orderid,
         shipid,
         reference,
         po
    from orderhdr
   where statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate < to_date(in_enddatestr,'yyyymmddhh24miss')
     and orderstatus = '9'
     and custid = in_custid;

cursor curOrderDtls(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         uom,
         uomentered,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyship,0) as qtyship,
         nvl(dtlpassthrunum10,0) as dtlpassthrunum10
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderDtlLines(in_orderid number, in_shipid number, in_item varchar2,
  in_lotnumber varchar2) is
  select linenumber,
         qty
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
     and nvl(xdock,'N') = 'N'
   order by linenumber;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
qtyRemain orderdtl.qtyship%type;
cntLines integer;
strMsg varchar2(255);
dtl med_shipments%rowtype;
qtyEquiv number;
uombase custitem.baseuom%type;
uomentered custitem.baseuom%type;

procedure add_dtl_row is
begin

qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,uombase,dtl.qtyorder,uomentered);
if mod(qtyEquiv,1) = 0 then
  dtl.uomorder := uomentered;
  dtl.qtyorder := qtyEquiv;
else
  dtl.uomorder := uombase;
end if;

qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,uombase,dtl.qtyship,uomentered);
if mod(qtyEquiv,1) = 0 then
  dtl.uomship := uomentered;
  dtl.qtyship := qtyEquiv;
else
  dtl.uomship := uombase;
end if;

curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, 'insert into med_shipments_' || strSuffix ||
  ' values (:fromdate,:todate,:shipdate,:facility,:custid,:orderid,:shipid,' ||
  ':reference,:po,:item,:lotnumber,:linenumber,:uomorder,:qtyorder,'||
  ':uomship,:qtyship)',
  dbms_sql.native);
dbms_sql.bind_variable(curSql, ':fromdate', dtl.fromdate);
dbms_sql.bind_variable(curSql, ':todate', dtl.todate);
dbms_sql.bind_variable(curSql, ':shipdate', dtl.shipdate);
dbms_sql.bind_variable(curSql, ':facility', dtl.facility);
dbms_sql.bind_variable(curSql, ':custid', dtl.custid);
dbms_sql.bind_variable(curSql, ':orderid', dtl.orderid);
dbms_sql.bind_variable(curSql, ':shipid', dtl.shipid);
dbms_sql.bind_variable(curSql, ':reference', dtl.reference);
dbms_sql.bind_variable(curSql, ':po', dtl.po);
dbms_sql.bind_variable(curSql, ':item', dtl.item);
dbms_sql.bind_variable(curSql, ':lotnumber', dtl.lotnumber);
dbms_sql.bind_variable(curSql, ':linenumber', dtl.linenumber);
dbms_sql.bind_variable(curSql, ':uomorder', dtl.uomorder);
dbms_sql.bind_variable(curSql, ':qtyorder', dtl.qtyorder);
dbms_sql.bind_variable(curSql, ':uomship', dtl.uomship);
dbms_sql.bind_variable(curSql, ':qtyship', dtl.qtyship);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

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
   where table_name = upper('med_shipments_' || strSuffix);
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

begin
  dtl.fromdate := to_date(in_begdatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -1;
  out_msg := 'Invalid begin date string ' || in_begdatestr;
  return;
end;

begin
  dtl.todate := to_date(in_enddatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -2;
  out_msg := 'Invalid end date string ' || in_enddatestr;
  return;
end;

cmdSql := 'create table med_shipments_' || strSuffix ||
 ' (FROMDATE DATE,TODATE DATE,SHIPDATE DATE,FACILITY VARCHAR2(3)'||
 ',CUSTID VARCHAR2(10) not null,ORDERID NUMBER(9) not null'||
 ',SHIPID NUMBER(2) not null,REFERENCE VARCHAR2(20),PO VARCHAR2(20)'||
 ',item varchar2(50) not null,LOTNUMBER VARCHAR2(30),LINENUMBER NUMBER(16,4)'||
 ',uomorder varchar2(4),QTYORDER NUMBER(7),uomship varchar2(4),QTYSHIP NUMBER(7))';
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

for oh in curOrderHdrs
loop
  dtl.shipdate := oh.statusupdate;
  dtl.facility := oh.fromfacility;
  dtl.custid := oh.custid;
  dtl.orderid := oh.orderid;
  dtl.shipid := oh.shipid;
  dtl.reference := oh.reference;
  dtl.po := oh.po;
  for od in curOrderDtls(oh.orderid,oh.shipid)
  loop
    uombase := od.uom;
    uomentered := od.uomentered;
    dtl.item := od.item;
    dtl.lotnumber := od.lotnumber;
    cntLines := 0;
    qtyRemain := od.qtyship;
    for ol in curOrderDtlLines(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      cntLines := cntLines + 1;
      dtl.linenumber := ol.linenumber;
      dtl.qtyorder := ol.qty;
      if qtyRemain >= ol.qty then
        dtl.qtyship := ol.qty;
      else
        dtl.qtyship := qtyRemain;
      end if;
      qtyRemain := qtyRemain - dtl.qtyship;
      add_dtl_row;
    end loop;
    if cntLines = 0 then
      dtl.linenumber := od.dtlpassthrunum10;
      dtl.qtyorder := od.qtyorder;
      dtl.qtyship := od.qtyship;
      add_dtl_row;
    end if;
  end loop;
end loop;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbmedsn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_med_shipments;

procedure end_med_shipments
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

cmdSql := 'drop table med_shipments_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zemedsn ' || sqlerrm;
  out_errorno := sqlcode;
end end_med_shipments;

procedure begin_med_receipts
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdrs is
  select statusupdate,
         fromfacility,
         custid,
         orderid,
         shipid,
         reference,
         po
    from orderhdr
   where statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate < to_date(in_enddatestr,'yyyymmddhh24miss')
     and orderstatus = 'R'
     and custid = in_custid;

cursor curOrderDtls(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         uomentered,
         nvl(qtyentered,0) as qtyentered,
         nvl(qtyorder,0) as qtyorder,
         uom,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(qtyrcvdgood,0) as qtyrcvdgood,
         nvl(qtyrcvddmgd,0) as qtyrcvddmgd,
         nvl(dtlpassthrunum10,0) as dtlpassthrunum10
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curOrderDtlLines(in_orderid number, in_shipid number, in_item varchar2,
  in_lotnumber varchar2) is
  select linenumber,
         qty
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
     and nvl(xdock,'N') = 'N'
   order by linenumber;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
qtyRemain orderdtl.qtyship%type;
cntLines integer;
strMsg varchar2(255);
dtl med_receipts%rowtype;
qtyEquiv number;

procedure add_dtl_row is
begin

curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, 'insert into med_receipts_' || strSuffix ||
  ' values (:fromdate,:todate,:rcvddate,:facility,:custid,:orderid,:shipid,' ||
  ':reference,:po,:item,:lotnumber,:uomorder,:qtyorder,:uomrcvd,:qtyrcvd,'||
  ':uomrcvdgood,:qtyrcvdgood,:uomrcvddmgd,:qtyrcvddmgd)',
  dbms_sql.native);
dbms_sql.bind_variable(curSql, ':fromdate', dtl.fromdate);
dbms_sql.bind_variable(curSql, ':todate', dtl.todate);
dbms_sql.bind_variable(curSql, ':rcvddate', dtl.rcvddate);
dbms_sql.bind_variable(curSql, ':facility', dtl.facility);
dbms_sql.bind_variable(curSql, ':custid', dtl.custid);
dbms_sql.bind_variable(curSql, ':orderid', dtl.orderid);
dbms_sql.bind_variable(curSql, ':shipid', dtl.shipid);
dbms_sql.bind_variable(curSql, ':reference', dtl.reference);
dbms_sql.bind_variable(curSql, ':po', dtl.po);
dbms_sql.bind_variable(curSql, ':item', dtl.item);
dbms_sql.bind_variable(curSql, ':lotnumber', dtl.lotnumber);
dbms_sql.bind_variable(curSql, ':uomorder', dtl.uomorder);
dbms_sql.bind_variable(curSql, ':qtyorder', dtl.qtyorder);
dbms_sql.bind_variable(curSql, ':uomrcvd', dtl.uomrcvd);
dbms_sql.bind_variable(curSql, ':qtyrcvd', dtl.qtyrcvd);
dbms_sql.bind_variable(curSql, ':uomrcvdgood', dtl.uomrcvdgood);
dbms_sql.bind_variable(curSql, ':qtyrcvdgood', dtl.qtyrcvdgood);
dbms_sql.bind_variable(curSql, ':uomrcvddmgd', dtl.uomrcvddmgd);
dbms_sql.bind_variable(curSql, ':qtyrcvddmgd', dtl.qtyrcvddmgd);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

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
   where table_name = upper('med_receipts_' || strSuffix);
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

begin
  dtl.fromdate := to_date(in_begdatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -1;
  out_msg := 'Invalid begin date string ' || in_begdatestr;
  return;
end;

begin
  dtl.todate := to_date(in_enddatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -2;
  out_msg := 'Invalid end date string ' || in_enddatestr;
  return;
end;

cmdSql := 'create table med_receipts_' || strSuffix ||
 ' (FROMDATE DATE,TODATE DATE,RCVDDATE DATE,FACILITY VARCHAR2(3)'||
 ',CUSTID VARCHAR2(10) not null,ORDERID NUMBER(9) not null'||
 ',SHIPID NUMBER(2) not null,REFERENCE VARCHAR2(20),PO VARCHAR2(20)'||
 ',item varchar2(50) not null,LOTNUMBER VARCHAR2(30),uomorder varchar2(4)'||
 ',QTYORDER NUMBER(7),uomrcvd varchar2(4),QTYrcvd NUMBER(7)'||
 ',uomrcvdgood varchar2(4),qtyrcvdgood number(7),uomrcvddmgd varchar2(4)'||
 ',qtyrcvddmgd number(7))';
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

for oh in curOrderHdrs
loop
  dtl.rcvddate := oh.statusupdate;
  dtl.facility := oh.fromfacility;
  dtl.custid := oh.custid;
  dtl.orderid := oh.orderid;
  dtl.shipid := oh.shipid;
  dtl.reference := oh.reference;
  dtl.po := oh.po;
  for od in curOrderDtls(oh.orderid,oh.shipid)
  loop
    dtl.item := od.item;
    dtl.lotnumber := od.lotnumber;
    dtl.uomorder := od.uomentered;
    dtl.qtyorder := od.qtyentered;
    dtl.uom := od.uom;
    qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,dtl.uom,od.qtyrcvd,od.uomentered);
    if mod(qtyEquiv,1) = 0 then
      dtl.uomrcvd := od.uomentered;
      dtl.qtyrcvd := qtyEquiv;
    else
      dtl.uomrcvd := od.uom;
      dtl.qtyrcvd := od.qtyrcvd;
    end if;
    qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,dtl.uom,od.qtyrcvdgood,od.uomentered);
    if mod(qtyEquiv,1) = 0 then
      dtl.uomrcvdgood := od.uomentered;
      dtl.qtyrcvdgood := qtyEquiv;
    else
      dtl.uomrcvdgood := od.uom;
      dtl.qtyrcvdgood := od.qtyrcvdgood;
    end if;
    qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,dtl.uom,od.qtyrcvddmgd,od.uomentered);
    if mod(qtyEquiv,1) = 0 then
      dtl.uomrcvddmgd := od.uomentered;
      dtl.qtyrcvddmgd := qtyEquiv;
    else
      dtl.uomrcvddmgd := od.uom;
      dtl.qtyrcvddmgd := od.qtyrcvddmgd;
    end if;
    add_dtl_row;
  end loop;
end loop;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbmedrn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_med_receipts;

procedure end_med_receipts
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

cmdSql := 'drop table med_receipts_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zemedsn ' || sqlerrm;
  out_errorno := sqlcode;
end end_med_receipts;

FUNCTION line_qtyentered
(in_orderid IN number
,in_shipid  IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return number is

cursor curOrderDtl is
  select qtyentered
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

out_qtyentered orderdtl.qtyentered%type;

begin

out_qtyentered := 0;

open curOrderDtl;
fetch curOrderdtl
 into out_qtyentered;
close curOrderDtl;

return out_qtyentered;

exception when others then
  return 0;
end line_qtyentered;

FUNCTION line_uomentered
(in_orderid IN number
,in_shipid  IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return varchar2 is

cursor curOrderDtl is
  select uomentered
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

out_uomentered orderdtl.uomentered%type;

begin

out_uomentered := '????';

open curOrderDtl;
fetch curOrderdtl
 into out_uomentered;
close curOrderDtl;

return out_uomentered;

exception when others then
  return '????';
end line_uomentered;

procedure begin_med_shorts
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdrs is
  select statusupdate,
         fromfacility,
         custid,
         orderid,
         shipid,
         reference,
         po
    from orderhdr
   where statusupdate >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and statusupdate < to_date(in_enddatestr,'yyyymmddhh24miss')
     and orderstatus = '9'
     and custid = in_custid;

cursor curOrderDtls(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         uom,
         uomentered,
         cancelreason,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyship,0) as qtyship,
         nvl(dtlpassthrunum10,0) as dtlpassthrunum10,
         linestatus
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and ( (linestatus = 'X') or
           (nvl(qtyorder,0) > nvl(qtyship,0)) );

cursor curOrderDtlLines(in_orderid number, in_shipid number, in_item varchar2,
  in_lotnumber varchar2) is
  select linenumber,
         qty
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
     and nvl(xdock,'N') = 'N'
   order by linenumber;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
qtyRemain orderdtl.qtyship%type;
cntLines integer;
strMsg varchar2(255);
dtl med_short_line%rowtype;
qtyEquiv number;
uombase custitem.baseuom%type;
uomentered custitem.baseuom%type;

procedure add_dtl_row is
begin

qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,uombase,dtl.qtyorder,uomentered);
if mod(qtyEquiv,1) = 0 then
  dtl.uomorder := uomentered;
  dtl.qtyorder := qtyEquiv;
else
  dtl.uomorder := uombase;
end if;

qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,uombase,dtl.qtyship,uomentered);
if mod(qtyEquiv,1) = 0 then
  dtl.uomship := uomentered;
  dtl.qtyship := qtyEquiv;
else
  dtl.uomship := uombase;
end if;

qtyEquiv := zcu.equiv_uom_qty(dtl.custid,dtl.item,uombase,dtl.qtyshort,uomentered);
if mod(qtyEquiv,1) = 0 then
  dtl.uomshort := uomentered;
  dtl.qtyshort := qtyEquiv;
else
  dtl.uomshort := uombase;
end if;

curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, 'insert into med_short_line_' || strSuffix ||
  ' values (:fromdate,:todate,:shipdate,:facility,:custid,:orderid,:shipid,' ||
  ':reference,:po,:item,:lotnumber,:linenumber,:cancelreason,:uomorder,:qtyorder,'||
  ':uomship,:qtyship,:uomshort,:qtyshort)',
  dbms_sql.native);
dbms_sql.bind_variable(curSql, ':fromdate', dtl.fromdate);
dbms_sql.bind_variable(curSql, ':todate', dtl.todate);
dbms_sql.bind_variable(curSql, ':shipdate', dtl.shipdate);
dbms_sql.bind_variable(curSql, ':facility', dtl.facility);
dbms_sql.bind_variable(curSql, ':custid', dtl.custid);
dbms_sql.bind_variable(curSql, ':orderid', dtl.orderid);
dbms_sql.bind_variable(curSql, ':shipid', dtl.shipid);
dbms_sql.bind_variable(curSql, ':reference', dtl.reference);
dbms_sql.bind_variable(curSql, ':po', dtl.po);
dbms_sql.bind_variable(curSql, ':item', dtl.item);
dbms_sql.bind_variable(curSql, ':lotnumber', dtl.lotnumber);
dbms_sql.bind_variable(curSql, ':linenumber', dtl.linenumber);
dbms_sql.bind_variable(curSql, ':cancelreason', dtl.cancelreason);
dbms_sql.bind_variable(curSql, ':uomorder', dtl.uomorder);
dbms_sql.bind_variable(curSql, ':qtyorder', dtl.qtyorder);
dbms_sql.bind_variable(curSql, ':uomship', dtl.uomship);
dbms_sql.bind_variable(curSql, ':qtyship', dtl.qtyship);
dbms_sql.bind_variable(curSql, ':uomshort', dtl.uomshort);
dbms_sql.bind_variable(curSql, ':qtyshort', dtl.qtyshort);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

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
   where table_name = upper('med_short_line_' || strSuffix);
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

begin
  dtl.fromdate := to_date(in_begdatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -1;
  out_msg := 'Invalid begin date string ' || in_begdatestr;
  return;
end;

begin
  dtl.todate := to_date(in_enddatestr,'yyyymmddhh24miss');
exception when others then
  out_errorno := -2;
  out_msg := 'Invalid end date string ' || in_enddatestr;
  return;
end;

cmdSql := 'create table med_short_line_' || strSuffix ||
 ' (FROMDATE DATE,TODATE DATE,SHIPDATE DATE,FACILITY VARCHAR2(3)'||
 ',CUSTID VARCHAR2(10) not null,ORDERID NUMBER(9) not null'||
 ',SHIPID NUMBER(2) not null,REFERENCE VARCHAR2(20),PO VARCHAR2(20)'||
 ',item varchar2(50) not null,LOTNUMBER VARCHAR2(30),LINENUMBER NUMBER(16,4)'||
 ',CANCELREASON VARCHAR2(12)' ||
 ',uomorder varchar2(4),QTYORDER NUMBER(7),uomship varchar2(4),QTYSHIP NUMBER(7)'||
 ',uomshort varchar2(4),qtyshort number(7))';
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

for oh in curOrderHdrs
loop
  dtl.shipdate := oh.statusupdate;
  dtl.facility := oh.fromfacility;
  dtl.custid := oh.custid;
  dtl.orderid := oh.orderid;
  dtl.shipid := oh.shipid;
  dtl.reference := oh.reference;
  dtl.po := oh.po;
  for od in curOrderDtls(oh.orderid,oh.shipid)
  loop
    uombase := od.uom;
    uomentered := od.uomentered;
    dtl.item := od.item;
    dtl.lotnumber := od.lotnumber;
    if od.cancelreason is not null then
      dtl.cancelreason := od.cancelreason;
    elsif od.linestatus = 'X' then
      dtl.cancelreason := 'LINECANCEL';
    else
      dtl.cancelreason := 'SHORT';
    end if;
    cntLines := 0;
    qtyRemain := od.qtyship;
    for ol in curOrderDtlLines(oh.orderid,oh.shipid,od.item,od.lotnumber)
    loop
      cntLines := cntLines + 1;
      dtl.linenumber := ol.linenumber;
      dtl.qtyorder := ol.qty;
      if qtyRemain >= ol.qty then
        dtl.qtyship := ol.qty;
      else
        dtl.qtyship := qtyRemain;
      end if;
      qtyRemain := qtyRemain - dtl.qtyship;
      if dtl.qtyorder > dtl.qtyship then
        dtl.qtyshort := dtl.qtyorder - dtl.qtyship;
        add_dtl_row;
      end if;
    end loop;
    if cntLines = 0 then
      dtl.linenumber := od.dtlpassthrunum10;
      dtl.qtyorder := od.qtyorder;
      dtl.qtyship := od.qtyship;
      dtl.qtyshort := od.qtyorder - od.qtyship;
      add_dtl_row;
    end if;
  end loop;
end loop;

cmdSql := 'create view med_short_order_' || strSuffix ||
 '(fromdate,todate,shipdate,facility,custid,orderid,shipid,reference,' ||
 ' po)' ||
 ' as select fromdate, todate, shipdate, facility, custid, ' ||
 ' orderid,shipid,reference,po ' ||
 ' from med_short_line_' || strSuffix ||
 ' group by fromdate,todate,shipdate,facility,custid,orderid,shipid,' ||
 ' reference,po';
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

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbmedsh ' || sqlerrm;
  out_errorno := sqlcode;
end begin_med_shorts;

procedure end_med_shorts
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

cmdSql := 'drop view med_short_order_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table med_short_line_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zemedsh ' || sqlerrm;
  out_errorno := sqlcode;
end end_med_shorts;

procedure item_master_info
(in_custid IN varchar2
,in_item IN varchar2
,in_descr IN varchar2
,in_abbrev IN varchar2
,in_baseuom IN varchar2
,in_cube IN number
,in_weight IN number
,in_hazardous IN varchar2
,in_to_uom1 IN varchar2
,in_to_uom1_qty IN number
,in_to_uom2 IN varchar2
,in_to_uom2_qty IN number
,in_to_uom3 IN varchar2
,in_to_uom3_qty IN number
,in_to_uom4 IN varchar2
,in_to_uom4_qty IN number
,in_shelflife IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select name
    from customer
   where custid = upper(rtrim(in_custid));
cs curCustomer%rowtype;

cursor curCustItem is
  select descr
    from custitem
   where custid = upper(rtrim(in_custid))
     and item = upper(rtrim(in_item));
ci curCustItem%rowtype;

uom_sequence custitemuom.sequence%type;

procedure error_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := ' Item: ' || rtrim(in_item) || ': ' || out_msg;
  zms.log_msg('IMPEXP', null, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), 'IMPITEM', strMsg);
end;

begin

if rtrim(in_custid) is null then
  out_errorno := 1;
  out_msg := 'Customer ID is required';
  error_msg('E');
  return;
end if;

cs := null;
open curCustomer;
fetch curCustomer into cs;
close curCustomer;
if cs.name is null then
  out_errorno := 2;
  out_msg := 'Customer ID is required';
  error_msg('E');
  return;
end if;

if rtrim(in_item) is null then
  out_errorno := 3;
  out_msg := 'Item ID is required';
  error_msg('E');
  return;
end if;

ci := null;
open curCustItem;
fetch curCustItem into ci;
close curCustItem;

if ci.descr is null then
  insert into custitem
  (custid,item,
   descr,abbrev,status,baseuom,
   cube,weight,hazardous,shelflife,
   lotrequired,serialrequired,user1required,user2required,user3required,
   mfgdaterequired,expdaterequired,countryrequired,
   allowsub,backorder,invstatusind,invclassind,
   qtytype,velocity,recvinvstatus,
   weightcheckrequired,ordercheckrequired,
   use_fifo,putawayconfirmation,
   nodamaged,iskit,picktotype,cartontype,subslprsnrequired,
   lotsumreceipt,lotsumrenewal,lotsumbol,lotsumaccess,
   lotfmtaction,serialfmtaction,
   user1fmtaction,user2fmtaction,user3fmtaction,
   maxqtyof1,rategroup,
   serialasncapture,user1asncapture,user2asncapture,user3asncapture,
   lastuser,lastupdate)
  values
  (upper(rtrim(in_custid)),upper(rtrim(in_item)),
   rtrim(in_descr),rtrim(in_abbrev),'ACTV',nvl(upper(rtrim(in_baseuom)),'EA'),
   nvl(in_cube,0)*1728.0,nvl(in_weight,0),nvl(upper(rtrim(in_hazardous)),'N'),
   nvl(in_shelflife,0),
   'C','C','C','C','C',
   'C','C','C',
   'C','C','C','C',
   'C','C','AV',
   'C','C',
   'N','C',
   'C','N','PAL','PAL','C',
   'N','N','N','N',
   'C','C',
   'C','C','C',
   'C','C',
   'C','C','C','C',
   'IMPITEM',sysdate);
else
  update custitem
     set descr = rtrim(in_descr),
         abbrev = rtrim(in_abbrev),
         baseuom = nvl(upper(rtrim(in_baseuom)),'EA'),
         cube = nvl(in_cube,0)*1728.0,
         weight = nvl(in_weight,0),
         hazardous = nvl(upper(rtrim(in_hazardous)),'N'),
         shelflife = nvl(in_shelflife,0),
         lastuser = 'IMPITEM',
         lastupdate = sysdate
   where custid = upper(rtrim(in_custid))
     and item = upper(rtrim(in_item));
end if;

delete from custitemuom
   where custid = upper(rtrim(in_custid))
     and item = upper(rtrim(in_item));

if (rtrim(in_to_uom1) is not null) and
   (nvl(in_to_uom1_qty,0) <> 0) then
  uom_sequence := 10;
  insert into custitemuom
  (custid,item,
   sequence,qty,
   fromuom,
   touom,
   lastuser,lastupdate)
  values
  (upper(rtrim(in_custid)),upper(rtrim(in_item)),
  uom_sequence,in_to_uom1_qty,
  nvl(upper(rtrim(in_baseuom)),'EA'),
  upper(rtrim(in_to_uom1)),
  'IMPITEM',sysdate);
  if (rtrim(in_to_uom2) is not null) and
     (nvl(in_to_uom2_qty,0) <> 0) then
    uom_sequence := uom_sequence + 10;
    insert into custitemuom
    (custid,item,
     sequence,qty,
     fromuom,
     touom,
     lastuser,lastupdate)
    values
    (upper(rtrim(in_custid)),upper(rtrim(in_item)),
    uom_sequence,in_to_uom2_qty,
    upper(rtrim(in_to_uom1)),
    upper(rtrim(in_to_uom2)),
    'IMPITEM',sysdate);
    if (rtrim(in_to_uom3) is not null) and
       (nvl(in_to_uom3_qty,0) <> 0) then
      uom_sequence := uom_sequence + 10;
      insert into custitemuom
      (custid,item,
       sequence,qty,
       fromuom,
       touom,
       lastuser,lastupdate)
      values
      (upper(rtrim(in_custid)),upper(rtrim(in_item)),
      uom_sequence,in_to_uom3_qty,
      upper(rtrim(in_to_uom2)),
      upper(rtrim(in_to_uom3)),
      'IMPITEM',sysdate);
      if (rtrim(in_to_uom4) is not null) and
         (nvl(in_to_uom4_qty,0) <> 0) then
        uom_sequence := uom_sequence + 10;
        insert into custitemuom
        (custid,item,
         sequence,qty,
         fromuom,
         touom,
         lastuser,lastupdate)
        values
        (upper(rtrim(in_custid)),upper(rtrim(in_item)),
        uom_sequence,in_to_uom4_qty,
        upper(rtrim(in_to_uom3)),
        upper(rtrim(in_to_uom4)),
        'IMPITEM',sysdate);
      end if;
    end if;
  end if;
end if;

exception when others then
  out_msg := 'zimi ' || sqlerrm;
  out_errorno := sqlcode;
end item_master_info;

FUNCTION sum_qtyrcvdgood
(in_orderid IN number
,in_shipid  IN number
) return number is

out_qtyrcvdgood orderdtl.qtyrcvdgood%type;

begin

out_qtyrcvdgood := 0;

select sum(nvl(qtyrcvdgood,0))
  into out_qtyrcvdgood
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid;

return out_qtyrcvdgood;

exception when others then
  return out_qtyrcvdgood;
end sum_qtyrcvdgood;

FUNCTION sum_cubercvdgood
(in_orderid IN number
,in_shipid  IN number
) return number is

out_cubercvdgood orderdtl.cubercvdgood%type;

begin

out_cubercvdgood := 0;

select sum(nvl(cubercvdgood,0))
  into out_cubercvdgood
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid;

return out_cubercvdgood;

exception when others then
  return out_cubercvdgood;
end sum_cubercvdgood;

FUNCTION sum_weightrcvdgood
(in_orderid IN number
,in_shipid  IN number
) return number is

out_weightrcvdgood orderdtl.weightrcvdgood%type;

begin

out_weightrcvdgood := 0;

select sum(nvl(weightrcvdgood,0))
  into out_weightrcvdgood
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid;

return out_weightrcvdgood;

exception when others then
  return out_weightrcvdgood;
end sum_weightrcvdgood;

FUNCTION sum_qtyrcvddmgd
(in_orderid IN number
,in_shipid  IN number
) return number is

out_qtyrcvddmgd orderdtl.qtyrcvddmgd%type;

begin

out_qtyrcvddmgd := 0;

select sum(nvl(qtyrcvddmgd,0))
  into out_qtyrcvddmgd
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid;

return out_qtyrcvddmgd;

exception when others then
  return out_qtyrcvddmgd;
end sum_qtyrcvddmgd;

FUNCTION sum_cubercvddmgd
(in_orderid IN number
,in_shipid  IN number
) return number is

out_cubercvddmgd orderdtl.cubercvddmgd%type;

begin

out_cubercvddmgd := 0;

select sum(nvl(cubercvddmgd,0))
  into out_cubercvddmgd
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid;

return out_cubercvddmgd;

exception when others then
  return out_cubercvddmgd;
end sum_cubercvddmgd;

FUNCTION sum_weightrcvddmgd
(in_orderid IN number
,in_shipid  IN number
) return number is

out_weightrcvddmgd orderdtl.weightrcvddmgd%type;

begin

out_weightrcvddmgd := 0;

select sum(nvl(weightrcvddmgd,0))
  into out_weightrcvddmgd
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid;

return out_weightrcvddmgd;

exception when others then
  return out_weightrcvddmgd;
end sum_weightrcvddmgd;

FUNCTION freight_total
(in_orderid IN number
,in_shipid  IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
) return number is

out_cost multishipdtl.cost%type;
ctn_cost multishipdtl.cost%type;
topfromlpid shippingplate.fromlpid%type;

begin

out_cost := 0;

if rtrim(in_item) is null then
  select sum(nvl(cost,0))
    into out_cost
    from multishipdtl
   where orderid = in_orderid
     and shipid = in_shipid;
else
  for spm in (select parentlpid from shippingplate
              where orderid = in_orderid
              and shipid = in_shipid
              and orderitem = in_item
              and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
              and type in ('F', 'P')
              and parentlpid is not null)
  loop

     select fromlpid into topfromlpid
        from shippingplate
        where parentlpid is null
        start with lpid = spm.parentlpid
        connect by prior parentlpid = lpid;

     ctn_cost := 0;
     select nvl(cost,0) into ctn_cost
       from multishipdtl
      where cartonid = topfromlpid;

     out_cost := out_cost + ctn_cost;

  end loop;
end if;

return out_cost;

exception when others then
  return out_cost;
end freight_total;

/* find cost from first non-null package on the order
** (because station is putting total order cost on each package)
**
*/
FUNCTION freight_cost
(in_orderid IN number
,in_shipid  IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
) return number is

cursor curFirstItemCost(p_orderid number, p_shipid number) is
  select cost
    from multishipdtl
   where orderid = p_orderid
     and shipid = p_shipid
     and cost is not null;

out_cost multishipdtl.cost%type;
ctn_cost multishipdtl.cost%type;
topfromlpid shippingplate.fromlpid%type;

cursor curWaveWeight(in_wave number) is
  select sum(nvl(weightship,0))
    from orderhdr
   where wave = in_wave;

cursor curWaveShipCost(in_wave number) is
  select shipcost
    from waves
   where wave = in_wave;

l_wave waves.wave%type;
tot_cost   number(10,2);
l_cost     number(10,2);
tot_weight number(19,8);
ord_weight number(17,8);

begin

out_cost := 0;

if rtrim(in_item) is null then
  l_wave := zcord.cons_orderid(in_orderid, in_shipid);

  -- If this is a consolidated wave do special processing
  if nvl(l_wave, 0) > 0 then
    out_cost := 0;
    tot_weight := 0;
    OPEN curWaveWeight(l_wave);
    FETCH curWaveWeight into tot_weight;
    CLOSE curWaveWeight;

    tot_cost := 0;
    OPEN curWaveShipCost(l_wave);
    FETCH curWaveShipCost into tot_cost;
    CLOSE curWaveShipCost;

    if nvl(tot_cost,0) = 0 then
--        tot_cost := freight_total(l_wave,0);
      open curFirstItemCost(l_wave, 0);
  		fetch curFirstItemCost into tot_cost;
  	   close curFirstItemCost;
  		if tot_cost is null then
    		tot_cost := 0;
  		end if;
    end if;

    for crec in (select orderid, shipid, nvl(weightship,0) weight
                   from orderhdr
                  where wave = l_wave
                   order by orderid, shipid)
    loop
        l_cost := tot_cost * (crec.weight / tot_weight);
        if crec.orderid = in_orderid and crec.shipid = in_shipid then
            out_cost := l_cost;
            exit;
        end if;
        tot_cost := tot_cost - l_cost;
        tot_weight := tot_weight - crec.weight;
    end loop;

    return out_cost;
  end if;

  open curFirstItemCost(in_orderid, in_shipid);
  fetch curFirstItemCost into out_cost;
  close curFirstItemCost;
  if out_cost is null then
    out_cost := 0;
  end if;
else


  for spm in (select parentlpid from shippingplate
              where orderid = in_orderid
              and shipid = in_shipid
              and orderitem = in_item
              and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
              and type in ('F', 'P')
              and parentlpid is not null)
  loop

     select fromlpid into topfromlpid
        from shippingplate
        where parentlpid is null
        start with lpid = spm.parentlpid
        connect by prior parentlpid = lpid;

     ctn_cost := 0;
     select nvl(cost,0) into ctn_cost
       from multishipdtl
      where cartonid = topfromlpid;

     out_cost := out_cost + ctn_cost;

  end loop;
end if;

return out_cost;

exception when others then
  return out_cost;
end freight_cost;

FUNCTION freight_weight
(in_orderid IN number
,in_shipid  IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
,in_round_up_yn IN varchar2 default 'N'
) return number is

out_actweight multishipdtl.actweight%type;
ctn_actweight multishipdtl.actweight%type;
topfromlpid shippingplate.fromlpid%type;

begin

out_actweight := 0;

if rtrim(in_item) is null then
  select sum(nvl(actweight,0))
    into out_actweight
    from multishipdtl
   where orderid = in_orderid
     and shipid = in_shipid;
else
  for spm in (select parentlpid from shippingplate
              where orderid = in_orderid
              and shipid = in_shipid
              and orderitem = in_item
              and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
              and type in ('F', 'P')
              and parentlpid is not null)
  loop

     select fromlpid into topfromlpid
        from shippingplate
        where parentlpid is null
        start with lpid = spm.parentlpid
        connect by prior parentlpid = lpid;

     ctn_actweight := 0;
     select nvl(actweight,0) into ctn_actweight
       from multishipdtl
      where cartonid = topfromlpid;

     out_actweight := out_actweight + ctn_actweight;

  end loop;
end if;

if in_round_up_yn = 'Y' then
  if mod(out_actweight,1) != 0 then
    out_actweight := out_actweight - mod(out_actweight,1) + 1;
  end if;
end if;
return out_actweight;

exception when others then
  return out_actweight;
end freight_weight;

FUNCTION delivery_service
(in_orderid IN number
,in_shipid  IN number
,in_item IN varchar2 default null
,in_lotnumber IN varchar2 default null
) return varchar2 is

out_carrierused multishipdtl.carrierused%type;
topfromlpid shippingplate.fromlpid%type;

begin

out_carrierused := null;

if rtrim(in_item) is null then
  select max(carrierused)
    into out_carrierused
    from multishipdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and carrierused is not null;
else
  for spm in (select parentlpid from shippingplate
              where orderid = in_orderid
              and shipid = in_shipid
              and orderitem = in_item
              and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
              and type in ('F', 'P')
              and parentlpid is not null)
  loop

     select fromlpid into topfromlpid
        from shippingplate
        where parentlpid is null
        start with lpid = spm.parentlpid
        connect by prior parentlpid = lpid;

     out_carrierused := null;
     select carrierused into out_carrierused
       from multishipdtl
      where cartonid = topfromlpid;

     if out_carrierused is not null then
       exit;
     end if;

  end loop;
end if;

if out_carrierused is null then
  begin
    select deliveryservice
      into out_carrierused
      from orderhdr
     where orderid = in_orderid
       and shipid = in_shipid;
  exception when others then
    null;
  end;
end if;

return out_carrierused;

exception when others then
  return out_carrierused;
end delivery_service;

FUNCTION freight_cost_once
(in_orderid IN number
,in_shipid  IN number
) return number is

out_cost multishipdtl.cost%type;
topfromlpid shippingplate.fromlpid%type;
  
begin
out_cost := 0;
for spm in (select parentlpid from shippingplate
          where orderid = in_orderid
          and shipid = in_shipid
          and type in ('F', 'P')
          and parentlpid is not null)
loop
    select fromlpid into topfromlpid
     from shippingplate
    where parentlpid is null
    start with lpid = spm.parentlpid
    connect by prior parentlpid = lpid;

    if nvl(topfromlpid,'none') != 'none' then
       select cost into out_cost
         from multishipdtl
       where cartonid = topfromlpid;

       if nvl(out_cost,0) != 0 then
         return out_cost;
       end if;
    end if;
end loop;

return out_cost;

exception when others then
  return out_cost;
end freight_cost_once;

FUNCTION cnt_lineitems
(in_orderid IN number
,in_shipid  IN number
) return number is

out_lineitems number;

begin

out_lineitems := 0;

select count(1)
 into out_lineitems
from 
(select orderid, shipid, item, lotnumber
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid
group by orderid, shipid, item, lotnumber);

return out_lineitems;

exception when others then
  return out_lineitems;
end cnt_lineitems;

FUNCTION cnt_qtyship
(in_orderid IN number
,in_shipid  IN number
,shiptype IN char
) return number is

out_qtyship number;
l_multiship carrier.multiship%type;

begin

out_qtyship := 0;

begin
  select ca.multiship
  into l_multiship
  from orderhdr oh, carrier ca
  where oh.orderid = in_orderid
    and oh.shipid = in_shipid
    and oh.carrier = ca.carrier(+);
exception when others then
  l_multiship := 'N';
end;

if nvl(shiptype, 'L') = 'L' or nvl(l_multiship, 'N') = 'N' then
  select nvl(qtyship,0)
   into out_qtyship
   from orderhdr
  where orderid = in_orderid
    and shipid = in_shipid;
elsif nvl(shiptype, 'L') = 'S' and nvl(l_multiship, 'N') = 'Y' then
  select count(cartonid)
    into out_qtyship
   from multishipdtl
  where orderid = in_orderid
    and shipid = in_shipid
    and trackid is not null;
end if;

return out_qtyship;

exception when others then
  return out_qtyship;
end cnt_qtyship;

function sum_weightship
(in_orderid IN number
,in_shipid IN number
,shiptype IN char
) return number is

out_weightship number;
l_multiship carrier.multiship%type;

begin

out_weightship := 0;

begin
  select ca.multiship
  into l_multiship
  from orderhdr oh, carrier ca
  where oh.orderid = in_orderid
    and oh.shipid = in_shipid
    and oh.carrier = ca.carrier(+);
exception when others then
  l_multiship := 'N';
end;

if nvl(shiptype, 'L') = 'L' or nvl(l_multiship, 'N') = 'N' then
  select nvl(weightship,0)
   into out_weightship
   from orderhdr
  where orderid = in_orderid
    and shipid = in_shipid;
elsif nvl(shiptype, 'L') = 'S' and nvl(l_multiship, 'N') = 'Y' then
  select sum(actweight)
    into out_weightship
   from multishipdtl
  where orderid = in_orderid
    and shipid = in_shipid
    and trackid is not null;
end if;

return out_weightship;

exception when others then
  return out_weightship;
end sum_weightship;

FUNCTION freight_cost_all_items
(in_orderid IN number
,in_shipid  IN number
,shiptype IN char
) return number is

out_freight_cost number(10,2);
l_multiship carrier.multiship%type;

begin

  begin
    select ca.multiship
     into l_multiship
     from orderhdr oh, carrier ca
    where oh.orderid = in_orderid
      and oh.shipid = in_shipid
      and oh.carrier = ca.carrier(+);
  exception when others then
    l_multiship := 'N';
  end;

  if nvl(shiptype, 'L') = 'L' or nvl(l_multiship, 'N') = 'N' then
    return 0;
  end if;
  
  out_freight_cost := 0;
  
  for spm in (select distinct item from shippingplate
              where orderid = in_orderid
              and shipid = in_shipid
              and type in ('F', 'P')
              and parentlpid is not null)
  loop
    out_freight_cost := out_freight_cost + zim14.freight_cost(in_orderid, in_shipid, spm.item);
  end loop;
  
  return out_freight_cost;
   
exception when others then
  return out_freight_cost;
end freight_cost_all_items;

FUNCTION get_carrier_name
(in_carrier IN varchar2
,in_servicecode  IN varchar2
) return varchar2 is

out_carrier_name carrierservicecodes.descr%type;

begin
    out_carrier_name := null;
    
 if rtrim(in_carrier) is not null and 
    rtrim(in_servicecode) is not null then
      select  rtrim(descr)
       into out_carrier_name
       from carrierservicecodes
      where carrier = in_carrier
        and servicecode = in_servicecode;
 end if;
 return out_carrier_name;
 
exception when others then
  return out_carrier_name;
end get_carrier_name;

procedure change_item_code
(in_custid IN varchar2
,in_old_item IN varchar2
,in_new_item IN varchar2
,in_adjreason IN varchar2
,in_tasktype IN varchar2
,in_custreference IN varchar2
,in_userid IN varchar2
,in_generate_947_edi_yn varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is
cursor curPlates is
  select lpid,
         custid,
         item,
         nvl(inventoryclass,'RG') as inventoryclass,
         invstatus,
         lotnumber,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         location,
         expirationdate,
         manufacturedate,
         anvdate,
         unitofmeasure,
         quantity as qty,
         facility,
         nvl(loadno,0) as loadno,
         nvl(stopno,0) as stopno,
         nvl(shipno,0) as shipno,
         orderid,
         shipid,
         type,
         parentlpid,
         weight,
         controlnumber,
         adjreason
    from plate
   where custid = in_custid
     and type = 'PA'
     and item = in_old_item;
out_adjrowid1 varchar2(255);
out_adjrowid2 varchar2(255);
cntRows pls_integer;
cntTot pls_integer;
cntErr pls_integer;
cntOky pls_integer;
qtyTot pls_integer;
qtyErr pls_integer;
qtyOky pls_integer;
l_suppress_edi_yn char(1);
l_cnt pls_integer;
l_outmsg varchar2(255);
l_msg varchar2(255);
begin
cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
select count(1)
  into l_cnt
  from custitem
 where custid = in_custid
   and item = in_new_item;
if l_cnt = 0 then
  l_msg := 'Item change from ' || 
         in_old_item ||
         ' to ' ||
         in_new_item || 
         '--new item is invalid';
  zms.log_autonomous_msg('INVADJ', null, in_custid,
                       l_msg, 'E', in_userid, l_outmsg);
  out_msg := 'Invalid new item ' || in_new_item;
  out_errorno := -1;
  return;
end if;
if nvl(rtrim(in_generate_947_edi_yn),'N') = 'Y' then
  l_suppress_edi_yn := 'N';
else
  l_suppress_edi_yn := 'Y';
end if;
for pl in curPlates
loop
  cntTot := cntTot + 1;
  qtyTot := qtyTot + pl.qty;
  zia.inventory_adjustment
  (pl.lpid
  ,pl.custid
  ,in_new_item
  ,pl.inventoryclass
  ,pl.invstatus
  ,pl.lotnumber
  ,pl.serialnumber
  ,pl.useritem1
  ,pl.useritem2
  ,pl.useritem3
  ,pl.location
  ,pl.expirationdate
  ,pl.qty
  ,pl.custid
  ,pl.item
  ,pl.inventoryclass
  ,pl.invstatus
  ,pl.lotnumber
  ,pl.serialnumber
  ,pl.useritem1
  ,pl.useritem2
  ,pl.useritem3
  ,pl.location
  ,pl.expirationdate
  ,pl.qty
  ,pl.facility
  ,in_adjreason
  ,in_userid
  ,in_tasktype
  ,pl.weight
  ,pl.weight
  ,pl.manufacturedate
  ,pl.manufacturedate
  ,pl.anvdate
  ,pl.anvdate
  ,out_adjrowid1
  ,out_adjrowid2
  ,out_errorno
  ,out_msg
  ,in_custreference
  ,'Y' -- in_tasks_ok
  ,l_suppress_edi_yn);
  if out_errorno != 0 then
    rollback;
    cntErr := cntErr + 1;
    qtyErr := qtyErr + pl.qty;
    l_msg := substr('LiP: ' || pl.lpid || ' ' || out_msg,1,255);
    zms.log_autonomous_msg('INVADJ', pl.facility, pl.custid,
                           l_msg, 'E', in_userid, l_outmsg);
  else
    commit;
    cntOky := cntOky + 1;
    qtyOky := qtyOky + pl.qty;
    if l_suppress_edi_yn = 'N' then
      if out_adjrowid1 is not null then
         zim6.check_for_adj_interface(out_adjrowid1,out_errorno,out_msg);
      end if;
      if out_adjrowid2 is not null then
         zim6.check_for_adj_interface(out_adjrowid2,out_errorno,out_msg);
      end if;
    end if;
  end if;
end loop;

l_msg := 'Item change from ' || 
         in_old_item ||
         ' to ' ||
         in_new_item || 
         ' Qty Total: ' || qtyTot ||
         ' Qty Error: ' || qtyErr ||
         ' Qty Okay: ' || qtyOky;
zms.log_autonomous_msg('INVADJ', null, in_custid,
                       l_msg, 'I', in_userid, l_outmsg);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zcic ' || sqlerrm;
  out_errorno := sqlcode;
end change_item_code;

end zimportproc14;
/
show error package body zimportproc14;
exit;

