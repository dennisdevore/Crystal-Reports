create or replace package body alps.zimportproc6 as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure check_for_adj_interface
(in_adjrowid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curInvAdjActivity is
  select *
    from invadjactivity
   where rowid = in_adjrowid;
adj curInvAdjActivity%rowtype;

prm orderstatus%rowtype;
strMovement orderstatus.abbrev%type;
strMsg varchar2(255);
strDebugYN char(1);
strBatchYN char(1);
nocommit boolean;

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

exception when others then
  zut.prt('debug--' || sqlerrm);
end;

begin

if out_errorno = -999 or
   out_errorno = -998 then
  strBatchYN := 'Y';
else
  strBatchYN := 'N';
end if;

if out_errorno = -12345 or
   out_errorno = -998 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

if out_msg = 'NOCOMMIT' then
  nocommit := True;
else
  nocommit := False;
end if;

out_msg := '';
out_errorno := 0;

debugmsg('validate interface');
if strDebugYN = 'Y' then
  out_errorno := -12345;
end if;

zmi3.validate_interface(in_adjrowid,strMovement,out_errorno,out_msg);
debugmsg('out_errorno ' || out_errorno);
debugmsg('out_msg ' || out_msg);
if out_errorno <> 0 then
  return;
end if;

adj := null;
open curInvAdjActivity;
fetch curInvAdjActivity into adj;
close curInvAdjActivity;

if adj.custid is null then
  out_errorno := -1;
  out_msg := 'Adjustment row not found: ' || in_adjrowid;
  return;
end if;

    debugmsg('get_cust_parm ' || adj.custid);
    zmi3.get_cust_parm_value(adj.custid,'I9INVADJFMT',prm.descr,prm.abbrev);
    debugmsg('parm descr is >' || prm.descr || '<');
    debugmsg('parm abbrev is >' || prm.abbrev || '<');
    if prm.descr is null then
      return;
    end if;

if (strBatchYN = 'N') and
   (upper(prm.abbrev) = 'BATCH') then
  return;
end if;

debugmsg('submit request');
if (nocommit) then
  out_msg := 'NOCOMMIT';
else
  out_msg := null;
end if;

ziem.impexp_request(
'E', -- reqtype
null, -- facility
adj.custid, -- custid
prm.descr, -- formatid
null, -- importfilepath
'NOW', -- when
0, -- loadno
0, -- orderid
0, -- shipid
in_adjrowid, --rowid
null, -- tablename
null,  --columnname
null, --filtercolumnname
null, -- company
null, -- warehouse
null, -- begindatestr
null, -- enddatestr
out_errorno,
out_msg);

if out_errorno != 0 then
  zms.log_msg('ImpExp', '', adj.custid,
    'Request Inv Adj Export: ' || out_msg,
    'E', 'IMPEXP', strMsg);
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end;

procedure begin_I9_inv_adj
(in_custid IN varchar2
,in_rowid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_nsd_yn IN varchar2
,in_invstatus_offset IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curInvAdjbyRowId is
  select rowid,invadjactivity.*
    from invadjactivity
   where custid = in_custid
     and rowid = in_rowid;

cursor curInvAdjByDate is
  select rowid,invadjactivity.*
    from invadjactivity
   where custid = in_custid
     and whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss');

cursor curLip(in_lpid varchar2) is
  select orderid, shipid,manufacturedate
    from plate
   where lpid = in_lpid;
lp curLip%rowtype;

cursor curDeletedLip(in_lpid varchar2) is
  select orderid, shipid,manufacturedate
    from deletedplate
   where lpid = in_lpid;

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select reference
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl(in_orderid number, in_shipid number, in_item varchar2,
  in_lotnumber varchar2) is
  select nvl(dtlpassthrunum10,0) as linenumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
od curOrderDtl%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
dteTest date;
strTranParm orderstatus.code%type;
strWhse orderstatus.abbrev%type;
strAbbrev orderstatus.abbrev%type;
strNewWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strUnStatus orderstatus.abbrev%type;
strDmgStatus orderstatus.abbrev%type;
strDescr orderstatus.descr%type;
strMovementCode orderstatus.abbrev%type;
strSalable_yn varchar2(1);
qtyAvailable number(7);
qtyNonSalable number(7);
qtyAdjust number(7);
qtyDamaged number(7);
strToStorageLoc varchar2(12);
prm licenseplatestatus%rowtype;
qtyRemain integer;
intErrorNo integer;
i9 i9_inv_adj_dtl%rowtype;
strMsg varchar2(255);
strDebugYN char(1);

procedure debugmsg(in_text varchar2) is
begin
  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  zut.prt('debugmsg exception');
end;

procedure add_dtl_rows(adj curInvAdjByRowid%rowtype) is
begin

debugmsg(adj.custid || ' ' || adj.invstatus || ' ' || adj.lpid || ' ' ||
  to_char(adj.whenoccurred, 'MM/DD/YYYY HH24:MI:SS'));

zmi3.get_whse(adj.custid,adj.inventoryclass,strWhse,strRegWhse,strRetWhse);
if strWhse is null then
  debugmsg('get_whse--not found');
  return;
end if;
debugmsg('whse is ' || strWhse);

if strDebugYN = 'Y' then
  intErrorNo := -12345;
end if;

zmi3.validate_interface(adj.rowid,strMovementCode,intErrorNo,strMsg);
if intErrorNo <> 0 then
  debugmsg('validate_interface errorno ' || intErrorNo);
  debugmsg(strMsg);
  return;
end if;

strToStorageLoc := null;
if ( (adj.inventoryclass != nvl(adj.newinventoryclass,adj.inventoryclass)) or
      (adj.invstatus != nvl(adj.newinvstatus,adj.invstatus)) ) then
  qtyAdjust := adj.adjqty * -1;
  zmi3.get_whse(adj.newcustid,adj.newinventoryclass,strNewWhse,strRegWhse,strRetWhse);
  if strNewWhse <> strWhse then
    strToStorageLoc := strNewWhse;
  end if;
else
  qtyAdjust := adj.adjqty;
end if;

i9.qty := qtyAdjust;

zmi3.get_cust_parm_value(adj.custid,'UNSTATUS',strDescr,strUnStatus);
if instr(strUnStatus,nvl(adj.newinvstatus,adj.invstatus)) != 0 then
  debugmsg('salable');
  qtyAvailable := qtyAdjust;
  qtyNonSalable := 0;
  strSalable_yn := 'Y';
else
  debugmsg('not salable');
  qtyAvailable := 0;
  qtyNonSalable := qtyAdjust;
  strSalable_yn := 'N';
  if nvl(upper(rtrim(in_include_nsd_yn)),'N') = 'Y' then
    zmi3.get_cust_parm_value(adj.custid,'DMGSTATUS',strDescr,strDmgStatus);
    if instr(strDmgStatus,nvl(adj.newinvstatus,adj.invstatus)) != 0 then
      debugmsg('damaged');
      qtyNonSalable := 0;
      qtyDamaged := qtyAdjust;
      strSalable_yn := 'D';
    end if;
  end if;
end if;

i9.origpo := 'xxx';
i9.origpolinenumber := 0;
strTranParm := 'OO-' || strMovementCode;
zmi3.get_whse_parm_value(adj.custid,strRegWhse,strTranParm,strDescr,strAbbrev);
if strAbbrev is not null then
  lp := null;
  open curLip(adj.lpid);
  fetch curLip into lp;
  close curLip;
  if lp.orderid is null then
    open curDeletedLip(adj.lpid);
    fetch curDeletedLip into lp;
    close curDeletedLip;
  end if;
  if lp.orderid is not null then
    oh := null;
    open curOrderHdr(lp.orderid,lp.shipid);
    fetch curOrderHdr into oh;
    close curOrderHdr;
    i9.origpo := nvl(oh.reference,'xxx');
    od := null;
    open curOrderDtl(lp.orderid,lp.shipid,adj.item,adj.lotnumber);
    fetch curOrderDtl into od;
    close curOrderDtl;
    i9.origpolinenumber := nvl(od.linenumber,0);
  end if;
else
  debugmsg('no orig order');
end if;

begin
  select useramt1,useramt2
    into i9.useramt1,i9.useramt2
    from custitem
   where custid = adj.custid
     and item = adj.item;
exception when others then
  debugmsg('exception on item retrieval ' || adj.custid || ' ' || adj.item);
  i9.useramt1 := 0;
  i9.useramt2 := 0;
end ;

if (trim(in_invstatus_offset) is not null) then
  if (adj.invstatus = nvl(adj.newinvstatus,adj.invstatus)) and -- or
     (adj.adjqty > 0) then
    i9.oldinvstatus := in_invstatus_offset;
    i9.newinvstatus := adj.invstatus; -- nvl(adj.newinvstatus,adj.invstatus);
  else
    i9.oldinvstatus := adj.invstatus;
    i9.newinvstatus := in_invstatus_offset;
  end if;
else
  i9.oldinvstatus := adj.oldinvstatus;
  i9.newinvstatus := nvl(adj.newinvstatus,adj.invstatus);
end if;


debugmsg('insert i9_inv_adj_lip');
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, 'insert into i9_inv_adj_lips_' || strSuffix ||
  ' values (:custid,:statusupdate,:movement,:specialstock,:reason,:item,' ||
  ':lpid,:origpo,:origpolinenumber,:salable_yn,:fromstorageloc,:tostorageloc,' ||
  ':uom,:lotnumber,:manufacturedate,:adjuser,:useramt1,:useramt2,'||
  ':qtyavailable,:qtynonsalable,:qtydamaged,:qty,:invstatus,:custreference,'||
  ':oldinvstatus,:newinvstatus,:facility)',
  dbms_sql.native);
dbms_sql.bind_variable(curSql, ':custid', adj.custid);
dbms_sql.bind_variable(curSql, ':statusupdate', adj.whenoccurred);
dbms_sql.bind_variable(curSql, ':movement', strMovementCode);
dbms_sql.bind_variable(curSql, ':specialstock', 'K');
dbms_sql.bind_variable(curSql, ':reason', adj.adjreason);
dbms_sql.bind_variable(curSql, ':item', adj.item);
dbms_sql.bind_variable(curSql, ':lpid', adj.lpid);
dbms_sql.bind_variable(curSql, ':origpo', i9.origpo);
dbms_sql.bind_variable(curSql, ':origpolinenumber', i9.origpolinenumber);
dbms_sql.bind_variable(curSql, ':salable_yn', strSalable_yn);
dbms_sql.bind_variable(curSql, ':fromstorageloc', strWhse);
dbms_sql.bind_variable(curSql, ':tostorageloc', strToStorageLoc);
dbms_sql.bind_variable(curSql, ':uom', adj.uom);
dbms_sql.bind_variable(curSql, ':lotnumber', adj.lotnumber);
dbms_sql.bind_variable(curSql, ':manufacturedate', lp.manufacturedate);
dbms_sql.bind_variable(curSql, ':adjuser', adj.adjuser);
dbms_sql.bind_variable(curSql, ':useramt1', zci.item_amt(adj.custid, lp.orderid, lp.shipid, adj.item, adj.lotnumber));
dbms_sql.bind_variable(curSql, ':useramt2', i9.useramt2);
dbms_sql.bind_variable(curSql, ':qtyavailable', qtyAvailable);
dbms_sql.bind_variable(curSql, ':qtynonsalable', qtynonsalable);
dbms_sql.bind_variable(curSql, ':qtydamaged', qtynonsalable);
dbms_sql.bind_variable(curSql, ':qty', i9.qty);
dbms_sql.bind_variable(curSql, ':invstatus', adj.invstatus);
dbms_sql.bind_variable(curSql, ':custreference', adj.custreference);
dbms_sql.bind_variable(curSql, ':oldinvstatus', i9.oldinvstatus);
dbms_sql.bind_variable(curSql, ':newinvstatus', i9.newinvstatus);
dbms_sql.bind_variable(curSql, ':facility', adj.facility);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

if (trim(in_invstatus_offset) is not null) and
   (adj.invstatus != nvl(adj.newinvstatus,adj.invstatus)) then
  i9.invstatus := in_invstatus_offset;
  i9.newinvstatus := adj.newinvstatus;
  i9.oldinvstatus := in_invstatus_offset;
  zmi3.get_movement_code(adj.custid,strWhse,adj.inventoryclass,i9.invstatus,
    adj.newinventoryclass,i9.newinvstatus,adj.adjreason,adj.adjqty,
    strMovementcode,interrorno,strmsg);
  debugmsg('insert i9_inv_adj_lip offset ' || strMovementCode );
  if strMovementCode is not null then
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, 'insert into i9_inv_adj_lips_' || strSuffix ||
      ' values (:custid,:statusupdate,:movement,:specialstock,:reason,:item,' ||
      ':lpid,:origpo,:origpolinenumber,:salable_yn,:fromstorageloc,:tostorageloc,' ||
      ':uom,:lotnumber,:manufacturedate,:adjuser,:useramt1,:useramt2,'||
      ':qtyavailable,:qtynonsalable,:qtydamaged,:qty,:invstatus,:custreference,'||
      ':oldinvstatus,:newinvstatus,:facility)',
      dbms_sql.native);
    dbms_sql.bind_variable(curSql, ':custid', adj.custid);
    dbms_sql.bind_variable(curSql, ':statusupdate', adj.whenoccurred);
    dbms_sql.bind_variable(curSql, ':movement', strMovementCode);
    dbms_sql.bind_variable(curSql, ':specialstock', 'K');
    dbms_sql.bind_variable(curSql, ':reason', adj.adjreason);
    dbms_sql.bind_variable(curSql, ':item', adj.item);
    dbms_sql.bind_variable(curSql, ':lpid', adj.lpid);
    dbms_sql.bind_variable(curSql, ':origpo', i9.origpo);
    dbms_sql.bind_variable(curSql, ':origpolinenumber', i9.origpolinenumber);
    dbms_sql.bind_variable(curSql, ':salable_yn', strSalable_yn);
    dbms_sql.bind_variable(curSql, ':fromstorageloc', strWhse);
    dbms_sql.bind_variable(curSql, ':tostorageloc', strToStorageLoc);
    dbms_sql.bind_variable(curSql, ':uom', adj.uom);
    dbms_sql.bind_variable(curSql, ':lotnumber', adj.lotnumber);
    dbms_sql.bind_variable(curSql, ':manufacturedate', lp.manufacturedate);
    dbms_sql.bind_variable(curSql, ':adjuser', adj.adjuser);
    dbms_sql.bind_variable(curSql, ':useramt1', zci.item_amt(adj.custid, lp.orderid, lp.shipid, adj.item, adj.lotnumber));
    dbms_sql.bind_variable(curSql, ':useramt2', i9.useramt2);
    dbms_sql.bind_variable(curSql, ':qtyavailable', qtyAvailable);
    dbms_sql.bind_variable(curSql, ':qtynonsalable', qtynonsalable);
    dbms_sql.bind_variable(curSql, ':qtydamaged', qtynonsalable);
    dbms_sql.bind_variable(curSql, ':qty', i9.qty);
    dbms_sql.bind_variable(curSql, ':invstatus', adj.invstatus);
    dbms_sql.bind_variable(curSql, ':custreference', adj.custreference);
    dbms_sql.bind_variable(curSql, ':oldinvstatus', i9.oldinvstatus);
    dbms_sql.bind_variable(curSql, ':newinvstatus', i9.newinvstatus);
    dbms_sql.bind_variable(curSql, ':facility', adj.facility);
    cntRows := dbms_sql.execute(curSql);
    dbms_sql.close_cursor(curSql);
  end if;
