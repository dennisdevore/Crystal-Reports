create or replace PACKAGE BODY Zimportproc947 AS

----------------------------------------------------------------------
-- begin_stdinvadj947_susp -- include suspense adjusments as a 2
--                            sided transaction
----------------------------------------------------------------------
procedure begin_invadj947std_susp
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;


cursor C_INVADJACTIVITY is
  select IA.rowid,IA.*, U.upc
    from custitemupcview U, invadjactivity IA
   where IA.custid = in_custid
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and IA.custid = U.custid(+)
     and IA.item = U.item(+)
     and nvl(IA.suppress_edi_yn,'N') != 'Y';

cursor C_LPID(in_lpid varchar2) is
  select DR.descr
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code;

dteTest date;

errmsg varchar2(100);
mark varchar2(20);

intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strMsg varchar2(255);
qtyAdjust number(7);
strRefDesc varchar2(45);
strNewRsnCode invadjactivity.adjreason%TYPE;
qtyAdjNew  invadjactivity.adjqty%TYPE;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' ' ||out_msg;
  zms.log_autonomous_msg('947', 'JCT', rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), '947', strMsg);
end;

begin

mark := 'Start';

out_errorno := 0;
out_msg := '';
viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'STDINVADJ947_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;
out_msg := strSuffix || ' ' || in_custid || ' ' || in_begdatestr || ' ' || in_enddatestr;
order_msg('I');
out_msg := '';

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

-- Verify the dates
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

cmdSql := 'create table stdinvadj947_' || strSuffix ||
          '(whenoccurred date, lpid varchar2(15), facility varchar2(3), custid varchar2(10), '||
          ' item varchar2(50), lotnumber varchar2(30), inventoryclass varchar2(2), invstatus varchar2(2),'||
          ' uom varchar2(4), adjqty number(7), adjreason varchar2(2), tasktype varchar2(4), '||
          ' adjuser varchar2(12), lastuser varchar2(12), lastupdate date, serialnumber varchar2(30),'||
          ' useritem1 varchar2(20), useritem2 varchar2(20), useritem3 varchar2(20), oldcustid varchar2(10), '||
          ' olditem varchar2(50), oldlotnumber varchar2(30), oldinventoryclass varchar2(2), '||
          ' oldinvstatus varchar2(2), newcustid varchar2(10), newitem varchar2(50), '||
          ' newlotnumber varchar2(30), newinventoryclass varchar2(2), newinvstatus varchar2(2), '||
          ' adjweight number(13,4), custreference varchar2(32))';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

