create or replace package body alps.zimportproc4 as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure begin_c5_extract
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
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'C5_ITEM_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
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

tblWarehouse := 'RG';
cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
  rtrim(in_custid) || ' where code = ''RG'' ';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblWarehouse,12);
  cntRows := dbms_sql.execute(curCompany);
  cntRows := dbms_sql.fetch_rows(curCompany);
  if cntRows > 0 then
    dbms_sql.column_value(curCompany,1,tblWarehouse);
  end if;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

cmdSql := 'create view c5_item_dtl_' || strSuffix ||
 ' (custid,warehouse,item,invstatus,qty) as select lp.custid, ' ||
 ' nvl(cw.abbrev,''' || tblWarehouse || '''),lp.item,lp.invstatus,sum(lp.quantity) ' ||
 ' from class_to_warehouse_' || rtrim(in_custid) || ' cw, plate lp ' ||
 ' where lp.inventoryclass = cw.code(+) '||
 ' and lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.type = ''PA'' ' ||
 ' and lp.status in (''A'',''M'') ' ||
 ' group by lp.custid,cw.abbrev,lp.item,lp.invstatus ';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view c5_file_hdr_' || strSuffix ||
 ' (custid,warehouse,cntitems,qty) as select custid, warehouse, ' ||
 ' count(1),sum(qty) from c5_item_dtl group by custid,warehouse ';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbc5 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_c5_extract;

procedure end_c5_extract
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

cmdSql := 'drop VIEW c5_file_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW c5_item_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimec5 ' || sqlerrm;
  out_errorno := sqlcode;
end end_c5_extract;

procedure trace_msg(in_pos varchar2, in_msg varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg('852', in_pos, '  ', substr(in_msg,1,254),
     'T', '852', strMsg);
  if length(in_msg) > 254 then
     zms.log_msg('852',in_pos || 'A', '  ', substr(in_msg, 255,254),
        'T', '852', strMsg);
  end if;
  if length(in_msg) > 508 then
     zms.log_msg('852',in_pos || 'B', '  ', substr(in_msg, 509,254),
        'T', '852', strMsg);
  end if;
end;

-----------------------------------------------------------------------
--  852 PROCESSING
-----------------------------------------------------------------------

procedure begin_I52_extract
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_zero_bal_yn varchar2
,in_include_all_invstatus_yn varchar2
,in_facility varchar2
,in_refid varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
curSql integer;
curItm integer;
curTime varchar2(16);
cmdSqlCompany varchar2(255);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
cit custitemtot%rowtype;
intPickNotShip integer;

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') ||
               viewcount;
  select count(1)
    into cntRows
    from user_objects
   where object_name = 'I52_ITEM_BAL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
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

tblWarehouse := 'RG';
cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
  rtrim(in_custid) || ' where code = ''RG'' ';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblWarehouse,12);
  cntRows := dbms_sql.execute(curCompany);
  cntRows := dbms_sql.fetch_rows(curCompany);
  if cntRows > 0 then
    dbms_sql.column_value(curCompany,1,tblWarehouse);
  end if;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;
/*
cmdSql := 'create table i52_item_bal_' || strSuffix ||
 ' (custid varchar2(10),warehouse varchar2(12),facility varchar2(3), ' ||
 ' item varchar2(50), diageostatus varchar2(2), ' ||
 ' invstatus varchar2(2), inventoryclass varchar2(2), unitofmeasure varchar2(4),' ||
 ' refid varchar2(2), lotnumber varchar2(30), eventdate date, ' ||
 ' eventtime number(16), qty number(16) ' ||
 ') ';
trace_msg('0', cmdSql);
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'select lp.custid, ' ||
 ' nvl(cw.abbrev,''' || tblWarehouse || '''),lp.facility,lp.item,' ||
 ' lp.invstatus,lp.inventoryclass, unitofmeasure, lotnumber, ' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')), ' ||
 ' sum(lp.quantity) ' ||
 ' from class_to_warehouse_' || rtrim(in_custid) || ' cw, plate lp ' ||
 ' where lp.inventoryclass = cw.code(+) '||
 ' and lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.type = ''PA'' ' ||
 ' and lp.status in (''A'',''M'') ';
*/
cmdSql := 'create table i52_item_bal_' || strSuffix ||
 ' (custid varchar2(10),warehouse varchar2(12),facility varchar2(3), ' ||
 ' item varchar2(50), ' ||
 ' invstatus varchar2(2), inventoryclass varchar2(2), unitofmeasure varchar2(4),' ||
 ' lotnumber varchar2(30), refid varchar2(2), eventdate date, ' ||
 ' eventtime number(16), qty number(16) ' ||
 ') ';
/*
trace_msg('0', cmdSql);
*/
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'select lp.custid, ' ||
 ' lp.facility,lp.facility,lp.item,' ||
 ' lp.invstatus,lp.inventoryclass, unitofmeasure, lotnumber, ' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')), ' ||
 ' sum(lp.quantity), ''A'' ' ||
 ' from  plate lp ' ||
 ' where  '||
 '  lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.type = ''PA'' ' ||
 ' and lp.status in (''A'',''M'') ';
if nvl(rtrim(in_include_all_invstatus_yn),'N') != 'Y' then
  cmdSql := cmdSql || ' and lp.invstatus = ''AV'' ';
end if;
if rtrim(in_facility) is not null then
  cmdSql := cmdSql || ' and lp.facility = ''' || in_facility || ''' ';
end if;
if rtrim(in_refid) is not null then
  cmdSql := cmdSql || ' and decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')) = ''' || in_refid || ''' ';
end if;
cmdSql := cmdSql || ' group by lp.custid,lp.facility,lp.item,' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')),' ||
 ' lp.invstatus,lp.inventoryclass,unitofmeasure,lotnumber ';


cmdSql := cmdsql || ' UNION  select lp.custid, ' ||
 ' lp.facility,lp.facility,lp.item,' ||
 ' lp.invstatus,lp.inventoryclass, unitofmeasure, lotnumber, ' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')), ' ||
 ' sum(lp.quantity), ''B'' ' ||
 ' from  shippingplate lp ' ||
 ' where  '||
 '  lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.status in (''S'',''L'',''P'',''FA'') ' ||
 ' and lp.type in (''F'',''P'') ';
if nvl(rtrim(in_include_all_invstatus_yn),'N') != 'Y' then
  cmdSql := cmdSql || ' and lp.invstatus = ''AV'' ';
end if;
if rtrim(in_facility) is not null then
  cmdSql := cmdSql || ' and lp.facility = ''' || in_facility || ''' ';
end if;
if rtrim(in_refid) is not null then
  cmdSql := cmdSql || ' and decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')) = ''' || in_refid || ''' ';
end if;
cmdSql := cmdSql || ' group by lp.custid,lp.facility,lp.item,' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')),' ||
 ' lp.invstatus,lp.inventoryclass,unitofmeasure,lotnumber ';

/*
trace_msg('D>', cmdSql);
*/

 begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,cit.custid,10);
  dbms_sql.define_column(curSql,2,cit.lastuser,12);
  dbms_sql.define_column(curSql,3,cit.facility,3);
  dbms_sql.define_column(curSql,4,cit.item,20);
  dbms_sql.define_column(curSql,5,cit.invstatus,2);
  dbms_sql.define_column(curSql,6,cit.inventoryclass,2);
  dbms_sql.define_column(curSql,7,cit.uom,4);
  dbms_sql.define_column(curSql,8,cit.lotnumber,30);
  dbms_sql.define_column(curSql,9,cit.refid,2);
  dbms_sql.define_column(curSql,10,cit.qty);
  cntRows := dbms_sql.execute(curSql);
  /*
  trace_msg('DC', cntRows);
  */
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    /*
    trace_msg('Dd', cntRows);
    */
    if cntRows <= 0 then
      exit;
    end if;
    dbms_sql.column_value(curSql,1,cit.custid);
    dbms_sql.column_value(curSql,2,cit.lastuser);
    dbms_sql.column_value(curSql,3,cit.facility);
    dbms_sql.column_value(curSql,4,cit.item);
    dbms_sql.column_value(curSql,5,cit.invstatus);
    dbms_sql.column_value(curSql,6,cit.inventoryclass);
    dbms_sql.column_value(curSql,7,cit.uom);
    dbms_sql.column_value(curSql,8,cit.lotnumber);
    dbms_sql.column_value(curSql,9,cit.refid);
    dbms_sql.column_value(curSql,10,cit.qty);
    /*
    trace_msg('De', cit.custid || cit.facility || cit.invstatus || cit.refid);
    cit.refid := 'XX';
    if cit.invstatus = 'SU' then
       if cit.inventoryclass = 'IB' then
          cit.refid := 'LI';
       end if;
       if cit.inventoryclass = 'RG' then
          cit.refid := 'LT';
       end if;
       if cit.inventoryclass = 'FT' then
          cit.refid := 'LC';
       end if;
    end if;

    if cit.invstatus <> 'SU' then
       if cit.inventoryclass = 'IB' then
          cit.refid := 'IB';
       end if;
       if cit.inventoryclass = 'RG' then
          cit.refid := 'TP';
       end if;
       if cit.inventoryclass = 'FT' then
          cit.refid := 'CB';
       end if;
    end if;

   */

    begin
      curItm := dbms_sql.open_cursor;
      /*
      trace_msg('Eo', strSuffix);
      */
      dbms_sql.parse(curItm, 'insert into i52_item_bal_' || strSuffix ||
        ' values (:custid,:warehouse,:facility,:item,:invstatus,' ||
        ':inventoryclass,:unitofmeasure,:lotnumber,:refid,:eventdate,' ||
        ':eventtime,:qty)',
        dbms_sql.native);
      dbms_sql.bind_variable(curItm, ':custid', cit.custid);
      dbms_sql.bind_variable(curItm, ':warehouse', cit.lastuser);
      dbms_sql.bind_variable(curItm, ':facility', cit.facility);
      dbms_sql.bind_variable(curItm, ':item', cit.item);
      dbms_sql.bind_variable(curItm, ':invstatus', cit.invstatus);
      dbms_sql.bind_variable(curItm, ':inventoryclass', cit.inventoryclass);
      dbms_sql.bind_variable(curItm, ':unitofmeasure', cit.uom);
      dbms_sql.bind_variable(curItm, ':lotnumber', cit.lotnumber);
      dbms_sql.bind_variable(curItm, ':refid', cit.refid);
      select sysdate into cit.eventdate from dual;
      /*
      trace_msg('E1', cit.eventdate);
      */
      dbms_sql.bind_variable(curItm, ':eventdate', cit.eventdate);
      dbms_sql.bind_variable(curItm, ':eventtime', 0);
      dbms_sql.bind_variable(curItm, ':qty', cit.qty);
      cntRows := dbms_sql.execute(curItm);
      /*
      trace_msg('E2', cntRows);
      */
      dbms_sql.close_cursor(curItm);
    exception when others then
      /*
      trace_msg('Ex', cntRows);
      */
      dbms_sql.close_cursor(curItm);
    end;
  end loop;
/*
trace_msg('1Y', cmdSql);
*/
dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;
/*
cmdSql := 'select lp.custid, ' ||
 ' nvl(cw.abbrev,''' || tblWarehouse || '''),lp.item,lp.invstatus,' ||
 ' lp.inventoryclass, ' ||
 ' lp.unitofmeasure, lp.lotnumber,  ' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')), ' ||
 ' sum(lp.qty) ' ||
 ' from class_to_warehouse_' || rtrim(in_custid) || ' cw, custitemtotallview lp ' ||
 ' where lp.inventoryclass = cw.code(+) '||
 ' and lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.status = ''PN'' ';
if nvl(rtrim(in_include_all_invstatus_yn),'N') != 'Y' then
  cmdSql := cmdSql || ' and lp.invstatus = ''AV'' ';
end if;
if rtrim(in_facility) is not null then
  cmdSql := cmdSql || ' and lp.facility = ''' || in_facility || ''' ';
end if;
cmdSql := cmdSql || ' group by lp.custid,cw.abbrev,lp.item,lp.invstatus,' ||
 ' lp.inventoryclass, lp.unitofmeasure, lp.lotnumber,' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')) ';
trace_msg('12', cmdSql);
*/
cmdSql := 'select lp.custid, ' ||
 ' lp.facility,lp.item,lp.invstatus,' ||
 ' lp.inventoryclass, ' ||
 ' lp.unitofmeasure, lp.lotnumber,  ' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')), ' ||
 ' sum(lp.qty) ' ||
 ' from  custitemtotallview lp ' ||
 ' where lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.status = ''PN'' ';
if nvl(rtrim(in_include_all_invstatus_yn),'N') != 'Y' then
  cmdSql := cmdSql || ' and lp.invstatus = ''AV'' ';
end if;
if rtrim(in_facility) is not null then
  cmdSql := cmdSql || ' and lp.facility = ''' || in_facility || ''' ';
end if;
if rtrim(in_refid) is not null then
  cmdSql := cmdSql || ' and decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')) = ''' || in_refid || ''' ';
end if;
cmdSql := cmdSql || ' group by lp.custid,lp.facility,lp.item,lp.invstatus,' ||
 ' decode(lp.invstatus,''SU'',decode(lp.inventoryclass,''IB'',''LI'', ' ||
 ' ''RG'',''LT'', ' ||
 ' ''FT'',''LC'',''XX''), decode(lp.inventoryclass,''IB'',''IB'', ' ||
 ' ''RG'',''TP'',''FT'',''CB'',''XX'')),'||
 ' lp.inventoryclass, lp.unitofmeasure, lp.lotnumber ';
/*
trace_msg('12', cmdSql);
*/

begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,cit.custid,10);
  /*
  dbms_sql.define_column(curSql,2,cit.lastuser,12);
  */
  dbms_sql.define_column(curSql,2,cit.facility,3);
  dbms_sql.define_column(curSql,3,cit.item,20);
  dbms_sql.define_column(curSql,4,cit.invstatus,2);
  dbms_sql.define_column(curSql,5,cit.inventoryclass,2);
  dbms_sql.define_column(curSql,6,cit.uom,4);
  dbms_sql.define_column(curSql,7,cit.lotnumber,30);
  dbms_sql.define_column(curSql,8,cit.refid,2);
  dbms_sql.define_column(curSql,9,cit.qty);
  cntRows := dbms_sql.execute(curSql);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    if cntRows <= 0 then
      exit;
    end if;
    /*
    trace_msg('I+', cntRows);
    */
    dbms_sql.column_value(curSql,1,cit.custid);
    /*
    dbms_sql.column_value(curSql,2,cit.lastuser);
    */
    dbms_sql.column_value(curSql,2,cit.facility);
    dbms_sql.column_value(curSql,3,cit.item);
    dbms_sql.column_value(curSql,4,cit.invstatus);
    dbms_sql.column_value(curSql,5,cit.inventoryclass);
    dbms_sql.column_value(curSql,6,cit.uom);
    dbms_sql.column_value(curSql,7,cit.lotnumber);
    dbms_sql.column_value(curSql,8,cit.refid);
    dbms_sql.column_value(curSql,9,cit.qty);
    /*
    trace_msg('2', cmdSql);
    */
    begin
      curItm := dbms_sql.open_cursor;
      dbms_sql.parse(curItm, 'insert into i52_item_bal_' || strSuffix ||
        ' values (:custid,:warehouse,:facility,:item,:invstatus,' ||
        ' sysdate, systime, :qty)',
        dbms_sql.native);
      dbms_sql.bind_variable(curItm, ':custid', cit.custid);
      dbms_sql.bind_variable(curItm, ':warehouse', cit.facility);
      dbms_sql.bind_variable(curItm, ':item', cit.item);
      dbms_sql.bind_variable(curItm, ':facility', cit.facility);
      dbms_sql.bind_variable(curItm, ':invstatus', cit.invstatus);
      dbms_sql.bind_variable(curItm, ':inventoryclass', cit.inventoryclass);
      dbms_sql.bind_variable(curItm, ':unitofmeasure', cit.uom);
      dbms_sql.bind_variable(curItm, ':lotnumber', cit.lotnumber);
      dbms_sql.bind_variable(curItm, ':refid', cit.refid);
      dbms_sql.bind_variable(curItm, ':eventdate', cit.eventdate);
      dbms_sql.bind_variable(curItm, ':qty', cit.qty);
      /*
      trace_msg('A+', cit.eventdate );
      */
      cntRows := dbms_sql.execute(curItm);
      /*
      trace_msg('A-', cntRows);
      */
      dbms_sql.close_cursor(curItm);
    exception when others then
      dbms_sql.close_cursor(curItm);
    end;
  end loop;
  dbms_sql.close_cursor(curSql);
exception when others then
  /*
  zut.prt(sqlerrm);
  */
  dbms_sql.close_cursor(curSql);
end;

if upper(in_include_zero_bal_yn) = 'Y' then
  begin
    /*
    trace_msg('3', cmdSql);
    */
    cmdSql := 'insert into i52_item_bal_' || strSuffix ||
    ' select custid,''' || tblWarehouse || ''',item' ||
    ',''AV'',''RG'',0 from custitem  where custid = ''' ||
    rtrim(in_custid) || ''' and status = ''ACTV'' and not exists ' ||
    ' (select * from i52_item_bal_' || strSuffix || ' where custitem.item = ' ||
    'i52_item_bal_' || strSuffix || '.item)';
    /*
    trace_msg('3a', cmdSql);
*/
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
  exception when others then
    /*
    zut.prt(sqlerrm);
    */
    dbms_sql.close_cursor(curFunc);
  end;
end if;

cmdSql := 'create view i52_item_dtl_' || strSuffix ||
 ' (custid,warehouse,facility,item,invstatus,inventoryclass,' ||
 ' unitofmeasure, lotnumber, refid, eventdate, eventtime, qty) as  ' ||
 ' select custid, ' ||
 ' warehouse,facility,item,decode(invstatus,''AV'',''UR'',''SP'',''UR'', ' ||
 ' ''CH'',''QI'',''CR'',''QI'',''EX'',''QI'',''FD'', ' ||
 ' ''QI'',''IN'',''QI'',''OH'',''QI'', ' ||
 ' ''QH'',''QI'',''QA'',''QI'',''QC'',''QI'', ' ||
 ' ''RE'',''QI'',''UN'',''QI'',''US'',''QI'', ' ||
 ' ''DM'',''BL'',''SU'',''BL'',''RD'',''BL'',invstatus),inventoryclass,unitofmeasure,' ||
 ' lotnumber,refid,eventdate,' ||
 ' eventtime, sum(qty) ' ||
 ' from i52_item_bal_' || strSuffix ||
 ' group by custid,warehouse,facility,item, ' ||
 '  decode(invstatus,''AV'',''UR'',''SP'',''UR'', ' ||
 ' ''CH'',''QI'',''CR'',''QI'',''EX'',''QI'',''FD'', ' ||
 ' ''QI'',''IN'',''QI'',''OH'',''QI'', ' ||
 ' ''QH'',''QI'',''QA'',''QI'',''QC'',''QI'', ' ||
 ' ''RE'',''QI'',''UN'',''QI'',''US'',''QI'', ' ||
 ' ''DM'',''BL'',''SU'',''BL'',''RD'',''BL'',invstatus), ' ||
 ' inventoryclass,unitofmeasure,' ||
 ' lotnumber, refid, eventdate, eventtime';
    /*
    trace_msg('3C', cmdSql);
*/
  curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
/*
trace_msg('4', cmdSql);
*/

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbI52 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_I52_extract;

procedure end_I52_extract
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

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') ||
             in_viewsuffix;

cmdSql := 'drop VIEW I52_item_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table I52_item_bal_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeI52 ' || sqlerrm;
  out_errorno := sqlcode;
end end_I52_extract;

-----------------------------------------------------------------------
--  I59 pricessubg
-----------------------------------------------------------------------

procedure begin_I59_extract
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_zero_bal_yn varchar2
,in_include_all_invstatus_yn varchar2
,in_facility varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
curSql integer;
curItm integer;
cmdSqlCompany varchar2(255);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
cit custitemtot%rowtype;
intPickNotShip integer;

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_objects
   where object_name = 'I59_ITEM_BAL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
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

tblWarehouse := 'RG';
cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
  rtrim(in_custid) || ' where code = ''RG'' ';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblWarehouse,12);
  cntRows := dbms_sql.execute(curCompany);
  cntRows := dbms_sql.fetch_rows(curCompany);
  if cntRows > 0 then
    dbms_sql.column_value(curCompany,1,tblWarehouse);
  end if;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

cmdSql := 'create table i59_item_bal_' || strSuffix ||
 ' (custid varchar2(10),warehouse varchar2(12),facility varchar2(3), item varchar2(50), ' ||
 ' invstatus varchar2(2),qty number(16) ' ||
 ') ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);

cmdSql := 'select lp.custid, ' ||
 ' nvl(cw.abbrev,''' || tblWarehouse || '''),lp.facility,lp.item,' ||
 ' lp.invstatus,sum(lp.quantity) ' ||
' from class_to_warehouse_' || rtrim(in_custid) || ' cw, plate lp ' ||
 ' where lp.inventoryclass = cw.code(+) '||
 ' and lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.type = ''PA'' ' ||
 ' and lp.status in (''A'',''M'') ';
if nvl(rtrim(in_include_all_invstatus_yn),'N') != 'Y' then
  cmdSql := cmdSql || ' and lp.invstatus = ''AV'' ';
end if;
if rtrim(in_facility) is not null then
  cmdSql := cmdSql || ' and lp.facility = ''' || in_facility || ''' ';
end if;
cmdSql := cmdSql || ' group by lp.custid,cw.abbrev,lp.facility,lp.item,lp.invstatus ';

begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,cit.custid,10);
  dbms_sql.define_column(curSql,2,cit.lastuser,12);
  dbms_sql.define_column(curSql,3,cit.facility,3);
  dbms_sql.define_column(curSql,4,cit.item,20);
  dbms_sql.define_column(curSql,5,cit.invstatus,2);
  dbms_sql.define_column(curSql,6,cit.qty);
  cntRows := dbms_sql.execute(curSql);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    if cntRows <= 0 then
      exit;
    end if;
    dbms_sql.column_value(curSql,1,cit.custid);
    dbms_sql.column_value(curSql,2,cit.lastuser);
    dbms_sql.column_value(curSql,3,cit.facility);
    dbms_sql.column_value(curSql,4,cit.item);
    dbms_sql.column_value(curSql,5,cit.invstatus);
    dbms_sql.column_value(curSql,6,cit.qty);
    begin
      curItm := dbms_sql.open_cursor;
      dbms_sql.parse(curItm, 'insert into i59_item_bal_' || strSuffix ||
        ' values (:custid,:warehouse,:facility,:item,:invstatus,:qty)',
        dbms_sql.native);
      dbms_sql.bind_variable(curItm, ':custid', cit.custid);
      dbms_sql.bind_variable(curItm, ':warehouse', cit.lastuser);
      dbms_sql.bind_variable(curItm, ':facility', cit.facility);
      dbms_sql.bind_variable(curItm, ':item', cit.item);
      dbms_sql.bind_variable(curItm, ':invstatus', cit.invstatus);
      dbms_sql.bind_variable(curItm, ':qty', cit.qty);
      cntRows := dbms_sql.execute(curItm);
      dbms_sql.close_cursor(curItm);
    exception when others then
      dbms_sql.close_cursor(curItm);
    end;
  end loop;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

cmdSql := 'select lp.custid, ' ||
 ' nvl(cw.abbrev,''' || tblWarehouse || '''),lp.facility,lp.item,lp.invstatus,sum(lp.qty) ' ||
 ' from class_to_warehouse_' || rtrim(in_custid) || ' cw, custitemtotallview lp ' ||
 ' where lp.inventoryclass = cw.code(+) '||
 ' and lp.custid = ''' || rtrim(in_custid) || '''' ||
 ' and lp.status = ''PN'' ';
if nvl(rtrim(in_include_all_invstatus_yn),'N') != 'Y' then
  cmdSql := cmdSql || ' and lp.invstatus = ''AV'' ';
end if;
if rtrim(in_facility) is not null then
  cmdSql := cmdSql || ' and lp.facility = ''' || in_facility || ''' ';
end if;
cmdSql := cmdSql || ' group by lp.custid, nvl(cw.abbrev,''' || tblWarehouse || '''),lp.facility,lp.item,lp.invstatus ';

begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,cit.custid,10);
  dbms_sql.define_column(curSql,2,cit.lastuser,12);
  dbms_sql.define_column(curSql,3,cit.facility,3);
  dbms_sql.define_column(curSql,4,cit.item,20);
  dbms_sql.define_column(curSql,5,cit.invstatus,2);
  dbms_sql.define_column(curSql,6,cit.qty);
  cntRows := dbms_sql.execute(curSql);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    if cntRows <= 0 then
      exit;
    end if;
    dbms_sql.column_value(curSql,1,cit.custid);
    dbms_sql.column_value(curSql,2,cit.lastuser);
    dbms_sql.column_value(curSql,3,cit.facility);
    dbms_sql.column_value(curSql,4,cit.item);
    dbms_sql.column_value(curSql,5,cit.invstatus);
    dbms_sql.column_value(curSql,6,cit.qty);
    begin
      curItm := dbms_sql.open_cursor;
      dbms_sql.parse(curItm, 'insert into i59_item_bal_' || strSuffix ||
        ' values (:custid,:warehouse,:facility,:item,:invstatus,:qty)',
        dbms_sql.native);
      dbms_sql.bind_variable(curItm, ':custid', cit.custid);
      dbms_sql.bind_variable(curItm, ':warehouse', cit.lastuser);
      dbms_sql.bind_variable(curItm, ':item', cit.item);
      dbms_sql.bind_variable(curItm, ':facility', cit.facility);
      dbms_sql.bind_variable(curItm, ':invstatus', cit.invstatus);
      dbms_sql.bind_variable(curItm, ':qty', cit.qty);
      cntRows := dbms_sql.execute(curItm);
      dbms_sql.close_cursor(curItm);
    exception when others then
      dbms_sql.close_cursor(curItm);
    end;
  end loop;
  dbms_sql.close_cursor(curSql);
exception when others then
  zut.prt(sqlerrm);
  dbms_sql.close_cursor(curSql);
end;

if upper(in_include_zero_bal_yn) = 'Y' then
  begin
    cmdSql := 'insert into i59_item_bal_' || strSuffix ||
    ' select custid,''' || tblWarehouse ||''','''||in_facility
    || ''',item' ||
    ',''AV'',0 from custitem  where custid = ''' ||
    rtrim(in_custid) || ''' and status = ''ACTV'' and not exists ' ||
    ' (select * from i59_item_bal_' || strSuffix || ' where custitem.item = ' ||
    'i59_item_bal_' || strSuffix || '.item)';
  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
  exception when others then
    zut.prt(sqlerrm);
    dbms_sql.close_cursor(curFunc);
  end;
end if;

cmdSql := 'create view i59_item_dtl_' || strSuffix ||
 ' (custid,warehouse,facility,item,invstatus,qty) as select custid, ' ||
 ' warehouse,facility,item,invstatus,sum(qty) ' ||
 ' from i59_item_bal_' || strSuffix || ' group by custid,warehouse,facility,item,invstatus ';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbI59 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_I59_extract;

procedure end_I59_extract
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

cmdSql := 'drop VIEW I59_item_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table I59_item_bal_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeI59 ' || sqlerrm;
  out_errorno := sqlcode;
end end_I59_extract;
procedure I15_import_order_header
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ordertype IN varchar2
,in_entrydate IN date
,in_apptdate IN date
,in_shipdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
,in_shippername IN varchar2
,in_shippercontact IN varchar2
,in_shipperaddr1 IN varchar2
,in_shipperaddr2 IN varchar2
,in_shippercity IN varchar2
,in_shipperstate IN varchar2
,in_shipperpostalcode IN varchar2
,in_shippercountrycode IN varchar2
,in_shipperphone IN varchar2
,in_shipperfax IN varchar2
,in_shipperemail IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_shiptocountrycode IN varchar2
,in_shiptophone IN varchar2
,in_shiptofax IN varchar2
,in_shiptoemail IN varchar2
,in_billtoname IN varchar2
,in_billtocontact IN varchar2
,in_billtoaddr1 IN varchar2
,in_billtoaddr2 IN varchar2
,in_billtocity IN varchar2
,in_billtostate IN varchar2
,in_billtopostalcode IN varchar2
,in_billtocountrycode IN varchar2
,in_billtophone IN varchar2
,in_billtofax IN varchar2
,in_billtoemail IN varchar2
,in_deliveryservice IN varchar2
,in_saturdaydelivery IN varchar2
,in_cod IN varchar2
,in_amtcod IN number
,in_specialservice1 IN varchar2
,in_specialservice2 IN varchar2
,in_specialservice3 IN varchar2
,in_specialservice4 IN varchar2
,in_importfileid IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_instructions IN varchar2
,in_bolcomment IN varchar2
,in_replace_cancel IN varchar2
,in_rfautodisplay IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         apptdate,
         nvl(fromfacility, tofacility) facility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(resubmitorder,'N') as resubmitorder,
        unique_order_identifier
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;

cntRows integer;
cntBolRow integer;
dteShipDate date;
dteApptDate date;
dtecancel_after date;
dtedelivery_requested date;
dterequested_ship date;
dteship_not_before date;
dteship_no_later date;
dtecancel_if_not_delivered_by date;
dtedo_not_deliver_after date;
dtedo_not_deliver_before date;
dtehdrpassthrudate01 date;
dtehdrpassthrudate02 date;
dtehdrpassthrudate03 date;
dtehdrpassthrudate04 date;


procedure delete_old_order(in_orderid number, in_shipid number) is
begin
  delete from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
end;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  if nvl(cs.unique_order_identifier,'R') = 'P' then
    out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) 
        ||' PO. '||rtrim(in_po)|| ': ' || out_msg;
  else
    out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) 
        || ': ' || out_msg;
  end if;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, nvl(in_fromfacility,in_tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R','I') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if rtrim(in_func) = 'D' then -- cancel function
  if out_orderid = 0 then
    out_errorno := 3;
    out_msg := 'Order to be cancelled not found';
    order_msg('E');
    return;
  end if;
end if;

begin
  if trunc(in_shipdate) = to_date('12/30/1899','mm/dd/yyyy') then
    dteShipDate := null;
  else
    dteShipDate := in_shipdate;
  end if;
exception when others then
  dteShipDate := null;
end;

begin
  if trunc(in_ApptDate) = to_date('12/30/1899','mm/dd/yyyy') then
    dteApptDate := null;
  else
    dteApptDate := in_ApptDate;
  end if;
exception when others then
  dteApptDate := null;
end;

begin
  if trunc(in_cancel_after) = to_date('12/30/1899','mm/dd/yyyy') then
    dtecancel_after := null;
  else
    dtecancel_after := in_cancel_after;
  end if;
exception when others then
  dtecancel_after := null;
end;

begin
  if trunc(in_delivery_requested) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedelivery_requested := null;
  else
    dtedelivery_requested := in_delivery_requested;
  end if;
exception when others then
  dtedelivery_requested := null;
end;

begin
  if trunc(in_requested_ship) = to_date('12/30/1899','mm/dd/yyyy') then
    dterequested_ship := null;
  else
    dterequested_ship := in_requested_ship;
  end if;
exception when others then
  dterequested_ship := null;
end;

begin
  if trunc(in_ship_not_before) = to_date('12/30/1899','mm/dd/yyyy') then
    dteship_not_before := null;
  else
    dteship_not_before := in_ship_not_before;
  end if;
exception when others then
  dteship_not_before := null;
end;

begin
  if trunc(in_ship_no_later) = to_date('12/30/1899','mm/dd/yyyy') then
    dteship_no_later := null;
  else
    dteship_no_later := in_ship_no_later;
  end if;
exception when others then
  dteship_no_later := null;
end;

begin
  if trunc(in_cancel_if_not_delivered_by) = to_date('12/30/1899','mm/dd/yyyy') then
    dtecancel_if_not_delivered_by := null;
  else
    dtecancel_if_not_delivered_by := in_cancel_if_not_delivered_by;
  end if;
exception when others then
  dtecancel_if_not_delivered_by := null;
end;

begin
  if trunc(in_do_not_deliver_after) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedo_not_deliver_after := null;
  else
    dtedo_not_deliver_after := in_do_not_deliver_after;
  end if;
exception when others then
  dtedo_not_deliver_after := null;
end;

begin
  if trunc(in_do_not_deliver_before) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedo_not_deliver_before := null;
  else
    dtedo_not_deliver_before := in_do_not_deliver_before;
  end if;
exception when others then
  dtedo_not_deliver_before := null;
end;

begin
  if trunc(in_hdrpassthrudate01) = to_date('12/30/1899','mm/dd/yyyy') then
    dtehdrpassthrudate01 := null;
  else
    dtehdrpassthrudate01 := in_hdrpassthrudate01;
  end if;
exception when others then
  dtehdrpassthrudate01 := null;
end;

begin
  if trunc(in_hdrpassthrudate02) = to_date('12/30/1899','mm/dd/yyyy') then
    dtehdrpassthrudate02 := null;
  else
    dtehdrpassthrudate02 := in_hdrpassthrudate02;
  end if;
exception when others then
  dtehdrpassthrudate02 := null;
end;

begin
  if trunc(in_hdrpassthrudate03) = to_date('12/30/1899','mm/dd/yyyy') then
    dtehdrpassthrudate03 := null;
  else
    dtehdrpassthrudate03 := in_hdrpassthrudate03;
  end if;
exception when others then
  dtehdrpassthrudate03 := null;
end;

begin
  if trunc(in_hdrpassthrudate04) = to_date('12/30/1899','mm/dd/yyyy') then
    dtehdrpassthrudate04 := null;
  else
    dtehdrpassthrudate04 := in_hdrpassthrudate04;
  end if;
exception when others then
  dtehdrpassthrudate04 := null;
end;

if rtrim(in_func) = 'A' then
  if out_orderid != 0 then
    open curCustomer;
    fetch curCustomer into cs;
    if curCustomer%notfound then
      cs.resubmitorder := 'N';
    end if;
    close curCustomer;
    if (cs.resubmitorder = 'N') or
       (oh.orderstatus != 'X') then
      out_msg := 'Add request rejected--order already on file';
      order_msg('W');
      return;
    else
      delete_old_order(out_orderid,out_shipid);
      out_msg := 'Resubmit of rejected order';
      order_msg('I');
    end if;
  end if;
end if;

if rtrim(in_func) = 'U' then
  if out_orderid = 0 then
    if rtrim(in_func) = 'U' then
      out_msg := 'Update requested--order not on file--add performed';
      order_msg('W');
    end if;
    in_func := 'A';
  else
    if oh.orderstatus > '1' then
      out_errorno := 2;
      out_msg := 'Invalid Order Status: ' || oh.orderstatus;
      order_msg('E');
      return;
    end if;
  end if;
end if;

if rtrim(in_func) = 'I' then
  if out_orderid = 0 then
    in_func := 'A';
  else
    if oh.orderstatus > '2' then
      out_errorno := 2;
      out_msg := 'Invalid Order Status: ' || oh.orderstatus;
      order_msg('E');
      return;
    end if;
    out_msg := 'OKAY';
    return;
  end if;
end if;

if rtrim(in_func) = 'R' then
  if out_orderid = 0 then
    out_msg := 'Replace requested--order not on file--add performed';
    order_msg('W');
    in_func := 'A';
  else
    if oh.orderstatus > '1'
     and not (nvl(in_replace_cancel, 'N') = 'Y' and oh.orderstatus = 'X')
    then
      out_errorno := 2;
      out_msg := 'Invalid Order Status for replace: ' || oh.orderstatus;
      order_msg('E');
      return;
    end if;
    delete_old_order(out_orderid,out_shipid);
    out_msg := 'Order replace transaction processed';
    order_msg('I');
    if (nvl(in_replace_cancel,'N') = 'Y') and dteApptDate is null then
        dteApptDate := oh.apptdate;
    end if;
  end if;
end if;

if out_orderid = 0 then
  zoe.get_next_orderid(out_orderid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 4;
    order_msg('E');
    return;
  end if;
  out_shipid := 1;
end if;

if rtrim(in_func) in ('A','R') then
  insert into orderhdr
  (orderid,shipid,custid,ordertype,apptdate,shipdate,po,rma,
   fromfacility,tofacility,shipto,billoflading,priority,shipper,
   consignee,shiptype,carrier,reference,shipterms,shippername,shippercontact,
   shipperaddr1,shipperaddr2,shippercity,shipperstate,shipperpostalcode,shippercountrycode,
   shipperphone,shipperfax,shipperemail,shiptoname,shiptocontact,
   shiptoaddr1,shiptoaddr2,shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,
   shiptophone,shiptofax,shiptoemail,billtoname,billtocontact,
   billtoaddr1,billtoaddr2,billtocity,billtostate,
   billtopostalcode,billtocountrycode,
   billtophone,billtofax,billtoemail,lastuser,lastupdate,
   orderstatus,commitstatus,statususer,entrydate,
   hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03, hdrpassthruchar04,
   hdrpassthruchar05, hdrpassthruchar06, hdrpassthruchar07, hdrpassthruchar08,
   hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11, hdrpassthruchar12,
   hdrpassthruchar13, hdrpassthruchar14, hdrpassthruchar15, hdrpassthruchar16,
   hdrpassthruchar17, hdrpassthruchar18, hdrpassthruchar19, hdrpassthruchar20,
   hdrpassthrunum01, hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04,
   hdrpassthrunum05, hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08,
   hdrpassthrunum09, hdrpassthrunum10, importfileid, deliveryservice,
   saturdaydelivery, cod, amtcod,
   specialservice1, specialservice2,
   specialservice3, specialservice4,
   source, comment1,
   cancel_after, delivery_requested, requested_ship,
   ship_not_before, ship_no_later, cancel_if_not_delivered_by,
   do_not_deliver_after, do_not_deliver_before,
   hdrpassthrudate01, hdrpassthrudate02,
   hdrpassthrudate03, hdrpassthrudate04,
   hdrpassthrudoll01, hdrpassthrudoll02,
   rfautodisplay
   )
  values
  (out_orderid,out_shipid,nvl(rtrim(in_custid),' '),nvl(rtrim(in_ordertype),' '),
  dteapptdate,dteshipdate,rtrim(in_po),rtrim(in_rma),rtrim(in_fromfacility),
  rtrim(in_tofacility),rtrim(in_shipto),rtrim(in_billoflading),
  rtrim(in_priority),rtrim(in_shipper),rtrim(in_consignee),rtrim(in_shiptype),
  rtrim(in_carrier),rtrim(in_reference),rtrim(in_shipterms),
  rtrim(in_shippername),rtrim(in_shippercontact),
  rtrim(in_shipperaddr1),rtrim(in_shipperaddr2),rtrim(in_shippercity),
  rtrim(in_shipperstate),rtrim(in_shipperpostalcode),rtrim(in_shippercountrycode),
  rtrim(in_shipperphone),rtrim(in_shipperfax),rtrim(in_shipperemail),
  rtrim(in_shiptoname),rtrim(in_shiptocontact),
  rtrim(in_shiptoaddr1),rtrim(in_shiptoaddr2),rtrim(in_shiptocity),
  rtrim(in_shiptostate),rtrim(in_shiptopostalcode),rtrim(in_shiptocountrycode),
  rtrim(in_shiptophone),rtrim(in_shiptofax),rtrim(in_shiptoemail),
  rtrim(in_billtoname),rtrim(in_billtocontact),rtrim(in_billtoaddr1),rtrim(in_billtoaddr2),
  rtrim(in_billtocity),rtrim(in_billtostate),rtrim(in_billtopostalcode),
  rtrim(in_billtocountrycode),rtrim(in_billtophone),rtrim(in_billtofax),
  rtrim(in_billtoemail),IMP_USERID,sysdate,
  '0','0',IMP_USERID,nvl(in_entrydate,sysdate),
  rtrim(in_hdrpassthruchar01),rtrim(in_hdrpassthruchar02),
  rtrim(in_hdrpassthruchar03),rtrim(in_hdrpassthruchar04),
  rtrim(in_hdrpassthruchar05),rtrim(in_hdrpassthruchar06),
  rtrim(in_hdrpassthruchar07),rtrim(in_hdrpassthruchar08),
  rtrim(in_hdrpassthruchar09),rtrim(in_hdrpassthruchar10),
  rtrim(in_hdrpassthruchar11),rtrim(in_hdrpassthruchar12),
  rtrim(in_hdrpassthruchar13),rtrim(in_hdrpassthruchar14),
  rtrim(in_hdrpassthruchar15),rtrim(in_hdrpassthruchar16),
  rtrim(in_hdrpassthruchar17),rtrim(in_hdrpassthruchar18),
  rtrim(in_hdrpassthruchar19),rtrim(in_hdrpassthruchar20),
  decode(in_hdrpassthrunum01,0,null,in_hdrpassthrunum01),
  decode(in_hdrpassthrunum02,0,null,in_hdrpassthrunum02),
  decode(in_hdrpassthrunum03,0,null,in_hdrpassthrunum03),
  decode(in_hdrpassthrunum04,0,null,in_hdrpassthrunum04),
  decode(in_hdrpassthrunum05,0,null,in_hdrpassthrunum05),
  decode(in_hdrpassthrunum06,0,null,in_hdrpassthrunum06),
  decode(in_hdrpassthrunum07,0,null,in_hdrpassthrunum07),
  decode(in_hdrpassthrunum08,0,null,in_hdrpassthrunum08),
  decode(in_hdrpassthrunum09,0,null,in_hdrpassthrunum09),
  decode(in_hdrpassthrunum10,0,null,in_hdrpassthrunum10),
  upper(rtrim(in_importfileid)),
  rtrim(in_deliveryservice),
  rtrim(in_saturdaydelivery),
  rtrim(in_cod),
  decode(in_amtcod,0,null,in_amtcod),
  rtrim(in_specialservice1),
  rtrim(in_specialservice2),
  rtrim(in_specialservice3),
  rtrim(in_specialservice4),
  'EDI', rtrim(in_instructions),
  dtecancel_after, dtedelivery_requested, dterequested_ship,
  dteship_not_before, dteship_no_later, dtecancel_if_not_delivered_by,
  dtedo_not_deliver_after, dtedo_not_deliver_before,
  dtehdrpassthrudate01, dtehdrpassthrudate02,
  dtehdrpassthrudate03, dtehdrpassthrudate04,
  decode(in_hdrpassthrudoll01,0,null,in_hdrpassthrudoll01),
  decode(in_hdrpassthrudoll02,0,null,in_hdrpassthrudoll02),
  rtrim(in_rfautodisplay)
  );
  if rtrim(in_bolcomment) is not null then
    insert into orderhdrbolcomments
    (orderid,shipid,bolcomment,lastuser,lastupdate)
    values
    (out_orderid,out_shipid,rtrim(in_bolcomment),IMP_USERID,sysdate);
  end if;
elsif rtrim(in_func) = 'U' then
  update orderhdr
     set orderstatus = '0',
         commitstatus = '0',
         entrydate = nvl(in_entrydate,entrydate),
         apptdate = nvl(dteapptdate,apptdate),
         shipdate = nvl(dteshipdate,shipdate),
         shipto = nvl(rtrim(in_shipto),shipto),
         billoflading = nvl(rtrim(in_billoflading),billoflading),
         priority = nvl(rtrim(in_priority),priority),
         shipper = nvl(rtrim(in_shipper),shipper),
         consignee = nvl(rtrim(in_consignee),consignee),
         shiptype = nvl(rtrim(in_shiptype),shiptype),
         carrier = nvl(rtrim(in_carrier),carrier),
         shipterms = nvl(rtrim(in_shipterms),shipterms),
         shippername = nvl(rtrim(in_shippername),shippername),
         shippercontact = nvl(rtrim(in_shippercontact),shippercontact),
         shipperaddr1 = nvl(rtrim(in_shipperaddr1),shipperaddr1),
         shipperaddr2 = nvl(rtrim(in_shipperaddr2),shipperaddr2),
         shippercity = nvl(rtrim(in_shippercity),shippercity),
         shipperstate = nvl(rtrim(in_shipperstate),shipperstate),
         shipperpostalcode = nvl(rtrim(in_shipperpostalcode),shipperpostalcode),
         shippercountrycode = nvl(rtrim(in_shippercountrycode),shippercountrycode),
         shipperphone = nvl(rtrim(in_shipperphone),shipperphone),
         shipperfax = nvl(rtrim(in_shipperfax),shipperfax),
         shipperemail = nvl(rtrim(in_shipperemail),shipperemail),
         shiptoname = nvl(rtrim(in_shiptoname),shiptoname),
         shiptocontact = nvl(rtrim(in_shiptocontact),shiptocontact),
         shiptoaddr1 = nvl(rtrim(in_shiptoaddr1),shiptoaddr1),
         shiptoaddr2 = nvl(rtrim(in_shiptoaddr2),shiptoaddr2),
         shiptocity = nvl(rtrim(in_shiptocity),shiptocity),
         shiptostate = nvl(rtrim(in_shiptostate),shiptostate),
         shiptopostalcode = nvl(rtrim(in_shiptopostalcode),shiptopostalcode),
         shiptocountrycode = nvl(rtrim(in_shiptocountrycode),shiptocountrycode),
         shiptophone = nvl(rtrim(in_shiptophone),shiptophone),
         shiptofax = nvl(rtrim(in_shiptofax),shiptofax),
         shiptoemail = nvl(rtrim(in_shiptoemail),shiptoemail),
         billtoname = nvl(rtrim(in_billtoname),billtoname),
         billtocontact = nvl(rtrim(in_billtocontact),billtocontact),
         billtoaddr1 = nvl(rtrim(in_billtoaddr1),billtoaddr1),
         billtoaddr2 = nvl(rtrim(in_billtoaddr2),billtoaddr2),
         billtocity = nvl(rtrim(in_billtocity),billtocity),
         billtostate = nvl(rtrim(in_billtostate),billtostate),
         billtopostalcode = nvl(rtrim(in_billtopostalcode),billtopostalcode),
         billtocountrycode = nvl(rtrim(in_billtocountrycode),billtocountrycode),
         billtophone = nvl(rtrim(in_billtophone),billtophone),
         billtofax = nvl(rtrim(in_billtofax),billtofax),
         billtoemail = nvl(rtrim(in_billtoemail),billtoemail),
         deliveryservice = nvl(rtrim(in_deliveryservice),deliveryservice),
         saturdaydelivery = nvl(rtrim(in_saturdaydelivery),saturdaydelivery),
         cod = nvl(rtrim(in_cod),cod),
         amtcod = nvl(decode(in_amtcod,0,null,in_amtcod),amtcod),
         specialservice1 = nvl(rtrim(in_specialservice1),specialservice1),
         specialservice2 = nvl(rtrim(in_specialservice2),specialservice2),
         specialservice3 = nvl(rtrim(in_specialservice3),specialservice3),
         specialservice4 = nvl(rtrim(in_specialservice4),specialservice4),
         lastuser = IMP_USERID,
         lastupdate = sysdate,
         hdrpassthruchar01 = nvl(rtrim(in_hdrpassthruchar01),hdrpassthruchar01),
         hdrpassthruchar02 = nvl(rtrim(in_hdrpassthruchar02),hdrpassthruchar02),
         hdrpassthruchar03 = nvl(rtrim(in_hdrpassthruchar03),hdrpassthruchar03),
         hdrpassthruchar04 = nvl(rtrim(in_hdrpassthruchar04),hdrpassthruchar04),
         hdrpassthruchar05 = nvl(rtrim(in_hdrpassthruchar05),hdrpassthruchar05),
         hdrpassthruchar06 = nvl(rtrim(in_hdrpassthruchar06),hdrpassthruchar06),
         hdrpassthruchar07 = nvl(rtrim(in_hdrpassthruchar07),hdrpassthruchar07),
         hdrpassthruchar08 = nvl(rtrim(in_hdrpassthruchar08),hdrpassthruchar08),
         hdrpassthruchar09 = nvl(rtrim(in_hdrpassthruchar09),hdrpassthruchar09),
         hdrpassthruchar10 = nvl(rtrim(in_hdrpassthruchar10),hdrpassthruchar10),
         hdrpassthruchar11 = nvl(rtrim(in_hdrpassthruchar11),hdrpassthruchar11),
         hdrpassthruchar12 = nvl(rtrim(in_hdrpassthruchar12),hdrpassthruchar12),
         hdrpassthruchar13 = nvl(rtrim(in_hdrpassthruchar13),hdrpassthruchar13),
         hdrpassthruchar14 = nvl(rtrim(in_hdrpassthruchar14),hdrpassthruchar14),
         hdrpassthruchar15 = nvl(rtrim(in_hdrpassthruchar15),hdrpassthruchar15),
         hdrpassthruchar16 = nvl(rtrim(in_hdrpassthruchar16),hdrpassthruchar16),
         hdrpassthruchar17 = nvl(rtrim(in_hdrpassthruchar17),hdrpassthruchar17),
         hdrpassthruchar18 = nvl(rtrim(in_hdrpassthruchar18),hdrpassthruchar18),
         hdrpassthruchar19 = nvl(rtrim(in_hdrpassthruchar19),hdrpassthruchar19),
         hdrpassthruchar20 = nvl(rtrim(in_hdrpassthruchar20),hdrpassthruchar20),
         hdrpassthrunum01 = nvl(decode(in_hdrpassthrunum01,0,null,in_hdrpassthrunum01),hdrpassthrunum01),
         hdrpassthrunum02 = nvl(decode(in_hdrpassthrunum02,0,null,in_hdrpassthrunum02),hdrpassthrunum02),
         hdrpassthrunum03 = nvl(decode(in_hdrpassthrunum03,0,null,in_hdrpassthrunum03),hdrpassthrunum03),
         hdrpassthrunum04 = nvl(decode(in_hdrpassthrunum04,0,null,in_hdrpassthrunum04),hdrpassthrunum04),
         hdrpassthrunum05 = nvl(decode(in_hdrpassthrunum05,0,null,in_hdrpassthrunum05),hdrpassthrunum05),
         hdrpassthrunum06 = nvl(decode(in_hdrpassthrunum06,0,null,in_hdrpassthrunum06),hdrpassthrunum06),
         hdrpassthrunum07 = nvl(decode(in_hdrpassthrunum07,0,null,in_hdrpassthrunum07),hdrpassthrunum07),
         hdrpassthrunum08 = nvl(decode(in_hdrpassthrunum08,0,null,in_hdrpassthrunum08),hdrpassthrunum08),
         hdrpassthrunum09 = nvl(decode(in_hdrpassthrunum09,0,null,in_hdrpassthrunum09),hdrpassthrunum09),
         hdrpassthrunum10 = nvl(decode(in_hdrpassthrunum10,0,null,in_hdrpassthrunum10),hdrpassthrunum10),
         cancel_after = nvl(dtecancel_after,cancel_after),
         delivery_requested = nvl(dtedelivery_requested,delivery_requested),
         requested_ship = nvl(dterequested_ship,requested_ship),
         ship_not_before = nvl(dteship_not_before,ship_not_before),
         ship_no_later = nvl(dteship_no_later,ship_no_later),
         cancel_if_not_delivered_by = nvl(dtecancel_if_not_delivered_by,cancel_if_not_delivered_by),
         do_not_deliver_after = nvl(dtedo_not_deliver_after,do_not_deliver_after),
         do_not_deliver_before = nvl(dtedo_not_deliver_before,do_not_deliver_before),
         hdrpassthrudate01 = nvl(dtehdrpassthrudate01,hdrpassthrudate01),
         hdrpassthrudate02 = nvl(dtehdrpassthrudate02,hdrpassthrudate02),
         hdrpassthrudate03 = nvl(dtehdrpassthrudate03,hdrpassthrudate03),
         hdrpassthrudate04 = nvl(dtehdrpassthrudate04,hdrpassthrudate04),
         hdrpassthrudoll01 = nvl(decode(in_hdrpassthrudoll01,0,null,in_hdrpassthrudoll01),hdrpassthrudoll01),
         hdrpassthrudoll02 = nvl(decode(in_hdrpassthrudoll02,0,null,in_hdrpassthrudoll02),hdrpassthrudoll02),
         importfileid = nvl(upper(rtrim(in_importfileid)),importfileid),
         rfautodisplay = nvl(rtrim(in_rfautodisplay),rfautodisplay)
   where orderid = out_orderid
     and shipid = out_shipid;
  if rtrim(in_instructions) is not null then
    update orderhdr
       set comment1 = in_instructions
     where orderid = out_orderid
       and shipid = out_shipid;
  end if;
  if rtrim(in_bolcomment) is not null then
    update orderhdrbolcomments
       set bolcomment = rtrim(in_bolcomment),
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid;
  end if;
elsif rtrim(in_func) = 'D' then
   zoe.cancel_order_request(out_orderid, out_shipid, oh.facility,
       'EDI',IMP_USERID, out_msg);
end if;
/*
out_msg := 'reached end-of-proc';
order_msg('I');
*/
out_msg := 'OKAY';

exception when others then
  out_msg := 'zioh ' || sqlerrm;
  out_errorno := sqlcode;
end I15_import_order_header;

procedure I15_import_order_line
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_instructions IN varchar2
,in_bolcomment IN varchar2
,in_rfautodisplay IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = rtrim(in_custid);
cs curCustomer%rowtype;

cursor curOrderDtl is
  select linestatus,
         itementered,
         uomentered,
         item,
         qtyentered,
         qtyorder,
         lotnumber,
         dtlpassthruchar01,
         dtlpassthruchar02,
         dtlpassthruchar03,
         dtlpassthruchar04,
         dtlpassthruchar05,
         dtlpassthruchar06,
         dtlpassthruchar07,
         dtlpassthruchar08,
         dtlpassthruchar09,
         dtlpassthruchar10,
         dtlpassthruchar11,
         dtlpassthruchar12,
         dtlpassthruchar13,
         dtlpassthruchar14,
         dtlpassthruchar15,
         dtlpassthruchar16,
         dtlpassthruchar17,
         dtlpassthruchar18,
         dtlpassthruchar19,
         dtlpassthruchar20,
         dtlpassthrunum01,
         dtlpassthrunum02,
         dtlpassthrunum03,
         dtlpassthrunum04,
         dtlpassthrunum05,
         dtlpassthrunum06,
         dtlpassthrunum07,
         dtlpassthrunum08,
         dtlpassthrunum09,
         dtlpassthrunum10,
         dtlpassthrudate01,
         dtlpassthrudate02,
         dtlpassthrudate03,
         dtlpassthrudate04,
         dtlpassthrudoll01,
         dtlpassthrudoll02
    from orderdtl
   where orderid = out_orderid
     and shipid = out_shipid
     and itementered = rtrim(in_itementered)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
od curOrderDtl%rowtype;

cursor curOrderDtlLineCount(in_item varchar2) is
  select count(1) as count
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = rtrim(in_item)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
     and nvl(xdock,'N') = 'N';
olc curOrderDtlLineCount%rowtype;

cursor curOrderDtlLine(in_linenumber number) is
  select item,
         lotnumber,
         qty,
         qtyentered
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and linenumber = in_linenumber;
ol curOrderDtlLine%rowtype;

cursor curCustItem(in_item varchar2) is
  select useramt1,
         backorder,
         allowsub,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtytype,
         baseuom
    from custitemview
   where custid = rtrim(in_custid)
     and item = rtrim(in_item);
ci curCustItem%rowtype;

chk orderdtlline%rowtype;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;
dtedtlpassthrudate01 date;
dtedtlpassthrudate02 date;
dtedtlpassthrudate03 date;
dtedtlpassthrudate04 date;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R','I') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  item_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  item_msg('E');
  return;
end if;

if rtrim(in_func) = 'I' then
  if oh.orderstatus > '2' then
    out_errorno := 2;
    out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
    item_msg('E');
    return;
  end if;
elsif oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  item_msg('E');
  return;
end if;

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.linenumbersyn := 'N';
end if;
close curCustomer;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%found then
  chk.item := od.item;
  chk.lotnumber := od.lotnumber;
else
  chk.item := null;
  chk.lotnumber := null;
end if;
close curOrderDtl;

if rtrim(in_func) = 'D' then -- cancel function
  if chk.item is null then
    out_errorno := 3;
    out_msg := 'Order-line to be cancelled not found';
    item_msg('E');
    return;
  end if;
  if od.linestatus = 'X' then
    out_errorno := 4;
    out_msg := 'Order-line already cancelled';
    item_msg('E');
    return;
  end if;
end if;

zci.get_customer_item(rtrim(in_custid),rtrim(in_itementered),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := in_itementered;
end if;

olc.count := 0;

if cs.linenumbersyn = 'Y' then
  if nvl(in_dtlpassthrunum10,0) <= 0 then
    out_errorno := 5;
    out_msg := 'Invalid Line Number: ' || in_dtlpassthrunum10;
    item_msg('E');
    return;
  end if;
  open curOrderDtlLineCount(strItem);
  fetch curOrderDtlLineCount into olc;
  if curOrderDtlLineCount%notfound then
    olc.count := 0;
  end if;
  close curOrderDtlLineCount;
  chk.linenumber := null;
  if olc.count != 0 then
    open curOrderDtlLine(in_dtlpassthrunum10);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      if (ol.item != strItem) or
         (nvl(ol.lotnumber,'(none)') != nvl(rtrim(in_lotnumber),'(none)')) then
        out_errorno := 6;
        out_msg := 'Line Number Mismatch: ' || in_dtlpassthrunum10;
        item_msg('E');
        return;
      else
        chk.linenumber := in_dtlpassthrunum10;
      end if;
    end if;
    close curOrderDtlLine;
  else
    if od.dtlpassthrunum10 = in_dtlpassthrunum10 then
      chk.linenumber := od.dtlpassthrunum10;
    end if;
  end if;
end if;

if rtrim(in_func) in ('A','R','I') then
  if ( (cs.linenumbersyn != 'Y') and (chk.item is not null) ) or
     ( (cs.linenumbersyn = 'Y') and (chk.linenumber is not null) ) then
    out_msg := 'Add requested--order-line already on file--update performed';
    item_msg('W');
    in_func := 'U';
  end if;
elsif rtrim(in_func) = 'U' then
  if ( (cs.linenumbersyn != 'Y') and (chk.item is null) ) or
     ( (cs.linenumbersyn = 'Y') and (chk.linenumber is null) ) then
    out_msg := 'Update requested--order-line not on file--add performed';
    item_msg('W');
    in_func := 'A';
  end if;
end if;

begin
  if trunc(in_dtlpassthrudate01) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedtlpassthrudate01 := null;
  else
    dtedtlpassthrudate01 := in_dtlpassthrudate01;
  end if;
exception when others then
  dtedtlpassthrudate01 := null;
end;

begin
  if trunc(in_dtlpassthrudate02) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedtlpassthrudate02 := null;
  else
    dtedtlpassthrudate02 := in_dtlpassthrudate02;
  end if;
exception when others then
  dtedtlpassthrudate02 := null;
end;

begin
  if trunc(in_dtlpassthrudate03) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedtlpassthrudate03 := null;
  else
    dtedtlpassthrudate03 := in_dtlpassthrudate03;
  end if;
exception when others then
  dtedtlpassthrudate03 := null;
end;

begin
  if trunc(in_dtlpassthrudate04) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedtlpassthrudate04 := null;
  else
    dtedtlpassthrudate04 := in_dtlpassthrudate04;
  end if;
exception when others then
  dtedtlpassthrudate04 := null;
end;

open curCustItem(strItem);
fetch curCustItem into ci;
if curCustItem%notfound then
  ci.useramt1 := 0;
end if;
close curCustItem;
if oh.ordertype in ('R','Q','P','A','C','I') then
  ci.invstatus := null;
  ci.inventoryclass := null;
end if;

zoe.get_base_uom_equivalent(rtrim(in_custid),rtrim(in_itementered),
  nvl(rtrim(in_uomentered),ci.baseuom),
  in_qtyentered,strItem,strUOMBase,qtyBase,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := rtrim(in_itementered);
  strUOMBase :=  nvl(rtrim(in_uomentered),ci.baseuom);
  qtyBase := in_qtyentered;
end if;

if rtrim(in_func) in ('A','R','I') then
  if chk.item is null then
    insert into orderdtl
    (orderid,shipid,item,lotnumber,uom,linestatus,qtyentered,itementered,uomentered,
    qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,
    backorder,allowsub,qtytype,invstatusind,invstatus,invclassind,
    inventoryclass,consigneesku,statususer,
    dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
    dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
    dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
    dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
    dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
    dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
    dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
    dtlpassthrunum09, dtlpassthrunum10, comment1,
    dtlpassthrudate01, dtlpassthrudate02,
    dtlpassthrudate03, dtlpassthrudate04,
    dtlpassthrudoll01, dtlpassthrudoll02,
    rfautodisplay
    )
    values
    (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),strUOMBase,'A',
     in_qtyentered,rtrim(in_itementered), nvl(rtrim(in_uomentered),ci.baseuom),
     qtyBase,
     zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
     zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
     qtyBase*ci.useramt1,IMP_USERID,sysdate,
     nvl(rtrim(in_backorder),ci.backorder),nvl(rtrim(in_allowsub),ci.allowsub),
     nvl(rtrim(in_qtytype),ci.qtytype),nvl(rtrim(in_invstatusind),ci.invstatusind),
     nvl(rtrim(in_invstatus),ci.invstatus),nvl(rtrim(in_invclassind),ci.invclassind),
     nvl(rtrim(in_inventoryclass),ci.inventoryclass),rtrim(in_consigneesku),
     IMP_USERID,
     rtrim(in_dtlpassthruchar01),rtrim(in_dtlpassthruchar02),
     rtrim(in_dtlpassthruchar03),rtrim(in_dtlpassthruchar04),
     rtrim(in_dtlpassthruchar05),rtrim(in_dtlpassthruchar06),
     rtrim(in_dtlpassthruchar07),rtrim(in_dtlpassthruchar08),
     rtrim(in_dtlpassthruchar09),rtrim(in_dtlpassthruchar10),
     rtrim(in_dtlpassthruchar11),rtrim(in_dtlpassthruchar12),
     rtrim(in_dtlpassthruchar13),rtrim(in_dtlpassthruchar14),
     rtrim(in_dtlpassthruchar15),rtrim(in_dtlpassthruchar16),
     rtrim(in_dtlpassthruchar17),rtrim(in_dtlpassthruchar18),
     rtrim(in_dtlpassthruchar19),rtrim(in_dtlpassthruchar20),
     decode(in_dtlpassthrunum01,0,null,in_dtlpassthrunum01),
     decode(in_dtlpassthrunum02,0,null,in_dtlpassthrunum02),
     decode(in_dtlpassthrunum03,0,null,in_dtlpassthrunum03),
     decode(in_dtlpassthrunum04,0,null,in_dtlpassthrunum04),
     decode(in_dtlpassthrunum05,0,null,in_dtlpassthrunum05),
     decode(in_dtlpassthrunum06,0,null,in_dtlpassthrunum06),
     decode(in_dtlpassthrunum07,0,null,in_dtlpassthrunum07),
     decode(in_dtlpassthrunum08,0,null,in_dtlpassthrunum08),
     decode(in_dtlpassthrunum09,0,null,in_dtlpassthrunum09),
     decode(in_dtlpassthrunum10,0,null,in_dtlpassthrunum10),
     rtrim(in_instructions),
     dtedtlpassthrudate01, dtedtlpassthrudate02,
     dtedtlpassthrudate03, dtedtlpassthrudate04,
     decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
     decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
     rtrim(in_rfautodisplay)
     );
	 
	   -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
	   -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
	   update orderdtl
	   set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
	   where orderid = out_orderid
		 and shipid = out_shipid
		 and item = nvl(strItem,' ')
		 and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
	 
    if rtrim(in_bolcomment) is not null then
      insert into orderdtlbolcomments
      (orderid,shipid,item,lotnumber,bolcomment,lastuser,lastupdate)
      values
      (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
       rtrim(in_bolcomment),IMP_USERID,sysdate);
    end if;
  else
    if olc.count = 0 then --add line record for item info that is already on file
      insert into orderdtlline
       (orderid,shipid,item,lotnumber,
        linenumber,qty,
        dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
        dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
        dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
        dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
        dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
        dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
        dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
        dtlpassthrunum09, dtlpassthrunum10, lastuser, lastupdate,
        dtlpassthrudate01, dtlpassthrudate02, dtlpassthrudate03, dtlpassthrudate04,
        dtlpassthrudoll01, dtlpassthrudoll02, uomentered, qtyentered
       )
       values
       (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
        od.dtlpassthrunum10,od.qtyorder,
        od.dtlpassthruchar01, od.dtlpassthruchar02, od.dtlpassthruchar03, od.dtlpassthruchar04,
        od.dtlpassthruchar05, od.dtlpassthruchar06, od.dtlpassthruchar07, od.dtlpassthruchar08,
        od.dtlpassthruchar09, od.dtlpassthruchar10, od.dtlpassthruchar11, od.dtlpassthruchar12,
        od.dtlpassthruchar13, od.dtlpassthruchar14, od.dtlpassthruchar15, od.dtlpassthruchar16,
        od.dtlpassthruchar17, od.dtlpassthruchar18, od.dtlpassthruchar19, od.dtlpassthruchar20,
        od.dtlpassthrunum01, od.dtlpassthrunum02, od.dtlpassthrunum03, od.dtlpassthrunum04,
        od.dtlpassthrunum05, od.dtlpassthrunum06, od.dtlpassthrunum07, od.dtlpassthrunum08,
        od.dtlpassthrunum09, od.dtlpassthrunum10, IMP_USERID, sysdate,
        od.dtlpassthrudate01, od.dtlpassthrudate02, od.dtlpassthrudate03, od.dtlpassthrudate04,
        od.dtlpassthrudoll01, od.dtlpassthrudoll02, od.uomentered, od.qtyentered
       );
    end if;
    insert into orderdtlline
     (orderid,shipid,item,lotnumber,
      linenumber,qty,
      dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
      dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
      dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
      dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
      dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
      dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
      dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
      dtlpassthrunum09, dtlpassthrunum10, lastuser, lastupdate,
      dtlpassthrudate01, dtlpassthrudate02, dtlpassthrudate03, dtlpassthrudate04,
      dtlpassthrudoll01, dtlpassthrudoll02, uomentered, qtyentered
     )
     values
     (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
      in_dtlpassthrunum10,qtyBase,
      decode(nvl(od.dtlpassthruchar01,'x'),nvl(rtrim(in_dtlpassthruchar01),'x'),
        od.dtlpassthruchar01,nvl(rtrim(in_dtlpassthruchar01),' ')),
      decode(nvl(od.dtlpassthruchar02,'x'),nvl(rtrim(in_dtlpassthruchar02),'x'),
        od.dtlpassthruchar02,nvl(rtrim(in_dtlpassthruchar02),' ')),
      decode(nvl(od.dtlpassthruchar03,'x'),nvl(rtrim(in_dtlpassthruchar03),'x'),
        od.dtlpassthruchar03,nvl(rtrim(in_dtlpassthruchar03),' ')),
      decode(nvl(od.dtlpassthruchar04,'x'),nvl(rtrim(in_dtlpassthruchar04),'x'),
        od.dtlpassthruchar04,nvl(rtrim(in_dtlpassthruchar04),' ')),
      decode(nvl(od.dtlpassthruchar05,'x'),nvl(rtrim(in_dtlpassthruchar05),'x'),
        od.dtlpassthruchar05,nvl(rtrim(in_dtlpassthruchar05),' ')),
      decode(nvl(od.dtlpassthruchar06,'x'),nvl(rtrim(in_dtlpassthruchar06),'x'),
        od.dtlpassthruchar06,nvl(rtrim(in_dtlpassthruchar06),' ')),
      decode(nvl(od.dtlpassthruchar07,'x'),nvl(rtrim(in_dtlpassthruchar07),'x'),
        od.dtlpassthruchar07,nvl(rtrim(in_dtlpassthruchar07),' ')),
      decode(nvl(od.dtlpassthruchar08,'x'),nvl(rtrim(in_dtlpassthruchar08),'x'),
        od.dtlpassthruchar08,nvl(rtrim(in_dtlpassthruchar08),' ')),
      decode(nvl(od.dtlpassthruchar09,'x'),nvl(rtrim(in_dtlpassthruchar09),'x'),
        od.dtlpassthruchar09,nvl(rtrim(in_dtlpassthruchar09),' ')),
      decode(nvl(od.dtlpassthruchar10,'x'),nvl(rtrim(in_dtlpassthruchar10),'x'),
        od.dtlpassthruchar10,nvl(rtrim(in_dtlpassthruchar10),' ')),
      decode(nvl(od.dtlpassthruchar11,'x'),nvl(rtrim(in_dtlpassthruchar11),'x'),
        od.dtlpassthruchar11,nvl(rtrim(in_dtlpassthruchar11),' ')),
      decode(nvl(od.dtlpassthruchar12,'x'),nvl(rtrim(in_dtlpassthruchar12),'x'),
        od.dtlpassthruchar12,nvl(rtrim(in_dtlpassthruchar12),' ')),
      decode(nvl(od.dtlpassthruchar13,'x'),nvl(rtrim(in_dtlpassthruchar13),'x'),
        od.dtlpassthruchar13,nvl(rtrim(in_dtlpassthruchar13),' ')),
      decode(nvl(od.dtlpassthruchar14,'x'),nvl(rtrim(in_dtlpassthruchar14),'x'),
        od.dtlpassthruchar14,nvl(rtrim(in_dtlpassthruchar14),' ')),
      decode(nvl(od.dtlpassthruchar15,'x'),nvl(rtrim(in_dtlpassthruchar15),'x'),
        od.dtlpassthruchar15,nvl(rtrim(in_dtlpassthruchar15),' ')),
      decode(nvl(od.dtlpassthruchar16,'x'),nvl(rtrim(in_dtlpassthruchar16),'x'),
        od.dtlpassthruchar16,nvl(rtrim(in_dtlpassthruchar16),' ')),
      decode(nvl(od.dtlpassthruchar17,'x'),nvl(rtrim(in_dtlpassthruchar17),'x'),
        od.dtlpassthruchar17,nvl(rtrim(in_dtlpassthruchar17),' ')),
      decode(nvl(od.dtlpassthruchar18,'x'),nvl(rtrim(in_dtlpassthruchar18),'x'),
        od.dtlpassthruchar18,nvl(rtrim(in_dtlpassthruchar18),' ')),
      decode(nvl(od.dtlpassthruchar19,'x'),nvl(rtrim(in_dtlpassthruchar19),'x'),
        od.dtlpassthruchar19,nvl(rtrim(in_dtlpassthruchar19),' ')),
      decode(nvl(od.dtlpassthruchar20,'x'),nvl(rtrim(in_dtlpassthruchar20),'x'),
        od.dtlpassthruchar20,nvl(rtrim(in_dtlpassthruchar20),' ')),
      decode(nvl(od.dtlpassthrunum01,0),nvl(in_dtlpassthrunum01,0),
        od.dtlpassthrunum01,nvl(in_dtlpassthrunum01,0)),
      decode(nvl(od.dtlpassthrunum02,0),nvl(in_dtlpassthrunum02,0),
        od.dtlpassthrunum02,nvl(in_dtlpassthrunum02,0)),
      decode(nvl(od.dtlpassthrunum03,0),nvl(in_dtlpassthrunum03,0),
        od.dtlpassthrunum03,nvl(in_dtlpassthrunum03,0)),
      decode(nvl(od.dtlpassthrunum04,0),nvl(in_dtlpassthrunum04,0),
        od.dtlpassthrunum04,nvl(in_dtlpassthrunum04,0)),
      decode(nvl(od.dtlpassthrunum05,0),nvl(in_dtlpassthrunum05,0),
        od.dtlpassthrunum05,nvl(in_dtlpassthrunum05,0)),
      decode(nvl(od.dtlpassthrunum06,0),nvl(in_dtlpassthrunum06,0),
        od.dtlpassthrunum06,nvl(in_dtlpassthrunum06,0)),
      decode(nvl(od.dtlpassthrunum07,0),nvl(in_dtlpassthrunum07,0),
        od.dtlpassthrunum07,nvl(in_dtlpassthrunum07,0)),
      decode(nvl(od.dtlpassthrunum08,0),nvl(in_dtlpassthrunum08,0),
        od.dtlpassthrunum08,nvl(in_dtlpassthrunum08,0)),
      decode(nvl(od.dtlpassthrunum09,0),nvl(in_dtlpassthrunum09,0),
        od.dtlpassthrunum09,nvl(in_dtlpassthrunum09,0)),
      decode(nvl(od.dtlpassthrunum10,0),nvl(in_dtlpassthrunum10,0),
        od.dtlpassthrunum10,nvl(in_dtlpassthrunum10,0)),
      IMP_USERID, sysdate,
      dtedtlpassthrudate01, dtedtlpassthrudate02,
      dtedtlpassthrudate03, dtedtlpassthrudate04,
      decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
      decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
      nvl(rtrim(in_uomentered),ci.baseuom),
      in_qtyentered
     );
    if nvl(rtrim(in_uomentered),ci.baseuom) != od.uomentered then
      update orderdtl
         set qtyentered = qtyorder + qtyBase,
             uomentered = ci.baseuom,
             qtyorder = qtyorder + qtyBase,
             weightorder = weightorder
               + zci.item_weight(rtrim(in_custid),strItem,ci.baseuom) * qtyBase,
             cubeorder = cubeorder
               + zci.item_cube(rtrim(in_custid),strItem,ci.Baseuom) * qtyBase,
             amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)), --prn 25133
             lastuser = IMP_USERID,
             lastupdate = sysdate
       where orderid = out_orderid
         and shipid = out_shipid
         and item = strItem
         and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
    else
      update orderdtl
         set qtyentered = qtyentered + in_qtyentered,
             qtyorder = qtyorder + qtyBase,
             weightorder = weightorder
               + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
             cubeorder = cubeorder
               + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
             amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)), --prn 25133
             lastuser = IMP_USERID,
             lastupdate = sysdate
       where orderid = out_orderid
         and shipid = out_shipid
         and item = strItem
         and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
    end if;
  end if;
elsif rtrim(in_func) = 'U' then
  if (olc.count != 0) and
     (chk.linenumber is not null) then
    update orderdtlline
       set qty = qtyBase,
           qtyentered = in_qtyentered,
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
       and linenumber = chk.linenumber;
    update orderdtl
       set qtyentered = qtyentered + in_qtyentered - ol.qty,
           qtyorder = qtyorder + qtyBase - ol.qty,
           weightorder = weightorder
             + (zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered)
             - (zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * ol.qty),
           cubeorder = cubeorder
             + (zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered)
             - (zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * ol.qty),
           amtorder = amtorder + (qtyBase - ol.qty) * zci.item_amt(custid,orderid,shipid,item,lotnumber), --prn 25133
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  else
    update orderdtl
       set uomentered = nvl(rtrim(in_uomentered),ci.baseuom),
           qtyentered = in_qtyentered,
           uom = strUOMBase,
           qtyorder = qtyBase,
           weightorder = zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
           cubeorder = zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
           amtorder = qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber), --prn 25133
           backorder = nvl(rtrim(in_backorder),backorder),
           allowsub = nvl(rtrim(in_allowsub),allowsub),
           qtytype = nvl(rtrim(in_qtytype),qtytype),
           invstatusind = nvl(rtrim(in_invstatusind),invstatusind),
           invstatus = nvl(rtrim(in_invstatus),invstatus),
           invclassind = nvl(rtrim(in_invclassind),invclassind),
           inventoryclass = nvl(rtrim(in_inventoryclass),inventoryclass),
           consigneesku = nvl(rtrim(in_consigneesku),consigneesku),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           dtlpassthruchar01 = nvl(rtrim(in_dtlpassthruchar01),dtlpassthruchar01),
           dtlpassthruchar02 = nvl(rtrim(in_dtlpassthruchar02),dtlpassthruchar02),
           dtlpassthruchar03 = nvl(rtrim(in_dtlpassthruchar03),dtlpassthruchar03),
           dtlpassthruchar04 = nvl(rtrim(in_dtlpassthruchar04),dtlpassthruchar04),
           dtlpassthruchar05 = nvl(rtrim(in_dtlpassthruchar05),dtlpassthruchar05),
           dtlpassthruchar06 = nvl(rtrim(in_dtlpassthruchar06),dtlpassthruchar06),
           dtlpassthruchar07 = nvl(rtrim(in_dtlpassthruchar07),dtlpassthruchar07),
           dtlpassthruchar08 = nvl(rtrim(in_dtlpassthruchar08),dtlpassthruchar08),
           dtlpassthruchar09 = nvl(rtrim(in_dtlpassthruchar09),dtlpassthruchar09),
           dtlpassthruchar10 = nvl(rtrim(in_dtlpassthruchar10),dtlpassthruchar10),
           dtlpassthruchar11 = nvl(rtrim(in_dtlpassthruchar11),dtlpassthruchar11),
           dtlpassthruchar12 = nvl(rtrim(in_dtlpassthruchar12),dtlpassthruchar12),
           dtlpassthruchar13 = nvl(rtrim(in_dtlpassthruchar13),dtlpassthruchar13),
           dtlpassthruchar14 = nvl(rtrim(in_dtlpassthruchar14),dtlpassthruchar14),
           dtlpassthruchar15 = nvl(rtrim(in_dtlpassthruchar15),dtlpassthruchar15),
           dtlpassthruchar16 = nvl(rtrim(in_dtlpassthruchar16),dtlpassthruchar16),
           dtlpassthruchar17 = nvl(rtrim(in_dtlpassthruchar17),dtlpassthruchar17),
           dtlpassthruchar18 = nvl(rtrim(in_dtlpassthruchar18),dtlpassthruchar18),
           dtlpassthruchar19 = nvl(rtrim(in_dtlpassthruchar19),dtlpassthruchar19),
           dtlpassthruchar20 = nvl(rtrim(in_dtlpassthruchar20),dtlpassthruchar20),
           dtlpassthrunum01 = nvl(decode(in_dtlpassthrunum01,0,null,in_dtlpassthrunum01),dtlpassthrunum01),
           dtlpassthrunum02 = nvl(decode(in_dtlpassthrunum02,0,null,in_dtlpassthrunum02),dtlpassthrunum02),
           dtlpassthrunum03 = nvl(decode(in_dtlpassthrunum03,0,null,in_dtlpassthrunum03),dtlpassthrunum03),
           dtlpassthrunum04 = nvl(decode(in_dtlpassthrunum04,0,null,in_dtlpassthrunum04),dtlpassthrunum04),
           dtlpassthrunum05 = nvl(decode(in_dtlpassthrunum05,0,null,in_dtlpassthrunum05),dtlpassthrunum05),
           dtlpassthrunum06 = nvl(decode(in_dtlpassthrunum06,0,null,in_dtlpassthrunum06),dtlpassthrunum06),
           dtlpassthrunum07 = nvl(decode(in_dtlpassthrunum07,0,null,in_dtlpassthrunum07),dtlpassthrunum07),
           dtlpassthrunum08 = nvl(decode(in_dtlpassthrunum08,0,null,in_dtlpassthrunum08),dtlpassthrunum08),
           dtlpassthrunum09 = nvl(decode(in_dtlpassthrunum09,0,null,in_dtlpassthrunum09),dtlpassthrunum09),
           dtlpassthrunum10 = nvl(decode(in_dtlpassthrunum10,0,null,in_dtlpassthrunum10),dtlpassthrunum10),
           dtlpassthrudate01 = nvl(dtedtlpassthrudate01,dtlpassthrudate01),
           dtlpassthrudate02 = nvl(dtedtlpassthrudate02,dtlpassthrudate02),
           dtlpassthrudate03 = nvl(dtedtlpassthrudate03,dtlpassthrudate03),
           dtlpassthrudate04 = nvl(dtedtlpassthrudate04,dtlpassthrudate04),
           dtlpassthrudoll01 = nvl(decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),dtlpassthrudoll01),
           dtlpassthrudoll02 = nvl(decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),dtlpassthrudoll02),
           rfautodisplay = nvl(rtrim(in_rfautodisplay),rfautodisplay)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
    if rtrim(in_instructions) is not null then
      update orderdtl
         set comment1 = in_instructions
       where orderid = out_orderid
         and shipid = out_shipid
         and item = strItem
         and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
    end if;
    if rtrim(in_bolcomment) is not null then
      update orderdtlbolcomments
         set bolcomment = rtrim(in_bolcomment),
             lastuser = IMP_USERID,
             lastupdate = sysdate
       where orderid = out_orderid
         and shipid = out_shipid
         and item = strItem
         and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
    end if;
  end if;
elsif rtrim(in_func) = 'D' then -- delete function (do a cancel)
  update orderdtl
     set linestatus = 'X',
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
  delete from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
     and nvl(xdock,'N') = 'N';
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziol ' || sqlerrm;
  out_errorno := sqlcode;
end I15_import_order_line;

procedure I15_end_of_import
(in_importfileid IN varchar2
,in_userid IN varchar2
,in_cleanup_load IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor getCust is
  select custid,
         fromfacility
    from orderhdr
   where importfileid = rtrim(upper(in_importfileid));
gc getCust%rowtype;

cursor curCust(in_custid varchar2) is
  select outRejectBatchMap,
         outConfirmBatchMap,
         outStatusBatchMap,
         outShipSumBatchMap,
         assign_stop_by_passthru_yn,
         assign_stop_load_passthru,
         assign_stop_stop_passthru
    from customer
   where custid = in_custid;
cs curCust%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg(IMP_USERID, gc.fromfacility, rtrim(gc.custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
gc.fromfacility := 'ALL';

open getCust;
fetch getCust into gc;
if getCust%notfound then
  close getCust;
  out_msg := 'Cannot get customer code: ' || in_importfileid;
  out_errorno := -1;
  return;
end if;
close getCust;

open curCust(gc.custid);
fetch curCust into cs;
if curCust%notfound then
  close curCust;
  out_msg := 'Invalid customer code: ' || gc.custid;
  out_errorno := -2;
  return;
end if;
close curCust;

out_msg := 'End of import: ' ||gc.custid || ' ' || in_importfileid || ' '
  || in_userid;
order_msg('I');

zgp.pick_request('ENDIMP',gc.fromfacility,IMP_USERID,0,0,0,
  in_importfileid,gc.custid,0,null,null,'N',out_errorno,out_msg);

if nvl(cs.assign_stop_by_passthru_yn,'N') = 'Y'
and nvl(in_cleanup_load, 'N') = 'Y' then
   for cld in
    (select distinct fromfacility,
        decode( nvl(substr(cs.assign_stop_load_passthru,-2),'??'),
            '??',0,
            '01',nvl(O.hdrpassthrunum01,0),
            '02',nvl(O.hdrpassthrunum02,0),
            '03',nvl(O.hdrpassthrunum03,0),
            '04',nvl(O.hdrpassthrunum04,0),
            '05',nvl(O.hdrpassthrunum05,0),
            '06',nvl(O.hdrpassthrunum06,0),
            '07',nvl(O.hdrpassthrunum07,0),
            '08',nvl(O.hdrpassthrunum08,0),
            '09',nvl(O.hdrpassthrunum09,0),
            '10',nvl(O.hdrpassthrunum10,0),
            0) loadno
      from orderhdr O
     where O.importfileid = in_importfileid)
    loop
        if nvl(cld.loadno,0) > 0 then

            for cord in (select orderid, shipid
                           from orderhdr O
                          where fromfacility = cld.fromfacility
                            and ordertype = 'O'
                            and orderstatus in ('0','1')
                            and importfileid != in_importfileid
                            and cld.loadno =
                                decode(
                        nvl(substr(cs.assign_stop_load_passthru,-2),'??'),
                                    '??',0,
                                    '01',nvl(O.hdrpassthrunum01,0),
                                    '02',nvl(O.hdrpassthrunum02,0),
                                    '03',nvl(O.hdrpassthrunum03,0),
                                    '04',nvl(O.hdrpassthrunum04,0),
                                    '05',nvl(O.hdrpassthrunum05,0),
                                    '06',nvl(O.hdrpassthrunum06,0),
                                    '07',nvl(O.hdrpassthrunum07,0),
                                    '08',nvl(O.hdrpassthrunum08,0),
                                    '09',nvl(O.hdrpassthrunum09,0),
                                    '10',nvl(O.hdrpassthrunum10,0),
                                    0)) loop

               zoe.cancel_order_request(cord.orderid, cord.shipid,
                    cld.fromfacility,
                   'EDI',IMP_USERID, out_msg);
            end loop;

        end if;

    end loop;


end if;


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zim4I15end ' || sqlerrm;
  out_errorno := sqlcode;
end I15_end_of_import;

procedure I55_import_order_header
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ordertype IN varchar2
,in_entrydate IN date
,in_apptdate IN date
,in_shipdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_tofacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
,in_shippername IN varchar2
,in_shippercontact IN varchar2
,in_shipperaddr1 IN varchar2
,in_shipperaddr2 IN varchar2
,in_shippercity IN varchar2
,in_shipperstate IN varchar2
,in_shipperpostalcode IN varchar2
,in_shippercountrycode IN varchar2
,in_shipperphone IN varchar2
,in_shipperfax IN varchar2
,in_shipperemail IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_shiptocountrycode IN varchar2
,in_shiptophone IN varchar2
,in_shiptofax IN varchar2
,in_shiptoemail IN varchar2
,in_billtoname IN varchar2
,in_billtocontact IN varchar2
,in_billtoaddr1 IN varchar2
,in_billtoaddr2 IN varchar2
,in_billtocity IN varchar2
,in_billtostate IN varchar2
,in_billtopostalcode IN varchar2
,in_billtocountrycode IN varchar2
,in_billtophone IN varchar2
,in_billtofax IN varchar2
,in_billtoemail IN varchar2
,in_deliveryservice IN varchar2
,in_saturdaydelivery IN varchar2
,in_cod IN varchar2
,in_amtcod IN number
,in_specialservice1 IN varchar2
,in_specialservice2 IN varchar2
,in_specialservice3 IN varchar2
,in_specialservice4 IN varchar2
,in_importfileid IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_hdrpassthruchar02 IN varchar2
,in_hdrpassthruchar03 IN varchar2
,in_hdrpassthruchar04 IN varchar2
,in_hdrpassthruchar05 IN varchar2
,in_hdrpassthruchar06 IN varchar2
,in_hdrpassthruchar07 IN varchar2
,in_hdrpassthruchar08 IN varchar2
,in_hdrpassthruchar09 IN varchar2
,in_hdrpassthruchar10 IN varchar2
,in_hdrpassthruchar11 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar13 IN varchar2
,in_hdrpassthruchar14 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
,in_hdrpassthrunum01 IN number
,in_hdrpassthrunum02 IN number
,in_hdrpassthrunum03 IN number
,in_hdrpassthrunum04 IN number
,in_hdrpassthrunum05 IN number
,in_hdrpassthrunum06 IN number
,in_hdrpassthrunum07 IN number
,in_hdrpassthrunum08 IN number
,in_hdrpassthrunum09 IN number
,in_hdrpassthrunum10 IN number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         nvl(fromfacility, tofacility) facility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(resubmitorder,'N') as resubmitorder,
        unique_order_identifier
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;

cntRows integer;
dteShipDate date;
dteApptDate date;

procedure delete_old_order(in_orderid number, in_shipid number) is
begin
  delete from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
  delete from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
end;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  if nvl(cs.unique_order_identifier,'R') = 'P' then
    out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) 
        ||' PO. '||rtrim(in_po)|| ': ' || out_msg;
  else
    out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) 
        || ': ' || out_msg;
  end if;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, nvl(in_fromfacility,in_tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if rtrim(in_func) = 'D' then -- cancel function
  if out_orderid = 0 then
    out_errorno := 3;
    out_msg := 'Order to be cancelled not found';
    order_msg('E');
    return;
  end if;
end if;

begin
  if trunc(in_shipdate) = to_date('12/30/1899','mm/dd/yyyy') then
    dteShipDate := null;
  else
    dteShipDate := in_shipdate;
  end if;
exception when others then
  dteShipDate := null;
end;

begin
  if trunc(in_ApptDate) = to_date('12/30/1899','mm/dd/yyyy') then
    dteApptDate := null;
  else
    dteApptDate := in_ApptDate;
  end if;
exception when others then
  dteApptDate := null;
end;

if rtrim(in_func) = 'A' then
  if out_orderid != 0 then
    open curCustomer;
    fetch curCustomer into cs;
    if curCustomer%notfound then
      cs.resubmitorder := 'N';
    end if;
    close curCustomer;
    if (cs.resubmitorder = 'N') or
       (oh.orderstatus != 'X') then
      out_msg := 'Add request rejected--order already on file';
      order_msg('W');
      return;
    else
      delete_old_order(out_orderid, out_shipid);
      out_msg := 'Resubmit of rejected order';
      order_msg('I');
    end if;
  end if;
end if;

if rtrim(in_func) = 'U' then
  if out_orderid = 0 then
    out_msg := 'Update requested--order not on file--add performed';
    order_msg('W');
    in_func := 'A';
  else
    if oh.orderstatus > '1' then
      out_errorno := 2;
      out_msg := 'Invalid Order Status: ' || oh.orderstatus;
      order_msg('E');
      return;
    end if;
  end if;
end if;

if rtrim(in_func) = 'R' then
  if out_orderid = 0 then
    out_msg := 'Replace requested--order not on file--add performed';
    order_msg('W');
    in_func := 'A';
  else
    if oh.orderstatus > '1' then
      out_errorno := 2;
      out_msg := 'Invalid Order Status for replace: ' || oh.orderstatus;
      order_msg('E');
      return;
    end if;
    delete_old_order(out_orderid,out_shipid);
    out_msg := 'Order replace transaction processed';
    order_msg('I');
  end if;
end if;

if out_orderid = 0 then
  zoe.get_next_orderid(out_orderid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 4;
    order_msg('E');
    return;
  end if;
  out_shipid := 1;
end if;

if rtrim(in_func) in ('A','R') then
  insert into orderhdr
  (orderid,shipid,custid,ordertype,apptdate,shipdate,po,rma,
   fromfacility,tofacility,shipto,billoflading,priority,shipper,
   consignee,shiptype,carrier,reference,shipterms,shippername,shippercontact,
   shipperaddr1,shipperaddr2,shippercity,shipperstate,shipperpostalcode,shippercountrycode,
   shipperphone,shipperfax,shipperemail,shiptoname,shiptocontact,
   shiptoaddr1,shiptoaddr2,shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,
   shiptophone,shiptofax,shiptoemail,billtoname,billtocontact,
   billtoaddr1,billtoaddr2,billtocity,billtostate,
   billtopostalcode,billtocountrycode,
   billtophone,billtofax,billtoemail,lastuser,lastupdate,
   orderstatus,commitstatus,statususer,entrydate,
   hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03, hdrpassthruchar04,
   hdrpassthruchar05, hdrpassthruchar06, hdrpassthruchar07, hdrpassthruchar08,
   hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11, hdrpassthruchar12,
   hdrpassthruchar13, hdrpassthruchar14, hdrpassthruchar15, hdrpassthruchar16,
   hdrpassthruchar17, hdrpassthruchar18, hdrpassthruchar19, hdrpassthruchar20,
   hdrpassthrunum01, hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04,
   hdrpassthrunum05, hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08,
   hdrpassthrunum09, hdrpassthrunum10, importfileid, deliveryservice,
   saturdaydelivery, cod, amtcod,
   specialservice1, specialservice2,
   specialservice3, specialservice4,
   source
   )
  values
  (out_orderid,out_shipid,nvl(rtrim(in_custid),' '),nvl(rtrim(in_ordertype),' '),
  dteapptdate,dteshipdate,rtrim(in_po),rtrim(in_rma),rtrim(in_fromfacility),
  rtrim(in_tofacility),rtrim(in_shipto),rtrim(in_billoflading),
  rtrim(in_priority),rtrim(in_shipper),rtrim(in_consignee),rtrim(in_shiptype),
  rtrim(in_carrier),rtrim(in_reference),rtrim(in_shipterms),
  rtrim(in_shippername),rtrim(in_shippercontact),
  rtrim(in_shipperaddr1),rtrim(in_shipperaddr2),rtrim(in_shippercity),
  rtrim(in_shipperstate),rtrim(in_shipperpostalcode),rtrim(in_shippercountrycode),
  rtrim(in_shipperphone),rtrim(in_shipperfax),rtrim(in_shipperemail),
  rtrim(in_shiptoname),rtrim(in_shiptocontact),
  rtrim(in_shiptoaddr1),rtrim(in_shiptoaddr2),rtrim(in_shiptocity),
  rtrim(in_shiptostate),rtrim(in_shiptopostalcode),rtrim(in_shiptocountrycode),
  rtrim(in_shiptophone),rtrim(in_shiptofax),rtrim(in_shiptoemail),
  rtrim(in_billtoname),rtrim(in_billtocontact),rtrim(in_billtoaddr1),rtrim(in_billtoaddr2),
  rtrim(in_billtocity),rtrim(in_billtostate),rtrim(in_billtopostalcode),
  rtrim(in_billtocountrycode),rtrim(in_billtophone),rtrim(in_billtofax),
  rtrim(in_billtoemail),IMP_USERID,sysdate,
  '0','0',IMP_USERID,nvl(in_entrydate,sysdate),
  rtrim(in_hdrpassthruchar01),rtrim(in_hdrpassthruchar02),
  rtrim(in_hdrpassthruchar03),rtrim(in_hdrpassthruchar04),
  rtrim(in_hdrpassthruchar05),rtrim(in_hdrpassthruchar06),
  rtrim(in_hdrpassthruchar07),rtrim(in_hdrpassthruchar08),
  rtrim(in_hdrpassthruchar09),rtrim(in_hdrpassthruchar10),
  rtrim(in_hdrpassthruchar11),rtrim(in_hdrpassthruchar12),
  rtrim(in_hdrpassthruchar13),rtrim(in_hdrpassthruchar14),
  rtrim(in_hdrpassthruchar15),rtrim(in_hdrpassthruchar16),
  rtrim(in_hdrpassthruchar17),rtrim(in_hdrpassthruchar18),
  rtrim(in_hdrpassthruchar19),rtrim(in_hdrpassthruchar20),
  decode(in_hdrpassthrunum01,0,null,in_hdrpassthrunum01),
  decode(in_hdrpassthrunum02,0,null,in_hdrpassthrunum02),
  decode(in_hdrpassthrunum03,0,null,in_hdrpassthrunum03),
  decode(in_hdrpassthrunum04,0,null,in_hdrpassthrunum04),
  decode(in_hdrpassthrunum05,0,null,in_hdrpassthrunum05),
  decode(in_hdrpassthrunum06,0,null,in_hdrpassthrunum06),
  decode(in_hdrpassthrunum07,0,null,in_hdrpassthrunum07),
  decode(in_hdrpassthrunum08,0,null,in_hdrpassthrunum08),
  decode(in_hdrpassthrunum09,0,null,in_hdrpassthrunum09),
  decode(in_hdrpassthrunum10,0,null,in_hdrpassthrunum10),
  upper(rtrim(in_importfileid)),
  rtrim(in_deliveryservice),
  rtrim(in_saturdaydelivery),
  rtrim(in_cod),
  decode(in_amtcod,0,null,in_amtcod),
  rtrim(in_specialservice1),
  rtrim(in_specialservice2),
  rtrim(in_specialservice3),
  rtrim(in_specialservice4),
  'EDI'
  );
elsif rtrim(in_func) = 'U' then
  update orderhdr
     set orderstatus = '0',
         commitstatus = '0',
         entrydate = nvl(in_entrydate,entrydate),
         apptdate = nvl(dteapptdate,apptdate),
         shipdate = nvl(dteshipdate,shipdate),
         shipto = nvl(rtrim(in_shipto),shipto),
         billoflading = nvl(rtrim(in_billoflading),billoflading),
         priority = nvl(rtrim(in_priority),priority),
         shipper = nvl(rtrim(in_shipper),shipper),
         consignee = nvl(rtrim(in_consignee),consignee),
         shiptype = nvl(rtrim(in_shiptype),shiptype),
         carrier = nvl(rtrim(in_carrier),carrier),
         shipterms = nvl(rtrim(in_shipterms),shipterms),
         shippername = nvl(rtrim(in_shippername),shippername),
         shippercontact = nvl(rtrim(in_shippercontact),shippercontact),
         shipperaddr1 = nvl(rtrim(in_shipperaddr1),shipperaddr1),
         shipperaddr2 = nvl(rtrim(in_shipperaddr2),shipperaddr2),
         shippercity = nvl(rtrim(in_shippercity),shippercity),
         shipperstate = nvl(rtrim(in_shipperstate),shipperstate),
         shipperpostalcode = nvl(rtrim(in_shipperpostalcode),shipperpostalcode),
         shippercountrycode = nvl(rtrim(in_shippercountrycode),shippercountrycode),
         shipperphone = nvl(rtrim(in_shipperphone),shipperphone),
         shipperfax = nvl(rtrim(in_shipperfax),shipperfax),
         shipperemail = nvl(rtrim(in_shipperemail),shipperemail),
         shiptoname = nvl(rtrim(in_shiptoname),shiptoname),
         shiptocontact = nvl(rtrim(in_shiptocontact),shiptocontact),
         shiptoaddr1 = nvl(rtrim(in_shiptoaddr1),shiptoaddr1),
         shiptoaddr2 = nvl(rtrim(in_shiptoaddr2),shiptoaddr2),
         shiptocity = nvl(rtrim(in_shiptocity),shiptocity),
         shiptostate = nvl(rtrim(in_shiptostate),shiptostate),
         shiptopostalcode = nvl(rtrim(in_shiptopostalcode),shiptopostalcode),
         shiptocountrycode = nvl(rtrim(in_shiptocountrycode),shiptocountrycode),
         shiptophone = nvl(rtrim(in_shiptophone),shiptophone),
         shiptofax = nvl(rtrim(in_shiptofax),shiptofax),
         shiptoemail = nvl(rtrim(in_shiptoemail),shiptoemail),
         billtoname = nvl(rtrim(in_billtoname),billtoname),
         billtocontact = nvl(rtrim(in_billtocontact),billtocontact),
         billtoaddr1 = nvl(rtrim(in_billtoaddr1),billtoaddr1),
         billtoaddr2 = nvl(rtrim(in_billtoaddr2),billtoaddr2),
         billtocity = nvl(rtrim(in_billtocity),billtocity),
         billtostate = nvl(rtrim(in_billtostate),billtostate),
         billtopostalcode = nvl(rtrim(in_billtopostalcode),billtopostalcode),
         billtocountrycode = nvl(rtrim(in_billtocountrycode),billtocountrycode),
         billtophone = nvl(rtrim(in_billtophone),billtophone),
         billtofax = nvl(rtrim(in_billtofax),billtofax),
         billtoemail = nvl(rtrim(in_billtoemail),billtoemail),
         deliveryservice = nvl(rtrim(in_deliveryservice),deliveryservice),
         saturdaydelivery = nvl(rtrim(in_saturdaydelivery),saturdaydelivery),
         cod = nvl(rtrim(in_cod),cod),
         amtcod = nvl(decode(in_amtcod,0,null,in_amtcod),amtcod),
         specialservice1 = nvl(rtrim(in_specialservice1),specialservice1),
         specialservice2 = nvl(rtrim(in_specialservice2),specialservice2),
         specialservice3 = nvl(rtrim(in_specialservice3),specialservice3),
         specialservice4 = nvl(rtrim(in_specialservice4),specialservice4),
         lastuser = IMP_USERID,
         lastupdate = sysdate,
         hdrpassthruchar01 = nvl(rtrim(in_hdrpassthruchar01),hdrpassthruchar01),
         hdrpassthruchar02 = nvl(rtrim(in_hdrpassthruchar02),hdrpassthruchar02),
         hdrpassthruchar03 = nvl(rtrim(in_hdrpassthruchar03),hdrpassthruchar03),
         hdrpassthruchar04 = nvl(rtrim(in_hdrpassthruchar04),hdrpassthruchar04),
         hdrpassthruchar05 = nvl(rtrim(in_hdrpassthruchar05),hdrpassthruchar05),
         hdrpassthruchar06 = nvl(rtrim(in_hdrpassthruchar06),hdrpassthruchar06),
         hdrpassthruchar07 = nvl(rtrim(in_hdrpassthruchar07),hdrpassthruchar07),
         hdrpassthruchar08 = nvl(rtrim(in_hdrpassthruchar08),hdrpassthruchar08),
         hdrpassthruchar09 = nvl(rtrim(in_hdrpassthruchar09),hdrpassthruchar09),
         hdrpassthruchar10 = nvl(rtrim(in_hdrpassthruchar10),hdrpassthruchar10),
         hdrpassthruchar11 = nvl(rtrim(in_hdrpassthruchar11),hdrpassthruchar11),
         hdrpassthruchar12 = nvl(rtrim(in_hdrpassthruchar12),hdrpassthruchar12),
         hdrpassthruchar13 = nvl(rtrim(in_hdrpassthruchar13),hdrpassthruchar13),
         hdrpassthruchar14 = nvl(rtrim(in_hdrpassthruchar14),hdrpassthruchar14),
         hdrpassthruchar15 = nvl(rtrim(in_hdrpassthruchar15),hdrpassthruchar15),
         hdrpassthruchar16 = nvl(rtrim(in_hdrpassthruchar16),hdrpassthruchar16),
         hdrpassthruchar17 = nvl(rtrim(in_hdrpassthruchar17),hdrpassthruchar17),
         hdrpassthruchar18 = nvl(rtrim(in_hdrpassthruchar18),hdrpassthruchar18),
         hdrpassthruchar19 = nvl(rtrim(in_hdrpassthruchar19),hdrpassthruchar19),
         hdrpassthruchar20 = nvl(rtrim(in_hdrpassthruchar20),hdrpassthruchar20),
         hdrpassthrunum01 = nvl(decode(in_hdrpassthrunum01,0,null,in_hdrpassthrunum01),hdrpassthrunum01),
         hdrpassthrunum02 = nvl(decode(in_hdrpassthrunum02,0,null,in_hdrpassthrunum02),hdrpassthrunum02),
         hdrpassthrunum03 = nvl(decode(in_hdrpassthrunum03,0,null,in_hdrpassthrunum03),hdrpassthrunum03),
         hdrpassthrunum04 = nvl(decode(in_hdrpassthrunum04,0,null,in_hdrpassthrunum04),hdrpassthrunum04),
         hdrpassthrunum05 = nvl(decode(in_hdrpassthrunum05,0,null,in_hdrpassthrunum05),hdrpassthrunum05),
         hdrpassthrunum06 = nvl(decode(in_hdrpassthrunum06,0,null,in_hdrpassthrunum06),hdrpassthrunum06),
         hdrpassthrunum07 = nvl(decode(in_hdrpassthrunum07,0,null,in_hdrpassthrunum07),hdrpassthrunum07),
         hdrpassthrunum08 = nvl(decode(in_hdrpassthrunum08,0,null,in_hdrpassthrunum08),hdrpassthrunum08),
         hdrpassthrunum09 = nvl(decode(in_hdrpassthrunum09,0,null,in_hdrpassthrunum09),hdrpassthrunum09),
         hdrpassthrunum10 = nvl(decode(in_hdrpassthrunum10,0,null,in_hdrpassthrunum10),hdrpassthrunum10),
         importfileid = nvl(upper(rtrim(in_importfileid)),importfileid)
   where orderid = out_orderid
     and shipid = out_shipid;
elsif rtrim(in_func) = 'D' then
   zoe.cancel_order_request(out_orderid, out_shipid, oh.facility,
       'EDI',IMP_USERID, out_msg);
end if;
/*
out_msg := 'reached end-of-proc';
order_msg('I');
*/
out_msg := 'OKAY';

exception when others then
  out_msg := 'zioh ' || sqlerrm;
  out_errorno := sqlcode;
end I55_import_order_header;

procedure I55_import_order_line
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN number
,in_backorder IN varchar2
,in_allowsub IN varchar2
,in_qtytype IN varchar2
,in_invstatusind IN varchar2
,in_invstatus IN varchar2
,in_invclassind IN varchar2
,in_inventoryclass IN varchar2
,in_consigneesku IN varchar2
,in_dtlpassthruchar01 IN varchar2
,in_dtlpassthruchar02 IN varchar2
,in_dtlpassthruchar03 IN varchar2
,in_dtlpassthruchar04 IN varchar2
,in_dtlpassthruchar05 IN varchar2
,in_dtlpassthruchar06 IN varchar2
,in_dtlpassthruchar07 IN varchar2
,in_dtlpassthruchar08 IN varchar2
,in_dtlpassthruchar09 IN varchar2
,in_dtlpassthruchar10 IN varchar2
,in_dtlpassthruchar11 IN varchar2
,in_dtlpassthruchar12 IN varchar2
,in_dtlpassthruchar13 IN varchar2
,in_dtlpassthruchar14 IN varchar2
,in_dtlpassthruchar15 IN varchar2
,in_dtlpassthruchar16 IN varchar2
,in_dtlpassthruchar17 IN varchar2
,in_dtlpassthruchar18 IN varchar2
,in_dtlpassthruchar19 IN varchar2
,in_dtlpassthruchar20 IN varchar2
,in_dtlpassthrunum01 IN number
,in_dtlpassthrunum02 IN number
,in_dtlpassthrunum03 IN number
,in_dtlpassthrunum04 IN number
,in_dtlpassthrunum05 IN number
,in_dtlpassthrunum06 IN number
,in_dtlpassthrunum07 IN number
,in_dtlpassthrunum08 IN number
,in_dtlpassthrunum09 IN number
,in_dtlpassthrunum10 IN number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         ordertype,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = rtrim(in_custid);
cs curCustomer%rowtype;

cursor curOrderDtl is
  select linestatus,
         itementered,
         item,
         qtyentered,
         qtyorder,
         lotnumber,
         dtlpassthruchar01,
         dtlpassthruchar02,
         dtlpassthruchar03,
         dtlpassthruchar04,
         dtlpassthruchar05,
         dtlpassthruchar06,
         dtlpassthruchar07,
         dtlpassthruchar08,
         dtlpassthruchar09,
         dtlpassthruchar10,
         dtlpassthruchar11,
         dtlpassthruchar12,
         dtlpassthruchar13,
         dtlpassthruchar14,
         dtlpassthruchar15,
         dtlpassthruchar16,
         dtlpassthruchar17,
         dtlpassthruchar18,
         dtlpassthruchar19,
         dtlpassthruchar20,
         dtlpassthrunum01,
         dtlpassthrunum02,
         dtlpassthrunum03,
         dtlpassthrunum04,
         dtlpassthrunum05,
         dtlpassthrunum06,
         dtlpassthrunum07,
         dtlpassthrunum08,
         dtlpassthrunum09,
         dtlpassthrunum10
    from orderdtl
   where orderid = out_orderid
     and shipid = out_shipid
     and itementered = rtrim(in_itementered)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
od curOrderDtl%rowtype;

cursor curOrderDtlLineCount(in_item varchar2) is
  select count(1) as count
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = rtrim(in_item)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
     and nvl(xdock,'N') = 'N';
olc curOrderDtlLineCount%rowtype;

cursor curOrderDtlLine(in_linenumber number) is
  select item,
         lotnumber,
         qty,
         qtyentered
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and linenumber = in_linenumber;
ol curOrderDtlLine%rowtype;

cursor curCustItem(in_item varchar2) is
  select useramt1,
         backorder,
         allowsub,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtytype,
         baseuom
    from custitemview
   where custid = rtrim(in_custid)
     and item = rtrim(in_item);
ci curCustItem%rowtype;

chk orderdtlline%rowtype;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  item_msg('E');
  return;
end if;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  item_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: ' || oh.orderstatus;
  item_msg('E');
  return;
end if;

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.linenumbersyn := 'N';
end if;
close curCustomer;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%found then
  chk.item := od.item;
  chk.lotnumber := od.lotnumber;
else
  chk.item := null;
  chk.lotnumber := null;
end if;
close curOrderDtl;

if rtrim(in_func) = 'D' then -- cancel function
  if chk.item is null then
    out_errorno := 3;
    out_msg := 'Order-line to be cancelled not found';
    item_msg('E');
    return;
  end if;
  if od.linestatus = 'X' then
    out_errorno := 4;
    out_msg := 'Order-line already cancelled';
    item_msg('E');
    return;
  end if;
end if;

zci.get_customer_item(rtrim(in_custid),rtrim(in_itementered),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := in_itementered;
end if;

olc.count := 0;

if cs.linenumbersyn = 'Y' then
  if nvl(in_dtlpassthrunum10,0) <= 0 then
    out_errorno := 5;
    out_msg := 'Invalid Line Number: ' || in_dtlpassthrunum10;
    item_msg('E');
    return;
  end if;
  open curOrderDtlLineCount(strItem);
  fetch curOrderDtlLineCount into olc;
  if curOrderDtlLineCount%notfound then
    olc.count := 0;
  end if;
  close curOrderDtlLineCount;
  chk.linenumber := null;
  if olc.count != 0 then
    open curOrderDtlLine(in_dtlpassthrunum10);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      if (ol.item != strItem) or
         (nvl(ol.lotnumber,'(none)') != nvl(rtrim(in_lotnumber),'(none)')) then
        out_errorno := 6;
        out_msg := 'Line Number Mismatch: ' || in_dtlpassthrunum10;
        item_msg('E');
        return;
      else
        chk.linenumber := in_dtlpassthrunum10;
      end if;
    end if;
    close curOrderDtlLine;
  else
    if od.dtlpassthrunum10 = in_dtlpassthrunum10 then
      chk.linenumber := od.dtlpassthrunum10;
    end if;
  end if;
end if;

if rtrim(in_func) in ('A','R') then
  if ( (cs.linenumbersyn != 'Y') and (chk.item is not null) ) or
     ( (cs.linenumbersyn = 'Y') and (chk.linenumber is not null) ) then
    out_msg := 'Add requested--order-line already on file--update performed';
    item_msg('W');
    in_func := 'U';
  end if;
elsif rtrim(in_func) = 'U' then
  if ( (cs.linenumbersyn != 'Y') and (chk.item is null) ) or
     ( (cs.linenumbersyn = 'Y') and (chk.linenumber is null) ) then
    out_msg := 'Update requested--order-line not on file--add performed';
    item_msg('W');
    in_func := 'A';
  end if;
end if;

open curCustItem(strItem);
fetch curCustItem into ci;
if curCustItem%notfound then
  ci.useramt1 := 0;
  ci.baseuom := 'EA';
end if;
close curCustItem;

if oh.ordertype in ('R','Q','P','A','C','I') then
  ci.invstatus := null;
  ci.inventoryclass := null;
end if;

zoe.get_base_uom_equivalent(rtrim(in_custid),rtrim(in_itementered),
  nvl(rtrim(in_uomentered),ci.baseuom),
  in_qtyentered,strItem,strUOMBase,qtyBase,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := rtrim(in_itementered);
  strUOMBase :=  nvl(rtrim(in_uomentered),ci.baseuom);
  qtyBase := in_qtyentered;
end if;

if rtrim(in_func) in ('A','R') then
  if chk.item is null then
    insert into orderdtl
    (orderid,shipid,item,lotnumber,uom,linestatus,qtyentered,itementered,uomentered,
    qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,
    backorder,allowsub,qtytype,invstatusind,invstatus,invclassind,
    inventoryclass,consigneesku,statususer,
    dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
    dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
    dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
    dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
    dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
    dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
    dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
    dtlpassthrunum09, dtlpassthrunum10
    )
    values
    (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),strUOMBase,'A',
     in_qtyentered,rtrim(in_itementered), nvl(rtrim(in_uomentered),ci.baseuom),
     qtyBase,
     zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
     zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
     qtyBase*ci.useramt1,IMP_USERID,sysdate,
     nvl(rtrim(in_backorder),ci.backorder),nvl(rtrim(in_allowsub),ci.allowsub),
     nvl(rtrim(in_qtytype),ci.qtytype),nvl(rtrim(in_invstatusind),ci.invstatusind),
     nvl(rtrim(in_invstatus),ci.invstatus),nvl(rtrim(in_invclassind),ci.invclassind),
     nvl(rtrim(in_inventoryclass),ci.inventoryclass),rtrim(in_consigneesku),
     IMP_USERID,
     rtrim(in_dtlpassthruchar01),rtrim(in_dtlpassthruchar02),
     rtrim(in_dtlpassthruchar03),rtrim(in_dtlpassthruchar04),
     rtrim(in_dtlpassthruchar05),rtrim(in_dtlpassthruchar06),
     rtrim(in_dtlpassthruchar07),rtrim(in_dtlpassthruchar08),
     rtrim(in_dtlpassthruchar09),rtrim(in_dtlpassthruchar10),
     rtrim(in_dtlpassthruchar11),rtrim(in_dtlpassthruchar12),
     rtrim(in_dtlpassthruchar13),rtrim(in_dtlpassthruchar14),
     rtrim(in_dtlpassthruchar15),rtrim(in_dtlpassthruchar16),
     rtrim(in_dtlpassthruchar17),rtrim(in_dtlpassthruchar18),
     rtrim(in_dtlpassthruchar19),rtrim(in_dtlpassthruchar20),
     decode(in_dtlpassthrunum01,0,null,in_dtlpassthrunum01),
     decode(in_dtlpassthrunum02,0,null,in_dtlpassthrunum02),
     decode(in_dtlpassthrunum03,0,null,in_dtlpassthrunum03),
     decode(in_dtlpassthrunum04,0,null,in_dtlpassthrunum04),
     decode(in_dtlpassthrunum05,0,null,in_dtlpassthrunum05),
     decode(in_dtlpassthrunum06,0,null,in_dtlpassthrunum06),
     decode(in_dtlpassthrunum07,0,null,in_dtlpassthrunum07),
     decode(in_dtlpassthrunum08,0,null,in_dtlpassthrunum08),
     decode(in_dtlpassthrunum09,0,null,in_dtlpassthrunum09),
     decode(in_dtlpassthrunum10,0,null,in_dtlpassthrunum10)
     );
	 
   -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
   -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
   update orderdtl
   set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  else
    if olc.count = 0 then --add line record for item info that is already on file
      insert into orderdtlline
       (orderid,shipid,item,lotnumber,
        linenumber,qty,
        dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
        dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
        dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
        dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
        dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
        dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
        dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
        dtlpassthrunum09, dtlpassthrunum10, lastuser, lastupdate
       )
       values
       (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
        od.dtlpassthrunum10,od.qtyorder,
        od.dtlpassthruchar01, od.dtlpassthruchar02, od.dtlpassthruchar03, od.dtlpassthruchar04,
        od.dtlpassthruchar05, od.dtlpassthruchar06, od.dtlpassthruchar07, od.dtlpassthruchar08,
        od.dtlpassthruchar09, od.dtlpassthruchar10, od.dtlpassthruchar11, od.dtlpassthruchar12,
        od.dtlpassthruchar13, od.dtlpassthruchar14, od.dtlpassthruchar15, od.dtlpassthruchar16,
        od.dtlpassthruchar17, od.dtlpassthruchar18, od.dtlpassthruchar19, od.dtlpassthruchar20,
        od.dtlpassthrunum01, od.dtlpassthrunum02, od.dtlpassthrunum03, od.dtlpassthrunum04,
        od.dtlpassthrunum05, od.dtlpassthrunum06, od.dtlpassthrunum07, od.dtlpassthrunum08,
        od.dtlpassthrunum09, od.dtlpassthrunum10, IMP_USERID, sysdate
       );
    end if;
    insert into orderdtlline
     (orderid,shipid,item,lotnumber,
      linenumber,qty,
      dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
      dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
      dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
      dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
      dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
      dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
      dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
      dtlpassthrunum09, dtlpassthrunum10, lastuser, lastupdate
     )
     values
     (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
      in_dtlpassthrunum10,qtyBase,
      decode(nvl(od.dtlpassthruchar01,'x'),nvl(rtrim(in_dtlpassthruchar01),'x'),
        od.dtlpassthruchar01,nvl(rtrim(in_dtlpassthruchar01),' ')),
      decode(nvl(od.dtlpassthruchar02,'x'),nvl(rtrim(in_dtlpassthruchar02),'x'),
        od.dtlpassthruchar02,nvl(rtrim(in_dtlpassthruchar02),' ')),
      decode(nvl(od.dtlpassthruchar03,'x'),nvl(rtrim(in_dtlpassthruchar03),'x'),
        od.dtlpassthruchar03,nvl(rtrim(in_dtlpassthruchar03),' ')),
      decode(nvl(od.dtlpassthruchar04,'x'),nvl(rtrim(in_dtlpassthruchar04),'x'),
        od.dtlpassthruchar04,nvl(rtrim(in_dtlpassthruchar04),' ')),
      decode(nvl(od.dtlpassthruchar05,'x'),nvl(rtrim(in_dtlpassthruchar05),'x'),
        od.dtlpassthruchar05,nvl(rtrim(in_dtlpassthruchar05),' ')),
      decode(nvl(od.dtlpassthruchar06,'x'),nvl(rtrim(in_dtlpassthruchar06),'x'),
        od.dtlpassthruchar06,nvl(rtrim(in_dtlpassthruchar06),' ')),
      decode(nvl(od.dtlpassthruchar07,'x'),nvl(rtrim(in_dtlpassthruchar07),'x'),
        od.dtlpassthruchar07,nvl(rtrim(in_dtlpassthruchar07),' ')),
      decode(nvl(od.dtlpassthruchar08,'x'),nvl(rtrim(in_dtlpassthruchar08),'x'),
        od.dtlpassthruchar08,nvl(rtrim(in_dtlpassthruchar08),' ')),
      decode(nvl(od.dtlpassthruchar09,'x'),nvl(rtrim(in_dtlpassthruchar09),'x'),
        od.dtlpassthruchar09,nvl(rtrim(in_dtlpassthruchar09),' ')),
      decode(nvl(od.dtlpassthruchar10,'x'),nvl(rtrim(in_dtlpassthruchar10),'x'),
        od.dtlpassthruchar10,nvl(rtrim(in_dtlpassthruchar10),' ')),
      decode(nvl(od.dtlpassthruchar11,'x'),nvl(rtrim(in_dtlpassthruchar11),'x'),
        od.dtlpassthruchar11,nvl(rtrim(in_dtlpassthruchar11),' ')),
      decode(nvl(od.dtlpassthruchar12,'x'),nvl(rtrim(in_dtlpassthruchar12),'x'),
        od.dtlpassthruchar12,nvl(rtrim(in_dtlpassthruchar12),' ')),
      decode(nvl(od.dtlpassthruchar13,'x'),nvl(rtrim(in_dtlpassthruchar13),'x'),
        od.dtlpassthruchar13,nvl(rtrim(in_dtlpassthruchar13),' ')),
      decode(nvl(od.dtlpassthruchar14,'x'),nvl(rtrim(in_dtlpassthruchar14),'x'),
        od.dtlpassthruchar14,nvl(rtrim(in_dtlpassthruchar14),' ')),
      decode(nvl(od.dtlpassthruchar15,'x'),nvl(rtrim(in_dtlpassthruchar15),'x'),
        od.dtlpassthruchar15,nvl(rtrim(in_dtlpassthruchar15),' ')),
      decode(nvl(od.dtlpassthruchar16,'x'),nvl(rtrim(in_dtlpassthruchar16),'x'),
        od.dtlpassthruchar16,nvl(rtrim(in_dtlpassthruchar16),' ')),
      decode(nvl(od.dtlpassthruchar17,'x'),nvl(rtrim(in_dtlpassthruchar17),'x'),
        od.dtlpassthruchar17,nvl(rtrim(in_dtlpassthruchar17),' ')),
      decode(nvl(od.dtlpassthruchar18,'x'),nvl(rtrim(in_dtlpassthruchar18),'x'),
        od.dtlpassthruchar18,nvl(rtrim(in_dtlpassthruchar18),' ')),
      decode(nvl(od.dtlpassthruchar19,'x'),nvl(rtrim(in_dtlpassthruchar19),'x'),
        od.dtlpassthruchar19,nvl(rtrim(in_dtlpassthruchar19),' ')),
      decode(nvl(od.dtlpassthruchar20,'x'),nvl(rtrim(in_dtlpassthruchar20),'x'),
        od.dtlpassthruchar20,nvl(rtrim(in_dtlpassthruchar20),' ')),
      decode(nvl(od.dtlpassthrunum01,0),nvl(in_dtlpassthrunum01,0),
        od.dtlpassthrunum01,nvl(in_dtlpassthrunum01,0)),
      decode(nvl(od.dtlpassthrunum02,0),nvl(in_dtlpassthrunum02,0),
        od.dtlpassthrunum02,nvl(in_dtlpassthrunum02,0)),
      decode(nvl(od.dtlpassthrunum03,0),nvl(in_dtlpassthrunum03,0),
        od.dtlpassthrunum03,nvl(in_dtlpassthrunum03,0)),
      decode(nvl(od.dtlpassthrunum04,0),nvl(in_dtlpassthrunum04,0),
        od.dtlpassthrunum04,nvl(in_dtlpassthrunum04,0)),
      decode(nvl(od.dtlpassthrunum05,0),nvl(in_dtlpassthrunum05,0),
        od.dtlpassthrunum05,nvl(in_dtlpassthrunum05,0)),
      decode(nvl(od.dtlpassthrunum06,0),nvl(in_dtlpassthrunum06,0),
        od.dtlpassthrunum06,nvl(in_dtlpassthrunum06,0)),
      decode(nvl(od.dtlpassthrunum07,0),nvl(in_dtlpassthrunum07,0),
        od.dtlpassthrunum07,nvl(in_dtlpassthrunum07,0)),
      decode(nvl(od.dtlpassthrunum08,0),nvl(in_dtlpassthrunum08,0),
        od.dtlpassthrunum08,nvl(in_dtlpassthrunum08,0)),
      decode(nvl(od.dtlpassthrunum09,0),nvl(in_dtlpassthrunum09,0),
        od.dtlpassthrunum09,nvl(in_dtlpassthrunum09,0)),
      decode(nvl(od.dtlpassthrunum10,0),nvl(in_dtlpassthrunum10,0),
        od.dtlpassthrunum10,nvl(in_dtlpassthrunum10,0)),
      IMP_USERID, sysdate
     );
    update orderdtl
       set qtyentered = qtyentered + in_qtyentered,
           qtyorder = qtyorder + qtyBase,
           weightorder = weightorder
             + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
           cubeorder = cubeorder
             + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
           amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)), --prn 25133
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  end if;
elsif rtrim(in_func) = 'U' then
  if (olc.count != 0) and
     (chk.linenumber is not null) then
    update orderdtlline
       set qty = qtyBase,
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
       and linenumber = chk.linenumber;
    update orderdtl
       set qtyentered = qtyentered + in_qtyentered - ol.qty,
           qtyorder = qtyorder + qtyBase - ol.qty,
           weightorder = weightorder
             + (zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered)
             - (zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * ol.qty),
           cubeorder = cubeorder
             + (zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered)
             - (zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * ol.qty),
           amtorder = amtorder + (qtyBase - ol.qty) * zci.item_amt(custid,orderid,shipid,item,lotnumber), --prn 25133
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  else
    update orderdtl
       set uomentered = nvl(rtrim(in_uomentered),ci.baseuom),
           qtyentered = in_qtyentered,
           uom = strUOMBase,
           qtyorder = qtyBase,
           weightorder = zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
           cubeorder = zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
           amtorder = qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber), --prn 25133
           backorder = nvl(rtrim(in_backorder),backorder),
           allowsub = nvl(rtrim(in_allowsub),allowsub),
           qtytype = nvl(rtrim(in_qtytype),qtytype),
           invstatusind = nvl(rtrim(in_invstatusind),invstatusind),
           invstatus = nvl(rtrim(in_invstatus),invstatus),
           invclassind = nvl(rtrim(in_invclassind),invclassind),
           inventoryclass = nvl(rtrim(in_inventoryclass),inventoryclass),
           consigneesku = nvl(rtrim(in_consigneesku),consigneesku),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           dtlpassthruchar01 = nvl(rtrim(in_dtlpassthruchar01),dtlpassthruchar01),
           dtlpassthruchar02 = nvl(rtrim(in_dtlpassthruchar02),dtlpassthruchar02),
           dtlpassthruchar03 = nvl(rtrim(in_dtlpassthruchar03),dtlpassthruchar03),
           dtlpassthruchar04 = nvl(rtrim(in_dtlpassthruchar04),dtlpassthruchar04),
           dtlpassthruchar05 = nvl(rtrim(in_dtlpassthruchar05),dtlpassthruchar05),
           dtlpassthruchar06 = nvl(rtrim(in_dtlpassthruchar06),dtlpassthruchar06),
           dtlpassthruchar07 = nvl(rtrim(in_dtlpassthruchar07),dtlpassthruchar07),
           dtlpassthruchar08 = nvl(rtrim(in_dtlpassthruchar08),dtlpassthruchar08),
           dtlpassthruchar09 = nvl(rtrim(in_dtlpassthruchar09),dtlpassthruchar09),
           dtlpassthruchar10 = nvl(rtrim(in_dtlpassthruchar10),dtlpassthruchar10),
           dtlpassthruchar11 = nvl(rtrim(in_dtlpassthruchar11),dtlpassthruchar11),
           dtlpassthruchar12 = nvl(rtrim(in_dtlpassthruchar12),dtlpassthruchar12),
           dtlpassthruchar13 = nvl(rtrim(in_dtlpassthruchar13),dtlpassthruchar13),
           dtlpassthruchar14 = nvl(rtrim(in_dtlpassthruchar14),dtlpassthruchar14),
           dtlpassthruchar15 = nvl(rtrim(in_dtlpassthruchar15),dtlpassthruchar15),
           dtlpassthruchar16 = nvl(rtrim(in_dtlpassthruchar16),dtlpassthruchar16),
           dtlpassthruchar17 = nvl(rtrim(in_dtlpassthruchar17),dtlpassthruchar17),
           dtlpassthruchar18 = nvl(rtrim(in_dtlpassthruchar18),dtlpassthruchar18),
           dtlpassthruchar19 = nvl(rtrim(in_dtlpassthruchar19),dtlpassthruchar19),
           dtlpassthruchar20 = nvl(rtrim(in_dtlpassthruchar20),dtlpassthruchar20),
           dtlpassthrunum01 = nvl(decode(in_dtlpassthrunum01,0,null,in_dtlpassthrunum01),dtlpassthrunum01),
           dtlpassthrunum02 = nvl(decode(in_dtlpassthrunum02,0,null,in_dtlpassthrunum02),dtlpassthrunum02),
           dtlpassthrunum03 = nvl(decode(in_dtlpassthrunum03,0,null,in_dtlpassthrunum03),dtlpassthrunum03),
           dtlpassthrunum04 = nvl(decode(in_dtlpassthrunum04,0,null,in_dtlpassthrunum04),dtlpassthrunum04),
           dtlpassthrunum05 = nvl(decode(in_dtlpassthrunum05,0,null,in_dtlpassthrunum05),dtlpassthrunum05),
           dtlpassthrunum06 = nvl(decode(in_dtlpassthrunum06,0,null,in_dtlpassthrunum06),dtlpassthrunum06),
           dtlpassthrunum07 = nvl(decode(in_dtlpassthrunum07,0,null,in_dtlpassthrunum07),dtlpassthrunum07),
           dtlpassthrunum08 = nvl(decode(in_dtlpassthrunum08,0,null,in_dtlpassthrunum08),dtlpassthrunum08),
           dtlpassthrunum09 = nvl(decode(in_dtlpassthrunum09,0,null,in_dtlpassthrunum09),dtlpassthrunum09),
           dtlpassthrunum10 = nvl(decode(in_dtlpassthrunum10,0,null,in_dtlpassthrunum10),dtlpassthrunum10)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  end if;
elsif rtrim(in_func) = 'D' then -- delete function (do a cancel)
  update orderdtl
     set linestatus = 'X',
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
  delete from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
     and nvl(xdock,'N') = 'N';
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziol ' || sqlerrm;
  out_errorno := sqlcode;
end I55_import_order_line;

procedure I55_end_of_import
(in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor getCust is
  select custid,
         fromfacility
    from orderhdr
   where importfileid = rtrim(upper(in_importfileid));
gc getCust%rowtype;

cursor curCust(in_custid varchar2) is
  select outRejectBatchMap,
         outConfirmBatchMap,
         outStatusBatchMap,
         outShipSumBatchMap
    from customer
   where custid = in_custid;
cs curCust%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg(IMP_USERID, gc.fromfacility, rtrim(gc.custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
gc.fromfacility := 'ALL';

open getCust;
fetch getCust into gc;
if getCust%notfound then
  close getCust;
  out_msg := 'Cannot get customer code: ' || in_importfileid;
  out_errorno := -1;
  return;
end if;
close getCust;

open curCust(gc.custid);
fetch curCust into cs;
if curCust%notfound then
  close curCust;
  out_msg := 'Invalid customer code: ' || gc.custid;
  out_errorno := -2;
  return;
end if;
close curCust;

out_msg := 'End of import: ' ||gc.custid || ' ' || in_importfileid || ' '
  || in_userid;
order_msg('I');

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zim4I55end ' || sqlerrm;
  out_errorno := sqlcode;
end I55_end_of_import;

procedure end_of_import_release
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor getCust is
  select custid,
         fromfacility,
         tofacility
    from orderhdr
   where importfileid = rtrim(upper(in_importfileid));
gc getCust%rowtype;

cursor curCust(in_custid varchar2) is
  select outRejectBatchMap,
         outConfirmBatchMap,
         outStatusBatchMap,
         outShipSumBatchMap
    from customer
   where custid = in_custid;
cs curCust%rowtype;


procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg(IMP_USERID, gc.fromfacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
gc.fromfacility := 'ALL';



-- Remove orders from hold
    for crec in (select orderid, shipid
                   from orderhdr
                  where importfileid = rtrim(upper(in_importfileid)))
    loop

    -- Check here for special processing carrier determination
    --    cdat := zcus.init_cdata;

    --    cdat.orderid := crec.orderid;
    --    cdat.shipid := crec.shipid;
    --    zcus.execute('LDOP',cdat);

    --    if cdat.out_no != 0 then
    --        zut.prt('LDOP:'||cdat.out_char);
    --    end if;

        zimp.release_and_commit_order(crec.orderid, crec.shipid,
                out_errorno, out_msg);

    end loop;

    commit;


open getCust;
fetch getCust into gc;
if getCust%notfound then
  close getCust;
  out_msg := 'Cannot get customer code: ' || in_importfileid;
  out_errorno := -1;
  return;
end if;
close getCust;

open curCust(gc.custid);
fetch curCust into cs;
if curCust%notfound then
  close curCust;
  out_msg := 'Invalid customer code: ' || in_custid;
  out_errorno := -2;
  return;
end if;
close curCust;

out_msg := 'End of import: ' ||in_custid || ' ' || in_importfileid || ' '
  || in_userid;
order_msg('I');

zgp.pick_request('ENDIMP',nvl(gc.fromfacility,gc.tofacility),IMP_USERID,0,0,0,
  in_importfileid,gc.custid,0,null,null,'N',out_errorno,out_msg);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zim4eoir ' || sqlerrm;
  out_errorno := sqlcode;
end end_of_import_release;


end zimportproc4;
/
show error package body zimportproc4;
exit;