end if;

end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = upper('I9_INV_ADJ_LIPS_' || strSuffix);
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

debugmsg('view number is ' || cntView);

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

debugmsg('create i9_inv_adj_lips table');
cmdSql := 'create table I9_inv_adj_lips_' || strSuffix ||
 ' (custid varchar2(10),statusupdate date,movement varchar2(12), ' ||
 ' specialstock varchar2(1),reason varchar2(12),item varchar2(50), ' ||
 ' lpid varchar2(15),origpo varchar2(20),origpolinenumber number(7), salable_yn varchar2(1), ' ||
 ' fromstorageloc varchar2(12),tostorageloc varchar2(12), ' ||
 ' uom varchar2(4), lotnumber varchar2(30), manufacturedate date, ' ||
 ' adjuser varchar2(12), useramt1 number, useramt2 number, ' ||
 ' qtyavailable number(7),qtynonsalable number(7), qtydamaged number(7), qty number(7), ' ||
 ' invstatus varchar2(2), custreference varchar2(32), oldinvstatus varchar2(2),'||
 ' newinvstatus varchar2(2), facility varchar2(3) ' ||
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

debugmsg('create i9_inv_adj_dtl view');
cmdSql := 'create or replace view I9_inv_adj_dtl_' || strSuffix ||
 ' (custid,statusupdate,movement,specialstock,reason,item,' ||
 ' lpid,origpo,origpolinenumber,salable_yn,fromstorageloc,tostorageloc,' ||
 ' uom,lotnumber,manufacturedate,adjuser,useramt1,useramt2,qtyavailable,qtynonsalable,qtydamaged,qty,' ||
 ' invstatus, custreference, oldinvstatus, newinvstatus, facility) ' ||
 ' as select custid,statusupdate,movement,specialstock,reason,item, ' ||
 ' lpid,origpo,origpolinenumber,salable_yn,fromstorageloc,tostorageloc, ' ||
 ' uom,lotnumber,manufacturedate,adjuser,useramt1,useramt2,sum(qtyavailable),sum(qtynonsalable), ' ||
 ' sum(qtydamaged), sum(qty), invstatus, custreference, oldinvstatus, newinvstatus, facility  ' ||
 ' from I9_inv_adj_lips_' || strSuffix ||
 ' group by custid,statusupdate,movement,specialstock,reason,item, ' ||
 ' lpid,origpo,origpolinenumber,salable_yn, ' ||
 ' fromstorageloc,tostorageloc,uom,lotnumber,manufacturedate,'||
 ' adjuser,useramt1,useramt2,invstatus, custreference, oldinvstatus, '||
 ' newinvstatus, facility ';
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