for adj in C_INVADJACTIVITY loop
  if adj.newinvstatus = 'SU' then -- into suspense
     --out of old
     curFunc := dbms_sql.open_cursor;
     dbms_sql.parse(curFunc, 'insert into stdinvadj947_' || strSuffix ||
        ' values (:whenoccurred,:lpid,:facility,:custid,:item,:lotnumber,:inventoryclass,:invstatus,'||
          ' :uom,:adjqty,:adjreason,:tasktype,:adjuser,:lastuser,:lastupdate,:serialnumber,'||
          ' :useritem1,:useritem2,:useritem3,:oldcustid,:olditem,:oldlotnumber,:oldinventoryclass,'||
          ' :oldinvstatus,:newcustid,:newitem,:newlotnumber, :newinventoryclass,:newinvstatus,'||
          ' :adjweight,:custreference) ',
          dbms_sql.native);
      dbms_sql.bind_variable(curFunc, ':whenoccurred', adj.whenoccurred);
      dbms_sql.bind_variable(curFunc, ':lpid',adj.lpid);
      dbms_sql.bind_variable(curFunc, ':facility',adj.facility);
      dbms_sql.bind_variable(curFunc, ':custid', adj.custid);
      dbms_sql.bind_variable(curFunc, ':item', adj.item);
      dbms_sql.bind_variable(curFunc, ':lotnumber', adj.lotnumber);
      dbms_sql.bind_variable(curFunc, ':inventoryclass', adj.inventoryclass);
      dbms_sql.bind_variable(curFunc, ':invstatus', adj.invstatus);
      dbms_sql.bind_variable(curFunc, ':uom', adj.uom);
      dbms_sql.bind_variable(curFunc, ':adjqty', -1 * adj.adjqty);
      dbms_sql.bind_variable(curFunc, ':adjreason', adj.adjreason);
      dbms_sql.bind_variable(curFunc, ':tasktype', adj.tasktype);
      dbms_sql.bind_variable(curFunc, ':adjuser', adj.adjuser);
      dbms_sql.bind_variable(curFunc, ':lastuser', adj.lastuser);
      dbms_sql.bind_variable(curFunc, ':lastupdate', adj.lastupdate);
      dbms_sql.bind_variable(curFunc, ':serialnumber', adj.serialnumber);
      dbms_sql.bind_variable(curFunc, ':useritem1', adj.useritem1);
      dbms_sql.bind_variable(curFunc, ':useritem2', adj.useritem2);
      dbms_sql.bind_variable(curFunc, ':useritem3', adj.useritem3);
      dbms_sql.bind_variable(curFunc, ':oldcustid', adj.oldcustid);
      dbms_sql.bind_variable(curFunc, ':olditem', adj.olditem);
      dbms_sql.bind_variable(curFunc, ':oldlotnumber', adj.oldlotnumber);
      dbms_sql.bind_variable(curFunc, ':oldinventoryclass', adj.oldinventoryclass);
      dbms_sql.bind_variable(curFunc, ':oldinvstatus', adj.oldinvstatus);
      dbms_sql.bind_variable(curFunc, ':newcustid', adj.newcustid);
      dbms_sql.bind_variable(curFunc, ':newitem', adj.newitem);
      dbms_sql.bind_variable(curFunc, ':newlotnumber', adj.newlotnumber);
      dbms_sql.bind_variable(curFunc, ':newinventoryclass', adj.newinventoryclass);
      dbms_sql.bind_variable(curFunc, ':newinvstatus', adj.newinvstatus);
      dbms_sql.bind_variable(curFunc, ':adjweight', adj.adjweight);
      dbms_sql.bind_variable(curFunc, ':custreference', adj.custreference);
      cntRows := dbms_sql.EXECUTE(curFunc);
      dbms_sql.close_cursor(curFunc);
      -- suspense side
      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, 'insert into stdinvadj947_' || strSuffix ||
         ' values (:whenoccurred,:lpid,:facility,:custid,:item,:lotnumber,:inventoryclass,:invstatus,'||
           ' :uom,:adjqty,:adjreason,:tasktype,:adjuser,:lastuser,:lastupdate,:serialnumber,'||
           ' :useritem1,:useritem2,:useritem3,:oldcustid,:olditem,:oldlotnumber,:oldinventoryclass,'||
           ' :oldinvstatus,:newcustid,:newitem,:newlotnumber, :newinventoryclass,:newinvstatus,'||
           ' :adjweight,:custreference) ',
           dbms_sql.native);
       dbms_sql.bind_variable(curFunc, ':whenoccurred', adj.whenoccurred);
       dbms_sql.bind_variable(curFunc, ':lpid',adj.lpid);
       dbms_sql.bind_variable(curFunc, ':facility',adj.facility);
       dbms_sql.bind_variable(curFunc, ':custid', adj.custid);
       dbms_sql.bind_variable(curFunc, ':item', adj.item);
       dbms_sql.bind_variable(curFunc, ':lotnumber', adj.newlotnumber);
       dbms_sql.bind_variable(curFunc, ':inventoryclass', adj.newinventoryclass);
       dbms_sql.bind_variable(curFunc, ':invstatus', adj.newinvstatus);
       dbms_sql.bind_variable(curFunc, ':uom', adj.uom);
       dbms_sql.bind_variable(curFunc, ':adjqty', adj.adjqty);
       dbms_sql.bind_variable(curFunc, ':adjreason', adj.adjreason);
       dbms_sql.bind_variable(curFunc, ':tasktype', adj.tasktype);
       dbms_sql.bind_variable(curFunc, ':adjuser', adj.adjuser);
       dbms_sql.bind_variable(curFunc, ':lastuser', adj.lastuser);
       dbms_sql.bind_variable(curFunc, ':lastupdate', adj.lastupdate);
       dbms_sql.bind_variable(curFunc, ':serialnumber', adj.serialnumber);
       dbms_sql.bind_variable(curFunc, ':useritem1', adj.useritem1);
       dbms_sql.bind_variable(curFunc, ':useritem2', adj.useritem2);
       dbms_sql.bind_variable(curFunc, ':useritem3', adj.useritem3);
       dbms_sql.bind_variable(curFunc, ':oldcustid', adj.custid);
       dbms_sql.bind_variable(curFunc, ':olditem', adj.item);
       dbms_sql.bind_variable(curFunc, ':oldlotnumber', adj.lotnumber);
       dbms_sql.bind_variable(curFunc, ':oldinventoryclass', adj.inventoryclass);
       dbms_sql.bind_variable(curFunc, ':oldinvstatus', adj.invstatus);
       dbms_sql.bind_variable(curFunc, ':newcustid', ' ');
       dbms_sql.bind_variable(curFunc, ':newitem', ' ');
       dbms_sql.bind_variable(curFunc, ':newlotnumber', ' ');
       dbms_sql.bind_variable(curFunc, ':newinventoryclass', ' ');
       dbms_sql.bind_variable(curFunc, ':newinvstatus', ' ');
       dbms_sql.bind_variable(curFunc, ':adjweight', adj.adjweight);
       dbms_sql.bind_variable(curFunc, ':custreference', adj.custreference);
       cntRows := dbms_sql.EXECUTE(curFunc);
       dbms_sql.close_cursor(curFunc);

  elsif adj.invstatus = 'SU' then -- out of suspense
     curFunc := dbms_sql.open_cursor;
     dbms_sql.parse(curFunc, 'insert into stdinvadj947_' || strSuffix ||
        ' values (:whenoccurred,:lpid,:facility,:custid,:item,:lotnumber,:inventoryclass,:invstatus,'||
          ' :uom,:adjqty,:adjreason,:tasktype,:adjuser,:lastuser,:lastupdate,:serialnumber,'||
          ' :useritem1,:useritem2,:useritem3,:oldcustid,:olditem,:oldlotnumber,:oldinventoryclass,'||
          ' :oldinvstatus,:newcustid,:newitem,:newlotnumber, :newinventoryclass,:newinvstatus,'||
          ' :adjweight,:custreference) ',
          dbms_sql.native);
      dbms_sql.bind_variable(curFunc, ':whenoccurred', adj.whenoccurred);
      dbms_sql.bind_variable(curFunc, ':lpid',adj.lpid);
      dbms_sql.bind_variable(curFunc, ':facility',adj.facility);
      dbms_sql.bind_variable(curFunc, ':custid', adj.custid);
      dbms_sql.bind_variable(curFunc, ':item', adj.item);
      dbms_sql.bind_variable(curFunc, ':lotnumber', adj.lotnumber);
      dbms_sql.bind_variable(curFunc, ':inventoryclass', adj.inventoryclass);
      dbms_sql.bind_variable(curFunc, ':invstatus', adj.invstatus);
      dbms_sql.bind_variable(curFunc, ':uom', adj.uom);
      dbms_sql.bind_variable(curFunc, ':adjqty', adj.adjqty);
      dbms_sql.bind_variable(curFunc, ':adjreason', adj.adjreason);
      dbms_sql.bind_variable(curFunc, ':tasktype', adj.tasktype);
      dbms_sql.bind_variable(curFunc, ':adjuser', adj.adjuser);
      dbms_sql.bind_variable(curFunc, ':lastuser', adj.lastuser);
      dbms_sql.bind_variable(curFunc, ':lastupdate', adj.lastupdate);
      dbms_sql.bind_variable(curFunc, ':serialnumber', adj.serialnumber);
      dbms_sql.bind_variable(curFunc, ':useritem1', adj.useritem1);
      dbms_sql.bind_variable(curFunc, ':useritem2', adj.useritem2);
      dbms_sql.bind_variable(curFunc, ':useritem3', adj.useritem3);
      dbms_sql.bind_variable(curFunc, ':oldcustid', adj.oldcustid);
      dbms_sql.bind_variable(curFunc, ':olditem', adj.olditem);
      dbms_sql.bind_variable(curFunc, ':oldlotnumber', adj.oldlotnumber);
      dbms_sql.bind_variable(curFunc, ':oldinventoryclass', adj.oldinventoryclass);
      dbms_sql.bind_variable(curFunc, ':oldinvstatus', adj.oldinvstatus);
      dbms_sql.bind_variable(curFunc, ':newcustid', adj.newcustid);
      dbms_sql.bind_variable(curFunc, ':newitem', adj.newitem);
      dbms_sql.bind_variable(curFunc, ':newlotnumber', adj.newlotnumber);
      dbms_sql.bind_variable(curFunc, ':newinventoryclass', adj.newinventoryclass);
      dbms_sql.bind_variable(curFunc, ':newinvstatus', adj.newinvstatus);
      dbms_sql.bind_variable(curFunc, ':adjweight', adj.adjweight);
      dbms_sql.bind_variable(curFunc, ':custreference', adj.custreference);
      cntRows := dbms_sql.EXECUTE(curFunc);
      dbms_sql.close_cursor(curFunc);

      curFunc := dbms_sql.open_cursor;
      dbms_sql.parse(curFunc, 'insert into stdinvadj947_' || strSuffix ||
         ' values (:whenoccurred,:lpid,:facility,:custid,:item,:lotnumber,:inventoryclass,:invstatus,'||
           ' :uom,:adjqty,:adjreason,:tasktype,:adjuser,:lastuser,:lastupdate,:serialnumber,'||
           ' :useritem1,:useritem2,:useritem3,:oldcustid,:olditem,:oldlotnumber,:oldinventoryclass,'||
           ' :oldinvstatus,:newcustid,:newitem,:newlotnumber, :newinventoryclass,:newinvstatus,'||
           ' :adjweight,:custreference) ',
           dbms_sql.native);
       dbms_sql.bind_variable(curFunc, ':whenoccurred', adj.whenoccurred);
       dbms_sql.bind_variable(curFunc, ':lpid',adj.lpid);
       dbms_sql.bind_variable(curFunc, ':facility',adj.facility);
       dbms_sql.bind_variable(curFunc, ':custid', adj.newcustid);
       dbms_sql.bind_variable(curFunc, ':item', adj.newitem);
       dbms_sql.bind_variable(curFunc, ':lotnumber', adj.newlotnumber);
       dbms_sql.bind_variable(curFunc, ':inventoryclass', adj.newinventoryclass);
       dbms_sql.bind_variable(curFunc, ':invstatus', adj.newinvstatus);
       dbms_sql.bind_variable(curFunc, ':uom', adj.uom);
       dbms_sql.bind_variable(curFunc, ':adjqty', -1 * adj.adjqty);
       dbms_sql.bind_variable(curFunc, ':adjreason', adj.adjreason);
       dbms_sql.bind_variable(curFunc, ':tasktype', adj.tasktype);
       dbms_sql.bind_variable(curFunc, ':adjuser', adj.adjuser);
       dbms_sql.bind_variable(curFunc, ':lastuser', adj.lastuser);
       dbms_sql.bind_variable(curFunc, ':lastupdate', adj.lastupdate);
       dbms_sql.bind_variable(curFunc, ':serialnumber', adj.serialnumber);
       dbms_sql.bind_variable(curFunc, ':useritem1', adj.useritem1);
       dbms_sql.bind_variable(curFunc, ':useritem2', adj.useritem2);
       dbms_sql.bind_variable(curFunc, ':useritem3', adj.useritem3);
       dbms_sql.bind_variable(curFunc, ':oldcustid', adj.custid);
       dbms_sql.bind_variable(curFunc, ':olditem', adj.item);
       dbms_sql.bind_variable(curFunc, ':oldlotnumber', adj.lotnumber);
       dbms_sql.bind_variable(curFunc, ':oldinventoryclass', adj.inventoryclass);
       dbms_sql.bind_variable(curFunc, ':oldinvstatus', adj.invstatus);
       dbms_sql.bind_variable(curFunc, ':newcustid', ' ');
       dbms_sql.bind_variable(curFunc, ':newitem', ' ');
       dbms_sql.bind_variable(curFunc, ':newlotnumber', ' ');
       dbms_sql.bind_variable(curFunc, ':newinventoryclass', ' ');
       dbms_sql.bind_variable(curFunc, ':newinvstatus', ' ');
       dbms_sql.bind_variable(curFunc, ':adjweight', adj.adjweight);
       dbms_sql.bind_variable(curFunc, ':custreference', adj.custreference);
       cntRows := dbms_sql.EXECUTE(curFunc);
       dbms_sql.close_cursor(curFunc);

  else

     curFunc := dbms_sql.open_cursor;
     dbms_sql.parse(curFunc, 'insert into stdinvadj947_' || strSuffix ||
        ' values (:whenoccurred,:lpid,:facility,:custid,:item,:lotnumber,:inventoryclass,:invstatus,'||
          ' :uom,:adjqty,:adjreason,:tasktype,:adjuser,:lastuser,:lastupdate,:serialnumber,'||
          ' :useritem1,:useritem2,:useritem3,:oldcustid,:olditem,:oldlotnumber,:oldinventoryclass,'||
          ' :oldinvstatus,:newcustid,:newitem,:newlotnumber, :newinventoryclass,:newinvstatus,'||
          ' :adjweight,:custreference) ',
          dbms_sql.native);
      dbms_sql.bind_variable(curFunc, ':whenoccurred', adj.whenoccurred);
      dbms_sql.bind_variable(curFunc, ':lpid',adj.lpid);
      dbms_sql.bind_variable(curFunc, ':facility',adj.facility);
      dbms_sql.bind_variable(curFunc, ':custid', adj.custid);
      dbms_sql.bind_variable(curFunc, ':item', adj.item);
      dbms_sql.bind_variable(curFunc, ':lotnumber', adj.lotnumber);
      dbms_sql.bind_variable(curFunc, ':inventoryclass', adj.inventoryclass);
      dbms_sql.bind_variable(curFunc, ':invstatus', adj.invstatus);
      dbms_sql.bind_variable(curFunc, ':uom', adj.uom);
      dbms_sql.bind_variable(curFunc, ':adjqty', adj.adjqty);
      dbms_sql.bind_variable(curFunc, ':adjreason', adj.adjreason);
      dbms_sql.bind_variable(curFunc, ':tasktype', adj.tasktype);
      dbms_sql.bind_variable(curFunc, ':adjuser', adj.adjuser);
      dbms_sql.bind_variable(curFunc, ':lastuser', adj.lastuser);
      dbms_sql.bind_variable(curFunc, ':lastupdate', adj.lastupdate);
      dbms_sql.bind_variable(curFunc, ':serialnumber', adj.serialnumber);
      dbms_sql.bind_variable(curFunc, ':useritem1', adj.useritem1);
      dbms_sql.bind_variable(curFunc, ':useritem2', adj.useritem2);
      dbms_sql.bind_variable(curFunc, ':useritem3', adj.useritem3);
      dbms_sql.bind_variable(curFunc, ':oldcustid', adj.oldcustid);
      dbms_sql.bind_variable(curFunc, ':olditem', adj.olditem);
      dbms_sql.bind_variable(curFunc, ':oldlotnumber', adj.oldlotnumber);
      dbms_sql.bind_variable(curFunc, ':oldinventoryclass', adj.oldinventoryclass);
      dbms_sql.bind_variable(curFunc, ':oldinvstatus', adj.oldinvstatus);
      dbms_sql.bind_variable(curFunc, ':newcustid', adj.newcustid);
      dbms_sql.bind_variable(curFunc, ':newitem', adj.newitem);
      dbms_sql.bind_variable(curFunc, ':newlotnumber', adj.newlotnumber);
      dbms_sql.bind_variable(curFunc, ':newinventoryclass', adj.newinventoryclass);
      dbms_sql.bind_variable(curFunc, ':newinvstatus', adj.newinvstatus);
      dbms_sql.bind_variable(curFunc, ':adjweight', adj.adjweight);
      dbms_sql.bind_variable(curFunc, ':custreference', adj.custreference);
      cntRows := dbms_sql.EXECUTE(curFunc);
      dbms_sql.close_cursor(curFunc);

  end if;

end loop;

-- create hdr view
cmdSql := 'create view stdinvadj947hdr_' || strSuffix ||
 ' (custid,trandate,adjno,cust_name,cust_addr1,cust_addr2,'||
 '  cust_city,cust_state,cust_postalcode,facility,facility_name,'||
 '  facility_addr1,facility_addr2,facility_city,facility_state,'||
 '  facility_postalcode) '||
 'as select distinct I.custid,to_char(I.whenoccurred,''YYYYMMDD''),' ||
 '   to_char(I.whenoccurred,''YYYYMMDDHH24MISS''),'||
 '  C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
 '  F.facility,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode '||
 ' from facility F, customer C, stdinvadj947_' || strSuffix || ' I ' ||
 ' where I.custid = ''' ||in_custid|| ''''||
 '  and I.whenoccurred >= to_date('''||in_begdatestr||''',''yyyymmddhh24miss'') '||
 '  and I.whenoccurred <  to_date('''||in_enddatestr||''',''yyyymmddhh24miss'') '||
 '  and I.custid = C.custid(+)'||
 '  and I.facility = F.facility(+)';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create dtl view
cmdSql := 'create view stdinvadj947dtl_' || strSuffix ||
 ' (whenoccurred, lpid, facility, custid, item, lotnumber, inventoryclass, invstatus, uom, ' ||
  ' adjqty, adjreason, adjuser, serialnumber, useritem1, useritem2, useritem3, oldcustid, ' ||
  ' olditem, oldlotnumber, oldinventoryclass, oldinvstatus, newcustid, newitem, newlotnumber, newinventoryclass, ' ||
  ' newinvstatus, adjweight, custreference, adjno) ' ||
  ' as select whenoccurred, lpid, facility, custid, item, lotnumber, inventoryclass, invstatus, uom, ' ||
  ' adjqty, adjreason, adjuser, serialnumber, useritem1, useritem2, useritem3, oldcustid, ' ||
  ' olditem, oldlotnumber, oldinventoryclass, oldinvstatus, newcustid, newitem, newlotnumber, newinventoryclass, ' ||
  ' newinvstatus, adjweight, custreference, to_char(whenoccurred,''YYYYMMDDHH24MISS'') ' ||
 '   from stdinvadj947_' || strSuffix ||
 ' where custid = ''' ||in_custid|| ''''||
 '  and whenoccurred >= to_date('''||in_begdatestr||''',''yyyymmddhh24miss'') '||
 '  and whenoccurred <  to_date('''||in_enddatestr||''',''yyyymmddhh24miss'')';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);






out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zbs947 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_invadj947std_susp;

PROCEDURE end_invadj947std_susp
(in_custid IN VARCHAR2
,in_viewsuffix IN VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT VARCHAR2
) IS

curFunc INTEGER;
cntRows INTEGER;
cmdSql VARCHAR2(20000);

strSuffix VARCHAR2(32);

BEGIN

out_errorno := 0;
out_msg := '';

strSuffix := RTRIM(UPPER(in_custid)) || in_viewsuffix;

DELETE FROM INVADJ947DTLEX WHERE sessionid = strSuffix;

cmdSql := 'drop VIEW stdinvadj947dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.EXECUTE(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stdinvadj947hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.EXECUTE(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table stdinvadj947_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.EXECUTE(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

EXCEPTION WHEN OTHERS THEN
  out_msg := 'zess947 ' || SQLERRM;
  out_errorno := SQLCODE;
END end_invadj947std_susp;

----------------------------------------------------------------------
-- begin_stdinvadj947
----------------------------------------------------------------------
procedure begin_invadj947std
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_rowid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;


cursor C_LPID(in_lpid varchar2) is
  select DR.descr
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code;

dteTest date;

errmsg varchar2(100);
mark varchar2(20);

intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strMsg varchar2(255);
qtyAdjust number(7);
strRefDesc varchar2(45);
strNewRsnCode invadjactivity.adjreason%TYPE;
qtyAdjNew  invadjactivity.adjqty%TYPE;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' ' ||out_msg;
  zms.log_autonomous_msg('947', 'JCT', rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), '947', strMsg);
end;

begin

mark := 'Start';

out_errorno := 0;
out_msg := '';
viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'STDINVADJ947HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;
out_msg := strSuffix || ' ' || in_custid || ' ' || in_begdatestr || ' ' || in_enddatestr;
order_msg('I');
out_msg := '';

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

-- Verify the dates
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

-- create hdr view
cmdSql := 'create view stdinvadj947hdr_' || strSuffix ||
 ' (custid,trandate,adjno,cust_name,cust_addr1,cust_addr2,'||
 '  cust_city,cust_state,cust_postalcode,facility,facility_name,'||
 '  facility_addr1,facility_addr2,facility_city,facility_state,'||
 '  facility_postalcode) '||
 'as select distinct I.custid,to_char(I.whenoccurred,''YYYYMMDD''),' ||
 '   to_char(I.whenoccurred,''YYYYMMDDHH24MISS''),'||
 '  C.name,C.addr1,C.addr2,C.city,C.state,C.postalcode,'||
 '  F.facility,F.name,F.addr1,F.addr2,F.city,F.state,F.postalcode '||
 ' from facility F, customer C, invadjactivity I ' ||
 ' where I.custid = ''' ||in_custid|| '''';
 if length(rtrim(in_rowid)) > 12 then
   cmdSql := cmdSql || ' and I.rowid = ''' || in_rowid || '''';
 else
   cmdSql := cmdSql ||
   '  and I.whenoccurred >= to_date('''||in_begdatestr||''',''yyyymmddhh24miss'') '||
   '  and I.whenoccurred <  to_date('''||in_enddatestr||''',''yyyymmddhh24miss'') ';
 end if;
 cmdSql := cmdSql ||
 '  and I.custid = C.custid(+)'||
 '  and I.facility = F.facility(+) ' ||
 '  and nvl(I.suppress_edi_yn,''N'') != ''Y''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- create dtl view
cmdSql := 'create view stdinvadj947dtl_' || strSuffix ||
 ' (whenoccurred, lpid, facility, custid, item, lotnumber, inventoryclass, invstatus, uom, ' ||
  ' adjqty, adjreason, adjuser, serialnumber, useritem1, useritem2, useritem3, oldcustid, ' ||
  ' olditem, oldlotnumber, oldinventoryclass, oldinvstatus, newcustid, newitem, newlotnumber, newinventoryclass, ' ||
  ' newinvstatus, adjweight, custreference, adjno) ' ||
  ' as select whenoccurred, lpid, facility, custid, item, lotnumber, inventoryclass, invstatus, uom, ' ||
  ' adjqty, adjreason, adjuser, serialnumber, useritem1, useritem2, useritem3, oldcustid, ' ||
  ' olditem, oldlotnumber, oldinventoryclass, oldinvstatus, newcustid, newitem, newlotnumber, newinventoryclass, ' ||
  ' newinvstatus, adjweight, custreference, to_char(whenoccurred,''YYYYMMDDHH24MISS'') ' ||
 '   from invadjactivity '||
 ' where custid = ''' ||in_custid|| '''';
 if length(rtrim(in_rowid)) > 12 then
   cmdSql := cmdSql || ' and rowid = ''' || in_rowid || '''';
 else
   cmdSql := cmdSql ||
   '  and whenoccurred >= to_date('''||in_begdatestr||''',''yyyymmddhh24miss'') '||
   '  and whenoccurred <  to_date('''||in_enddatestr||''',''yyyymmddhh24miss'') ';
 end if;
 cmdSql := cmdSql ||
 '  and nvl(suppress_edi_yn,''N'') != ''Y''';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zb947 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_invadj947std;