debugmsg('create i9_inv_adj_hdr view');
cmdSql := 'create or replace view I9_inv_adj_hdr_' || strSuffix ||
 ' (custid,statusupdate,movement,specialstock,reason, ' ||
 ' item,lpid,origpo,origpolinenumber,salable_yn,facility) ' ||
 ' as select distinct custid,statusupdate,movement,specialstock,reason, ' ||
 ' item,lpid,origpo,origpolinenumber,salable_yn, facility from I9_inv_adj_dtl_' || strSuffix;
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


debugmsg('create i9_inv_adj_sum view');
cmdSql := 'create or replace view I9_inv_adj_sum_' || strSuffix ||
 ' (custid,statusupdate,movement,reason,item,uom,lotnumber,' ||
 ' qtyavailable,qtynonsalable,qtydamaged,qty,' ||
 ' invstatus, custreference, oldinvstatus, newinvstatus, facility) ' ||
 ' as select custid,trunc(statusupdate,''DD''),movement,reason,' ||
 ' item,uom,lotnumber, ' ||
 ' sum(qtyavailable),sum(qtynonsalable),sum(qtydamaged),sum(qty),' ||
 ' invstatus, custreference, oldinvstatus, newinvstatus, facility  ' ||
 ' from I9_inv_adj_lips_' || strSuffix ||
 ' group by custid,trunc(statusupdate,''DD''),movement,reason,' ||
 ' item,uom,lotnumber, ' ||
 ' invstatus, custreference, oldinvstatus,newinvstatus, facility ';
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