PROCEDURE end_invadj947std
(in_custid IN VARCHAR2
,in_viewsuffix IN VARCHAR2
,out_errorno IN OUT NUMBER
,out_msg IN OUT VARCHAR2
) IS

curFunc INTEGER;
cntRows INTEGER;
cmdSql VARCHAR2(20000);

strSuffix VARCHAR2(32);

BEGIN

out_errorno := 0;
out_msg := '';

strSuffix := RTRIM(UPPER(in_custid)) || in_viewsuffix;

DELETE FROM INVADJ947DTLEX WHERE sessionid = strSuffix;

cmdSql := 'drop VIEW stdinvadj947dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.EXECUTE(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stdinvadj947hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.EXECUTE(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

EXCEPTION WHEN OTHERS THEN
  out_msg := 'zes947 ' || SQLERRM;
  out_errorno := SQLCODE;
END end_invadj947std;

procedure begin_952
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

cursor C_INVADJACTIVITY is
  select IA.rowid,IA.*, U.upc
    from custitemupcview U, invadjactivity IA
   where IA.custid = in_custid
     and IA.whenoccurred >= to_date(in_begdatestr,'yyyymmddhh24miss')
     and IA.whenoccurred <  to_date(in_enddatestr,'yyyymmddhh24miss')
     and IA.custid = U.custid(+)
     and IA.item = U.item(+);
cursor C_LPID(in_lpid varchar2) is
  select DR.descr, holdreason
    from damageditemreasons DR, plate P
   where P.lpid = in_lpid
     and P.condition = DR.code;
dteTest date;
errmsg varchar2(100);
mark varchar2(20);
intErrorNo integer;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strMsg varchar2(255);
qtyAdjust number(7);
strRefDesc varchar2(45);
strHoldReason VARCHAR2(2);
begin
mark := 'Start';
out_errorno := 0;
out_msg := '';
viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'IA952HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;
out_errorno := viewcount;
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
  for adj in C_INVADJACTIVITY loop
      zmi3.get_whse(adj.custid,adj.inventoryclass,strWhse,
            strRegWhse,strRetWhse);
      if strWhse is not null then
         zedi.validate_interface(adj.rowid,strMovementCode,intErrorNo,strMsg);
         if intErrorNo = 0 then
            strRefDesc := null;
            if adj.newinvstatus = 'DM' and adj.invstatus != 'DM' then
               OPEN C_LPID(adj.lpid);
               FETCH C_LPID into strRefDesc, strHoldReason;
               CLOSE C_LPID;
            end if;
            if ((adj.inventoryclass !=
                  nvl(adj.newinventoryclass,adj.inventoryclass)) or
                (adj.invstatus !=
                  nvl(adj.newinvstatus,adj.invstatus)) ) then
               qtyAdjust := adj.adjqty * -1;
            else
               qtyAdjust := adj.adjqty;
            end if;
            insert into invadj947dtlex
               (
                   sessionid,
                   whenoccurred,
                   lpid,
                   facility,
                   custid,
                   rsncode,
                   quantity,
                   uom,
                   upc,
                   item,
                   lotno,
                   dmgdesc,
                   lotnumber,
                   holdreason
               )
            values
               (
                   strSuffix,
                   adj.whenoccurred,
                   adj.lpid,
                   adj.facility,
                   adj.custid,
                   strMovementCode,
                   qtyAdjust,
                   adj.uom,
                   adj.upc,
                   adj.item,
                   adj.lpid,
                   strRefDesc,
                   adj.lotnumber,
                   strHoldReason
               );
         end if;
      end if;
  end loop;