if nvl(upper(rtrim(in_rowid)),'(NONE)') != '(NONE)' then
  for adj in curInvAdjByRowId
  loop
    add_dtl_rows(adj);
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
  for adj in curInvAdjByDate
  loop
    add_dtl_rows(adj);
  end loop;
end if;

out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbi9sn ' || sqlerrm || ' ' || in_rowid;
  out_errorno := sqlcode;
end begin_I9_inv_adj;

procedure end_I9_inv_adj
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

cmdSql := 'drop view I9_inv_adj_HDR_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop view I9_inv_adj_DTL_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop view I9_inv_adj_SUM_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'drop table I9_inv_adj_lips_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zei9sn ' || sqlerrm;
  out_errorno := sqlcode;
end end_I9_inv_adj;

procedure begin_matissue_lpid
(in_custid in varchar2
,in_rowid in varchar2
,out_errorno in out number
,out_msg in out varchar2)
as

  strDebugYN varchar2(1);
  strSuffix varchar2(32);
  cntView integer;
  cntRows integer;
  cntRows2 integer;
  
  procedure debugmsg(in_text varchar2) is
  begin
    if strDebugYN = 'Y' then
      zut.prt(in_text);
    end if;
  exception when others then
    zut.prt('debugmsg exception');
  end;

begin
  if out_errorno = -12345 then
    strDebugYN := 'Y';
  else
    strDebugYN := 'N';
  end if;

  out_errorno := 0;
  out_msg := '';
  
  cntView := 1;
  while(1=1)
  loop
    strSuffix := rtrim(upper(in_custid)) || cntView;
      select count(1)
      into cntRows
      from user_tables
      where table_name = upper('matissue_lpid_' || strSuffix);

      select count(1)
      into cntRows2
      from user_views
      where view_name = upper('matissue_lpid_' || strSuffix);
    if (cntRows + cntRows2) = 0 then
      exit;
    else
      cntView := cntView + 1;
    end if;
  end loop;

  debugmsg('view number is ' || cntView);

  select count(1)
    into cntRows
    from customer
   where custid = rtrim(in_custid);

  if cntRows = 0 then
    out_errorno := -1;
    out_msg := 'Invalid Customer Code';
    return;
  end if;
  
  execute immediate 'create table matissue_lpid_' || strSuffix  ||
    ' as select * from matissue_lpid where 1=0';
    
  execute immediate
   'insert into matissue_lpid_' || strSuffix || '
    select *
    from matissue_lpid
    where lpid in (
      select lpid
      from shippingplate
      start with rowid = ''' || in_rowid || '''
      connect by prior lpid = parentlpid)';

  out_msg := 'OKAY';
  out_errorno := cntView;
  
exception when others then
  out_msg := 'zip6 bml ' || sqlerrm;
  out_errorno := sqlcode;
end begin_matissue_lpid;

procedure end_matissue_lpid
(in_custid in varchar2
,in_viewsuffix in varchar2
,out_errorno in out number
,out_msg in out varchar2
)
as 

  strDebugYN varchar2(1);
  strSuffix varchar2(32);
  curSql integer;
  cmdSql varchar2(20000);
  cntRows integer;
  
  procedure debugmsg(in_text varchar2) is
  begin
    if strDebugYN = 'Y' then
      zut.prt(in_text);
    end if;
  exception when others then
    zut.prt('debugmsg exception');
  end;
  
begin
  out_errorno := 0;
  out_msg := '';

  strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

  cmdSql := 'drop view matissue_lpid_' || strSuffix;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);

  out_msg := 'OKAY';
  out_errorno := 0;

exception when others then
  out_msg := 'zip6 eml ' || sqlerrm;
  out_errorno := sqlcode;
end end_matissue_lpid;  

----------------------------------------------------------
procedure begin_staged_shippingplate
(in_custid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curSP is
  select rowid,s.*
    from shippingplate s
   where status = 'S'
     and custid = in_custid
     and parentlpid is null;

cursor curChildSP(in_lpid varchar2) is
  select fromlpid
    from shippingplate
   where parentlpid = in_lpid
     and fromlpid is not null
     and type = 'F';

cSP curSP%rowtype;
curSql integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
cntView integer;
strDebugYN char(1);
dExportDate date;
strLpid varchar2(15);
strReference orderhdr.reference%type;
procedure debugmsg(in_text varchar2) is
begin
  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  zut.prt('debugmsg exception');
end;


begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

cntView := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || cntView;
  select count(1)
    into cntRows
    from user_tables
   where table_name = upper('STAGED_SP_' || strSuffix);
  if cntRows = 0 then
    exit;
  else
    cntView := cntView + 1;
  end if;
end loop;

debugmsg('view number is ' || cntView);

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;
select sysdate into dExportDate from dual;
debugmsg('create STAGED_SP_' || strsuffix || ' table');
cmdSql := 'create table STAGED_SP_' || strSuffix ||
 ' (custid varchar2(10), fromlpid varchar2(15), item varchar2(20), quantity number(7), '||
  ' type varchar(2), orderid number(9), lpid varchar2(15), parentlpid varchar2(15), '||
  ' creationdate varchar2(15), exportdate date, reference varchar2(20))';

debugmsg(cmdSql);
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);