cmdSql := 'create view ia952hdr_' || strSuffix ||
 ' (custid,idcode,facilityid,soldto,shipto,transactiondate) '||
 'as select ''8017'' CUSTID,''01'' idcode, ''118'' FACILITYID, ''SOLDTO'' SOLDTO,''20789'' SHIPTO,sysdate TRANSACTIONDATE from dual';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
cmdSql := 'create view ia952dtl_' || strSuffix ||
  ' (custid,facilityid,idcode,item,upc,gtin,description,lotnumber,rsncode,baseuom,baseqty,eauom,eaqty) as '||
  ' select '||
  ' custid, '||
  ' ''118'', '||
  ' ''03'' IDCODE, '||
  ' item, '||
  ' (select U.itemalias from custitemalias U where U.custid = od.custid and U.item = od.item and U.ALIASDESC like ''UPC%'' and rownum = 1) as UPC, '||
  ' (select SUBSTR(U.itemalias,1,14) from custitemalias U where U.custid = od.custid and U.item = od.ITEM and U.aliasdesc like ''GTIN%'' and rownum = 1) as gtin, '||
  ' dtlpassthruchar10 description, '||
  ' lotnumber, '||
  ' linestatus, '||
  ' uom baseuom, '||
  ' qtyrcvd baseqty, '||
  ' ''EA'' eauom, '||
  ' Decode( zlbl.uom_qty_conv(CUSTID, item, nvl(qtyrcvd,0), od.uom, ''EA''), 99999,nvl(qtyrcvd,0), zlbl.uom_qty_conv(CUSTID, item, nvl(qtyrcvd,0), od.uom, ''EA'') ) EAQTY '||
  ' from orderdtl od where qtyrcvd>0 and orderid in(select orderid from orderhdr where custid=''8017'' and (reference like ''CR %'' or po like ''% R'') and orderstatus =''R'' and statusupdate between to_date(''' || in_begdatestr || ''',''yyyymmddhh24miss'') and to_date(''' || in_enddatestr || ''',''yyyymmddhh24miss'')) '||
  ' union all '||
  ' select  '||
  ' custid, '||
  ' facility, '||
  ' ''04'' IDCODE, '||
  ' item, '||
  ' upc, '||
  ' (select SUBSTR(U.itemalias,1,14) from custitemalias u where U.custid = i.custid and u.item = i.ITEM and u.aliasdesc like ''GTIN%'' and rownum = 1) as gtin,  '||
  ' lpid description, '||
  ' nvl(lotnumber,''(none)'') lotnumber, '||
  ' rsncode, '||
  ' uom baseuom, '||
  ' case when rsncode=''AVXX'' then quantity * -1 else quantity end baseqty, '||
  ' ''EA'' EAUOM, '||
  ' case when rsncode=''AVXX'' then Decode( zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(quantity,0), I.uom, ''EA''), 99999,nvl(quantity,0), zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(quantity,0), I.uom, ''EA'') )*-1 else Decode( zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(quantity,0), I.uom, ''EA''), 99999,nvl(quantity,0), zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(quantity,0), I.uom, ''EA'') ) end EAQTY '||
  ' from invadj947dtlex i  '||
  ' where quantity <> 0  '||
  ' and sessionid = '''||strSuffix||''''||
  ' union all '||
  ' select  '||
  ' CI.custid,  '||
  ' I.facility,  '||
  ' ''05'' IDCODE, '||
  ' CI.item,  '||
  ' (select U.itemalias from custitemalias U where U.custid = ci.custid and U.item = CI.item and U.ALIASDESC like ''UPC%'' and rownum = 1) as UPC,  '||
  ' (select SUBSTR(U.itemalias,1,14) from custitemalias U where U.custid = ci.custid and U.item = CI.ITEM and U.aliasdesc like ''GTIN%'' and rownum = 1) as gtin, '||
  ' CI.descr,  '||
  ' I.LOTNUMBER, '||
  ' ''00'', '||
  ' nvl(I.uom,CI.baseuom) BASEUOM, '||
  ' sum(nvl(qty,0)) BASEQTY,  '||
  ' ''EA'' EAUOM, '||
  ' sum( Decode( zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA''), 99999,nvl(qty,0), zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA'') )  ) EAQTY '||
  ' from custitem CI, custitemtot I  '||
  ' where CI.custid = ''8017'' '||
  ' and I.custid(+) = CI.custid  '||
  ' and I.item(+) = CI.item  '||
  ' and I.status(+) not in (''D'', ''P'', ''U'', ''CM'')  '||
  ' and CI.status = ''ACTV''  '||
  ' and CI.item not in (''UNKNOWN'', ''RETURNS'', ''x'')  '||
  ' and qty > 0 '||
  ' GROUP BY i.facility,ci.custid,ci.item,i.lotnumber,ci.descr,ci.baseuom,nvl(I.uom,CI.baseuom) '||
  ' union all '||
  ' select  '||
  ' CI.custid,  '||
  ' I.facility,  '||
  ' ''05'' IDCODE, '||
  ' CI.item,  '||
  ' (select U.itemalias from custitemalias U where U.custid = ci.custid and U.item = CI.item and U.ALIASDESC like ''UPC%'' and rownum = 1) as UPC,  '||
  ' (select SUBSTR(U.itemalias,1,14) from custitemalias U where U.custid = ci.custid and U.item = CI.ITEM and U.aliasdesc like ''GTIN%'' and rownum = 1) as gtin, '||
  ' CI.descr,  '||
  ' I.LOTNUMBER, '||
  ' decode(nvl(I.invstatus,''AV''), ''DM'',''DM'',''AV'',''AV'',''QH''), '||
  ' nvl(I.uom,CI.baseuom) BASEUOM, '||
  ' sum(nvl(qty,0)) BASEQTY,  '||
  ' ''EA'' EAUOM, '||
  ' sum( Decode( zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA''), 99999,nvl(qty,0), zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA'') )  ) EAQTY '||
  ' from custitem CI, custitemtot I  '||
  ' where CI.custid = ''8017'' '||
  ' and I.custid(+) = CI.custid  '||
  ' and I.item(+) = CI.item  '||
  ' and I.status(+) not in (''D'', ''P'', ''U'', ''CM'')  '||
  ' and decode(nvl(I.invstatus(+),''AV''), ''DM'',''DM'',''AV'',''AV'',''RW'',''RW'',''QH'')=''AV'' '||
  ' and CI.status = ''ACTV''  '||
  ' and CI.item not in (''UNKNOWN'', ''RETURNS'', ''x'')  '||
  ' and qty > 0 '||
  ' GROUP BY i.facility,ci.custid,ci.item,i.lotnumber,ci.descr,ci.baseuom,decode(nvl(I.invstatus,''AV''), ''DM'',''DM'',''AV'',''AV'',''QH''),nvl(I.uom,CI.baseuom) '||
  ' union all '||
  ' select  '||
  ' CI.custid,  '||
  ' I.facility,  '||
  ' ''05'' IDCODE, '||
  ' CI.item,  '||
  ' (select U.itemalias from custitemalias U where U.custid = ci.custid and U.item = CI.item and U.ALIASDESC like ''UPC%'' and rownum = 1) as UPC,  '||
  ' (select SUBSTR(U.itemalias,1,14) from custitemalias U where U.custid = ci.custid and U.item = CI.ITEM and U.aliasdesc like ''GTIN%'' and rownum = 1) as gtin, '||
  ' CI.descr,  '||
  ' I.LOTNUMBER, '||
  ' decode(nvl(I.invstatus,''DM''), ''DM'',''DM'',''AV'',''AV'',''QH''), '||
  ' nvl(I.uom,CI.baseuom) BASEUOM, '||
  ' sum(nvl(qty,0)) BASEQTY,  '||
  ' ''EA'' EAUOM, '||
  ' sum( Decode( zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA''), 99999,nvl(qty,0), zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA'') )  ) EAQTY '||
  ' from custitem CI, custitemtot I  '||
  ' where CI.custid = ''8017'' '||
  ' and I.custid(+) = CI.custid  '||
  ' and I.item(+) = CI.item  '||
  ' and I.status(+) not in (''D'', ''P'', ''U'', ''CM'')  '||
  ' and decode(nvl(I.invstatus(+),''DM''), ''DM'',''DM'',''AV'',''AV'',''RW'',''RW'',''QH'')=''DM'' '||
  ' and CI.status = ''ACTV''  '||
  ' and CI.item not in (''UNKNOWN'', ''RETURNS'', ''x'')  '||
  ' and qty > 0 '||
  ' GROUP BY i.facility,ci.custid,ci.item,i.lotnumber,ci.descr,ci.baseuom,decode(nvl(I.invstatus,''DM''), ''DM'',''DM'',''AV'',''AV'',''QH''),nvl(I.uom,CI.baseuom) '||
  ' union all '||
  ' select  '||
  ' CI.custid,  '||
  ' I.facility,  '||
  ' ''05'' IDCODE, '||
  ' CI.item,  '||
  ' (select U.itemalias from custitemalias U where U.custid = ci.custid and U.item = CI.item and U.ALIASDESC like ''UPC%'' and rownum = 1) as UPC,  '||
  ' (select SUBSTR(U.itemalias,1,14) from custitemalias U where U.custid = ci.custid and U.item = CI.ITEM and U.aliasdesc like ''GTIN%'' and rownum = 1) as gtin, '||
  ' CI.descr,  '||
  ' I.LOTNUMBER, '||
  ' decode(nvl(I.invstatus,''QH''), ''DM'',''DM'',''AV'',''AV'',''QH''), '||
  ' nvl(I.uom,CI.baseuom) BASEUOM, '||
  ' sum(nvl(qty,0)) BASEQTY,  '||
  ' ''EA'' EAUOM, '||
  ' sum( Decode( zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA''), 99999,nvl(qty,0), zlbl.uom_qty_conv(I.CUSTID, I.item, nvl(qty,0), nvl(I.uom,CI.baseuom), ''EA'') )  ) EAQTY '||
  ' from custitem CI, custitemtot I  '||
  ' where CI.custid = ''8017'' '||
  ' and I.custid(+) = CI.custid  '||
  ' and I.item(+) = CI.item  '||
  ' and I.status(+) not in (''D'', ''P'', ''U'', ''CM'')  '||
  ' and decode(nvl(I.invstatus(+),''QH''), ''DM'',''DM'',''AV'',''AV'',''RW'',''RW'',''QH'')=''QH'' '||
  ' and CI.status = ''ACTV''  '||
  ' and CI.item not in (''UNKNOWN'', ''RETURNS'', ''x'')  '||
  ' and qty > 0 '||
  ' GROUP BY i.facility,ci.custid,ci.item,i.lotnumber,ci.descr,ci.baseuom,decode(nvl(I.invstatus,''QH''), ''DM'',''DM'',''AV'',''AV'',''QH''),nvl(I.uom,CI.baseuom) '||
  ' union all '||
    ' select '||
  ' custid, '||
  ' ''118'', '||
  ' ''06'' IDCODE, '||
  ' item, '||
  ' (select U.itemalias from custitemalias U where U.custid = od.custid and U.item = od.item and U.ALIASDESC like ''UPC%'' and rownum = 1) as UPC, '||
  ' (select SUBSTR(U.itemalias,1,14) from custitemalias U where U.custid = od.custid and U.item = od.ITEM and U.aliasdesc like ''GTIN%'' and rownum = 1) as gtin, '||
  ' dtlpassthruchar10 description, '||
  ' lotnumber, '||
  ' linestatus, '||
  ' uom baseuom, '||
  ' qtyrcvd baseqty, '||
  ' ''EA'' eauom, '||
  ' Decode( zlbl.uom_qty_conv(CUSTID, item, nvl(qtyrcvd,0), od.uom, ''EA''), 99999,nvl(qtyrcvd,0), zlbl.uom_qty_conv(CUSTID, item, nvl(qtyrcvd,0), od.uom, ''EA'') ) EAQTY '||
  ' from orderdtl od where qtyrcvd>0 and orderid in(select orderid from orderhdr where custid=''8017'' and substr(reference,1,3)<>''CR '' and substr(po,length(po)-3,3)<>'' R'' and orderstatus =''R'' and statusupdate between to_date(''' || in_begdatestr || ''',''yyyymmddhh24miss'') and to_date(''' || in_enddatestr || ''',''yyyymmddhh24miss'')) ';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
out_msg := 'OKAY';
out_errorno := viewcount;
exception when others then
  out_msg := 'zb952 '||mark||'-' || sqlerrm;
  out_errorno := sqlcode;
end begin_952;
procedure end_952
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
begin
out_errorno := 0;
out_msg := '';
strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;
delete from invadj947dtlex where sessionid = strSuffix;
cmdSql := 'drop VIEW ia952hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
cmdSql := 'drop VIEW ia952dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
out_msg := 'OKAY';
out_errorno := 0;
exception when others then
  out_msg := 'ze952 ' || sqlerrm;
  out_errorno := sqlcode;
end end_952;
END Zimportproc947;


/
show error package body zimportproc947;
exit;