open curSP;
while 1 = 1 loop
   fetch curSP into cSP;
   exit when curSP%notfound;
   cntRows := 1;
   begin
      select reference into strReference
         from orderhdr
         where orderid = cSP.orderid
           and shipid = cSP.shipid;
   exception when no_data_found then
      strReference := null;
   end;
   if cSP.type = 'M' then
--      if cSP.item is null then
--         strLpid := 'MIXED';
--      else
         select count(1) into cntRows
            from shippingplate
            where parentlpid = cSP.lpid;
         strLpid := cSP.fromlpid;
--      end if;
   else
      strLpid := cSP.fromlpid;
   end if;
   if strLpid is null then
      open curChildSP(cSP.lpid);
      fetch curChildSP into strLpid;
      close curChildSP;
      if strLpid is null then
         strLpid := 'MIXED';
      end if;
   end if;
   if cntRows < 2 then
      debugmsg('start cp loop');
      for cp in (select custid, item, zim6.lip_creationdate(fromlpid) as creationdate,
                 sum(quantity) as quantity
                  from shippingplate
                  where type in ('F','P')
                  start with lpid = cSP.lpid
                  connect by prior lpid = parentlpid
                  group by custid, item, zim6.lip_creationdate(fromlpid)) loop
         debugmsg('  ' || cp.custid || ' ' || cp.item || ' ' || cp.quantity);
         execute immediate 'insert into STAGED_SP_' || strSuffix ||
         ' values (:CUSTID,:FROMLPID,:ITEM, :QUANTITY, '||
                  ':TYPE, :ORDERID, :LPID, :PARENTLPID, '||
                  ':CREATIONDATE, :EXPORTDATE, :REFERENCE) '
         using in_custid, strLpid, cp.item,cp.quantity,
               cSP.type, cSP.orderid, nvl(cSP.fromlpid,'MIXED'), strLpid,
               to_char(cp.creationdate,'mm/dd/yyyy'), dExportdate, strReference;
      end loop;
   else
      debugmsg('start cp loop2');
      for cp in (select custid, item,
                 sum(quantity) as quantity
                  from shippingplate
                  where type in ('F','P')
                  start with lpid = cSP.lpid
                  connect by prior lpid = parentlpid
                  group by custid, item) loop
         debugmsg('  ' || cp.custid || ' ' || cp.item || ' ' || cp.quantity);
         execute immediate 'insert into STAGED_SP_' || strSuffix ||
         ' values (:CUSTID,:FROMLPID,:ITEM, :QUANTITY, '||
                  ':TYPE, :ORDERID, :LPID, :PARENTLPID, '||
                  ':CREATIONDATE, :EXPORTDATE, :REFERENCE) '
         using in_custid, strLpid, cp.item,
               cp.quantity, cSP.type, cSP.orderid,
               'CHILDREN', 'CHILDREN', 'MULTIPLEDATES', dExportdate, strReference;
      end loop;
   end if;

end loop;
close curSp;




out_msg := 'OKAY';
out_errorno := cntView;

exception when others then
  out_msg := 'zbss ' || sqlerrm ;
  out_errorno := sqlcode;
end begin_staged_shippingplate;

procedure end_staged_shippingplate
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

cmdSql := 'drop table STAGED_SP_' || strSuffix;
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zeiss ' || sqlerrm;
  out_errorno := sqlcode;
end end_staged_shippingplate;

function lip_creationdate
(in_lpid varchar2
) return date is

cursor curPlate is
  select creationdate
    from plate
   where lpid = in_lpid;

cursor curDeletedPlate is
  select creationdate
    from deletedplate
   where lpid = in_lpid;

out_creationdate date;

begin

out_creationdate := null;

open curPlate;
fetch curPlate into out_creationdate;
close curPlate;
if out_creationdate is null then
  open curDeletedPlate;
  fetch curDeletedPlate into out_creationdate;
  close curDeletedPlate;
  if out_creationdate is null then
     select sysdate into out_creationdate from dual;
  end if;
end if;

return out_creationdate;

exception when others then
  return null;
end lip_creationdate;

end zimportproc6;
/
show error package body zimportproc6;
exit;
