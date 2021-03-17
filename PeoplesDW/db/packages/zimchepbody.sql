create or replace package body alps.zimportprocchep as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

function find_chep_sequence(in_custid varchar2, in_next_or_curr varchar2)
return integer
is

out_sequence integer;
begin

  begin
    select count(1)
      into out_sequence
      from user_objects
     where object_name = 'CHEPSEQ' || upper(in_custid);
  exception when others then
    out_sequence := 0;
  end;

  if out_sequence = 0 then
    execute immediate
      'create sequence ' || 'CHEPSEQ' || upper(in_custid) ||
      ' increment by 1 ' ||
       'start with 1 maxvalue 9999 minvalue 1 nocache cycle ';
  end if;

  if upper(in_next_or_curr) = 'NEXT' then
    execute immediate
      'select chepseq' || in_custid || '.nextval from dual'
      into out_sequence;
  else
    execute immediate
      'select chepseq' || in_custid || '.currval from dual'
      into out_sequence;
  end if;

  return out_sequence;

end;

procedure begin_chep_global_format
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

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
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss')
   order by loadno;

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and loadno = in_loadno;

cursor curCustomer is
  select custid,
         chep_communicator_code
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility(in_facility varchar2) is
  select facility,
         name,
         countrycode,
         chep_communicator_code
    from facility
   where facility = in_facility;
fa curFacility%rowtype;

strChepType pallethistory.pallettype%type;

cursor curPalletHistory (in_loadno number,in_facility varchar2,
                         in_orderid number,in_shipid number ) is
  select sum(nvl(outpallets,0)) as outpallets
    from pallethistory
   where loadno = in_loadno
     and custid = in_custid
     and facility = in_facility
     and orderid = in_orderid
     and shipid = in_shipid
     and pallettype = strChepType;
ph curPalletHistory%rowtype;

cursor curConsignee (in_shipto varchar2)
is
  select *
    from consignee
   where consignee = in_shipto;
co curConsignee%rowtype;

cursor curColumns(in_tablename varchar2) is
  select *
    from user_tab_columns
   where table_name = in_tablename
   order by table_name,column_id;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
viewcount integer;
strDebugYN char(1);
cntDtl integer;
sumQty integer;
dteTest date;
hdr chep_hdr_view%rowtype;
dtl chep_dtl_view%rowtype;
trl chep_trl_view%rowtype;
seq_number integer;
strseq_number varchar2(4);
strdetail_number varchar2(5);
strChepCustId varchar2(4);

procedure debugmsg(in_text varchar2)
as

cntChar integer;

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

exception when others then
  null;
end;

procedure add_chep_hdr_row is
begin

debugmsg('add chep hdr ' || hdr.dtl_count);
if hdr.dtl_count = 0 then
  return;
end if;
hdr.communicator_country := fa.countrycode;
hdr.communicator_code := cu.chep_communicator_code;
hdr.country_and_code := 'CHEP-US' || cu.chep_communicator_code;
hdr.file_date := sysdate;
hdr.seq_number := seq_number;
hdr.facility := fa.facility;
hdr.custid := in_custid;
execute immediate 'insert into CHEP_HDR_VIEW_' || strSuffix ||
' values (:LOADNO,:COMMUNICATOR_COUNTRY,:COMMUNICATOR_CODE,:FILE_DATE,' ||
' :DTL_COUNT,:SEQ_NUMBER, :COUNTRY_AND_CODE, :FACILITY, :CUSTID )'
using hdr.LOADNO,hdr.COMMUNICATOR_COUNTRY,hdr.COMMUNICATOR_CODE,hdr.FILE_DATE,
hdr.DTL_COUNT,hdr.SEQ_NUMBER,hdr.COUNTRY_AND_CODE,hdr.facility,hdr.custid;

end;

procedure add_chep_trl_row is
begin

debugmsg('add chep trl ' || trl.dtl_count);
if trl.dtl_count = 0 then
  return;
end if;

trl.loadno := hdr.loadno;

execute immediate 'insert into CHEP_TRL_VIEW_' || strSuffix ||
' values (:LOADNO,:DTL_COUNT,:QTY_SUM )'
using trl.LOADNO,trl.DTL_COUNT,trl.QTY_SUM;

end;

procedure add_chep_dtl_rows(oh orderhdr%rowtype) is
begin

debugmsg('add chep dtl');
ph := null;
open curPalletHistory(oh.loadno,oh.fromfacility,oh.orderid,oh.shipid);
fetch curPalletHistory into ph;
close curPalletHistory;
if nvl(ph.outpallets,0) = 0 then
  return;
end if;

if seq_number = 0 then
  seq_number := find_chep_sequence(in_custid,'NEXT');
  strseq_number := trim(to_char(seq_number));
  debugmsg('strseq_number is ' || strseq_number);
  while Length(trim(strseq_number)) < 4
  loop
    strseq_number := '0' || strseq_number;
  end loop;
  debugmsg('strseq_number is ' || strseq_number);
end if;

debugmsg('set dtl values');
dtl.loadno := hdr.loadno;
dtl.detail_number := dtl.detail_number + 1;
strdetail_number := trim(to_char(dtl.detail_number));
while Length(trim(strdetail_number)) < 5
loop
  strdetail_number := '0' || strdetail_number;
end loop;
dtl.INFORMER_FLAG := '1'; -- shipper
dtl.INFORMER_COUNTRY := fa.countrycode;
dtl.SENDER_CODE_QUALIFIER := 'SA';
dtl.SENDER_CODE := fa.chep_communicator_code;
dtl.RECEIVER_CODE_QUALIFIER := 'SA';
dtl.RECEIVER_CODE := oh.hdrpassthruchar07;
dtl.EQUIP_CODE_QUALIFIER := '90';
dtl.EQUIP_CODE := '4001';
dtl.DATE_OF_DISPATCH := oh.statusupdate;
dtl.DATE_OF_RECEIPT := null;
dtl.QTY := ph.outpallets;
dtl.REFERENCE_1 := strChepCustId ||
                   substr(strseq_number,1,4) ||
                   substr(strdetail_number,1,5);
debugmsg('reference1 ' || dtl.reference_1);
dtl.REFERENCE_2 := oh.reference;
debugmsg('reference2 ' || oh.reference);
dtl.REFERENCE_3 := oh.hdrpassthruchar03;
debugmsg('reference3 ' || oh.hdrpassthruchar03);
dtl.TRANSPORT_RESPONSIBILITY := '2';
debugmsg('transport resp');
dtl.SYS_PARM_1 := '';
dtl.SYS_PARM_2 := '';
dtl.SYS_PARM_3 := '';
dtl.SPECIAL_PROCESSING_CODE := '';
dtl.FLOW_CODE := '';
if oh.shipto is not null then
  co := null;
  open curConsignee(oh.shipto);
  fetch curConsignee into co;
  close curConsignee;
  debugmsg('con name');
  dtl.COUNTER_PART_NAME := co.name;
  debugmsg('con addr1');
  dtl.COUNTER_PART_ADDR := co.addr1;
  debugmsg('con city');
  dtl.COUNTER_PART_CITY := co.city;
  debugmsg('con postal');
  dtl.COUNTER_PART_POSTAL_CODE := co.postalcode;
  debugmsg('con state');
  dtl.COUNTER_PART_STATE := co.state;
  debugmsg('con country');
  dtl.COUNTER_PART_COUNTRY := co.countrycode;
else
  debugmsg('st name');
  dtl.COUNTER_PART_NAME := oh.shiptoname;
  debugmsg('st addr');
  dtl.COUNTER_PART_ADDR := oh.shiptoaddr1;
  debugmsg('st city');
  dtl.COUNTER_PART_CITY := oh.shiptocity;
  debugmsg('st postal');
  dtl.COUNTER_PART_POSTAL_CODE := oh.shiptopostalcode;
  debugmsg('st state');
  dtl.COUNTER_PART_STATE := oh.shiptostate;
  debugmsg('st country');
  dtl.COUNTER_PART_COUNTRY := oh.shiptocountrycode;
end if;
dtl.THIRD_PARTY_CODE_QUALIFIER := '';
dtl.THIRD_PARTY_CODE := '';

if strDebugYN = 'Y' then
zut.prt('LOADNO ' || dtl.LOADNO || length(dtl.LOADNO));
zut.prt('DETAIL_NUMBER ' || dtl.DETAIL_NUMBER || length(dtl.DETAIL_NUMBER));
zut.prt('INFORMER_FLAG ' || dtl.INFORMER_FLAG || length(dtl.INFORMER_FLAG));
zut.prt('INFORMER_COUNTRY ' || dtl.INFORMER_COUNTRY || length(dtl.INFORMER_COUNTRY));
zut.prt('SENDER_CODE_QUALIFIER ' || dtl.SENDER_CODE_QUALIFIER || length(dtl.SENDER_CODE_QUALIFIER));
zut.prt('SENDER_CODE ' || dtl.SENDER_CODE || length(dtl.SENDER_CODE));
zut.prt('RECEIVER_CODE_QUALIFIER ' || dtl.RECEIVER_CODE_QUALIFIER || length(dtl.RECEIVER_CODE_QUALIFIER));
zut.prt('RECEIVER_CODE ' || dtl.RECEIVER_CODE || length(dtl.RECEIVER_CODE));
zut.prt('EQUIP_CODE_QUALIFIER ' || dtl.EQUIP_CODE_QUALIFIER || length(dtl.EQUIP_CODE_QUALIFIER));
zut.prt('EQUIP_CODE ' || dtl.EQUIP_CODE || length(dtl.EQUIP_CODE));
zut.prt('DATE_OF_DISPATCH ' || dtl.DATE_OF_DISPATCH || length(dtl.DATE_OF_DISPATCH));
zut.prt('DATE_OF_RECEIPT ' || dtl.DATE_OF_RECEIPT || length(dtl.DATE_OF_RECEIPT));
zut.prt('QTY ' || dtl.QTY || length(dtl.QTY));
zut.prt('REFERENCE_1 ' || dtl.REFERENCE_1 || length(dtl.REFERENCE_1));
zut.prt('REFERENCE_2 ' || dtl.REFERENCE_2 || length(dtl.REFERENCE_2));
zut.prt('REFERENCE_3 ' || dtl.REFERENCE_3 || length(dtl.REFERENCE_3));
zut.prt('TRANSPORT_RESPONSIBILITY ' || dtl.TRANSPORT_RESPONSIBILITY || length(dtl.TRANSPORT_RESPONSIBILITY));
zut.prt('SYS_PARM_1 ' || dtl.SYS_PARM_1 || length(dtl.SYS_PARM_1));
zut.prt('SYS_PARM_2 ' || dtl.SYS_PARM_2 || length(dtl.SYS_PARM_2));
zut.prt('SYS_PARM_3 ' || dtl.SYS_PARM_3 || length(dtl.SYS_PARM_3));
zut.prt('SPECIAL_PROCESSING_CODE ' || dtl.SPECIAL_PROCESSING_CODE || length(dtl.SPECIAL_PROCESSING_CODE));
zut.prt('FLOW_CODE ' || dtl.FLOW_CODE || length(dtl.FLOW_CODE));
zut.prt('COUNTER_PART_NAME ' || dtl.COUNTER_PART_NAME || length(dtl.COUNTER_PART_NAME));
zut.prt('COUNTER_PART_ADDR ' || dtl.COUNTER_PART_ADDR || length(dtl.COUNTER_PART_ADDR));
zut.prt('COUNTER_PART_CITY ' || dtl.COUNTER_PART_CITY || length(dtl.COUNTER_PART_CITY));
zut.prt('COUNTER_PART_POSTAL_CODE ' || dtl.COUNTER_PART_POSTAL_CODE || length(dtl.COUNTER_PART_POSTAL_CODE));
zut.prt('COUNTER_PART_STATE ' || dtl.COUNTER_PART_STATE || length(dtl.COUNTER_PART_STATE));
zut.prt('COUNTER_PART_COUNTRY ' || dtl.COUNTER_PART_COUNTRY || length(dtl.COUNTER_PART_COUNTRY));
zut.prt('THIRD_PARTY_CODE_QUALIFIER ' || dtl.THIRD_PARTY_CODE_QUALIFIER || length(dtl.THIRD_PARTY_CODE_QUALIFIER));
zut.prt('THIRD_PARTY_CODE ' || dtl.THIRD_PARTY_CODE || length(dtl.THIRD_PARTY_CODE));
end if;


debugmsg('insert dtl');
execute immediate 'insert into CHEP_DTL_VIEW_' || strSuffix ||
' values (:LOADNO,:DETAIL_NUMBER,:INFORMER_FLAG,:INFORMER_COUNTRY,' ||
' :SENDER_CODE_QUALIFIER,:SENDER_CODE,:RECEIVER_CODE_QUALIFIER,:RECEIVER_CODE,' ||
' :EQUIP_CODE_QUALIFIER,:EQUIP_CODE,:DATE_OF_DISPATCH,:DATE_OF_RECEIPT,' ||
' :QTY,:REFERENCE_1,:REFERENCE_2,:REFERENCE_3,:TRANSPORT_RESPONSIBILITY,' ||
' :SYS_PARM_1,:SYS_PARM_2,:SYS_PARM_3,:SPECIAL_PROCESSING_CODE,:FLOW_CODE,' ||
' :COUNTER_PART_NAME,:COUNTER_PART_ADDR,:COUNTER_PART_CITY,:COUNTER_PART_POSTAL_CODE,' ||
' :COUNTER_PART_STATE,:COUNTER_PART_COUNTRY,:THIRD_PARTY_CODE_QUALIFIER,' ||
' :THIRD_PARTY_CODE )'
using dtl.LOADNO,dtl.DETAIL_NUMBER,dtl.INFORMER_FLAG,dtl.INFORMER_COUNTRY,
dtl.SENDER_CODE_QUALIFIER,dtl.SENDER_CODE,dtl.RECEIVER_CODE_QUALIFIER,
dtl.RECEIVER_CODE,dtl.EQUIP_CODE_QUALIFIER,dtl.EQUIP_CODE,dtl.DATE_OF_DISPATCH,
dtl.DATE_OF_RECEIPT,dtl.QTY,dtl.REFERENCE_1,dtl.REFERENCE_2,dtl.REFERENCE_3,
dtl.TRANSPORT_RESPONSIBILITY,dtl.SYS_PARM_1,dtl.SYS_PARM_2,dtl.SYS_PARM_3,
dtl.SPECIAL_PROCESSING_CODE,dtl.FLOW_CODE,dtl.COUNTER_PART_NAME,dtl.COUNTER_PART_ADDR,
dtl.COUNTER_PART_CITY,dtl.COUNTER_PART_POSTAL_CODE,dtl.COUNTER_PART_STATE,
dtl.COUNTER_PART_COUNTRY,dtl.THIRD_PARTY_CODE_QUALIFIER,dtl.THIRD_PARTY_CODE;

debugmsg('accum counts');
hdr.dtl_count := hdr.dtl_count + 1;
trl.dtl_count := trl.dtl_count + 1;
trl.qty_sum := trl.qty_sum + ph.outpallets;

end;

procedure process_chep_orders(oh orderhdr%rowtype) is
begin
  debugmsg('process_chep_orders');
  if oh.loadno <> hdr.loadno then
    if hdr.loadno = -1 then
      strChepCustId := substr(zci.default_value('CHEPCUSTID'),1,4);
      hdr.dtl_count := 0;
      trl.dtl_count := 0;
      trl.qty_sum := 0;
      dtl.detail_number := 0;
    end if;
    fa := null;
    open curFacility(oh.fromfacility);
    fetch curFacility into fa;
    close curFacility;
    hdr.loadno := oh.loadno;
  end if;
  add_chep_dtl_rows(oh);
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

debugmsg('find view suffix');
viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'CHEP_HDR_VIEW_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

debugmsg('get customer');
cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;


debugmsg('create chep hdr');
cmdSql := 'create table chep_hdr_view_' || strSuffix ||
' (LOADNO NUMBER,COMMUNICATOR_COUNTRY CHAR(3),COMMUNICATOR_CODE CHAR(18),' ||
' FILE_DATE DATE,DTL_COUNT NUMBER,SEQ_NUMBER NUMBER, COUNTRY_AND_CODE VARCHAR2(32),'||
' FACILITY CHAR(3), CUSTID CHAR(10) )';
debugmsg(cmdSql);
execute immediate cmdSql;

debugmsg('create table CHEP_DTL_VIEW_' || strSuffix);
cmdSql := 'create table CHEP_DTL_VIEW_' || strSuffix ||
' (LOADNO NUMBER,DETAIL_NUMBER NUMBER,INFORMER_FLAG CHAR(1),INFORMER_COUNTRY CHAR(3),' ||
' SENDER_CODE_QUALIFIER CHAR(2),SENDER_CODE CHAR(35),RECEIVER_CODE_QUALIFIER CHAR(2),' ||
' RECEIVER_CODE CHAR(35),EQUIP_CODE_QUALIFIER CHAR(2),EQUIP_CODE CHAR(35),' ||
' DATE_OF_DISPATCH DATE,DATE_OF_RECEIPT DATE,QTY NUMBER,REFERENCE_1 CHAR(36),' ||
' REFERENCE_2 CHAR(36),REFERENCE_3 CHAR(36),TRANSPORT_RESPONSIBILITY CHAR(1),' ||
' SYS_PARM_1 CHAR(1),SYS_PARM_2 CHAR(1),SYS_PARM_3 CHAR(6),SPECIAL_PROCESSING_CODE CHAR(3),' ||
' FLOW_CODE CHAR(1),COUNTER_PART_NAME CHAR(40),COUNTER_PART_ADDR CHAR(60),' ||
' COUNTER_PART_CITY CHAR(40),COUNTER_PART_POSTAL_CODE CHAR(30),COUNTER_PART_STATE CHAR(35),' ||
' COUNTER_PART_COUNTRY CHAR(3),THIRD_PARTY_CODE_QUALIFIER CHAR(2),' ||
' THIRD_PARTY_CODE CHAR(35) )';
debugmsg(cmdSql);
execute immediate cmdSql;

debugmsg('create table CHEP_TRL_VIEW_' || strSuffix);
cmdSql := 'create table CHEP_TRL_VIEW_' || strSuffix ||
' (LOADNO NUMBER,DTL_COUNT NUMBER,QTY_SUM NUMBER )';
debugmsg(cmdSql);
execute immediate cmdSql;

strChepType := trim(substr(zci.default_value('PALLETTYPECHEP'),1,12));
hdr.loadno := -1;
seq_number := 0;

if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    process_chep_orders(oh);
  end loop;
elsif in_loadno != 0 then  for oh in curOrderHdrByLoad
  loop
    process_chep_orders(oh);
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
    process_chep_orders(oh);
  end loop;
end if;

add_chep_hdr_row;
add_chep_trl_row;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimchepb ' || sqlerrm;
  out_errorno := sqlcode;
end begin_chep_global_format;

procedure end_chep_global_format
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'drop table chep_dtl_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table chep_trl_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table chep_hdr_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimchepe ' || sqlerrm;
  out_errorno := sqlcode;
end end_chep_global_format;

procedure begin_dre_chep_global_format
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

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
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss')
   order by loadno;

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and loadno = in_loadno;

cursor curCustomer is
  select custid,
         chep_communicator_code
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility(in_facility varchar2) is
  select facility,
         name,
         countrycode,
         chep_communicator_code
    from facility
   where facility = in_facility;
fa curFacility%rowtype;

strChepType pallethistory.pallettype%type;

cursor curPalletHistory (in_loadno number,in_facility varchar2,
                         in_orderid number,in_shipid number ) is
  select sum(nvl(outpallets,0)) as outpallets
    from pallethistory
   where loadno = in_loadno
     and custid = in_custid
     and facility = in_facility
     and orderid = in_orderid
     and shipid = in_shipid
     and pallettype = strChepType;
ph curPalletHistory%rowtype;

cursor curConsignee (in_shipto varchar2)
is
  select *
    from consignee
   where consignee = in_shipto;
co curConsignee%rowtype;

cursor curColumns(in_tablename varchar2) is
  select *
    from user_tab_columns
   where table_name = in_tablename
   order by table_name,column_id;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
viewcount integer;
strDebugYN char(1);
cntDtl integer;
sumQty integer;
dteTest date;
hdr chep_hdr_view%rowtype;
dtl chep_dtl_view%rowtype;
trl chep_trl_view%rowtype;
seq_number integer;
strseq_number varchar2(4);
strdetail_number varchar2(5);
strChepCustId varchar2(4);

procedure debugmsg(in_text varchar2)
as

cntChar integer;

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

exception when others then
  null;
end;

procedure add_chep_hdr_row is
begin

debugmsg('add chep hdr ' || hdr.dtl_count);
if hdr.dtl_count = 0 then
  return;
end if;
hdr.communicator_country := fa.countrycode;
hdr.communicator_code := cu.chep_communicator_code;
hdr.country_and_code := 'CHEP-US' || substr(cu.chep_communicator_code,1,10);
hdr.file_date := sysdate;
hdr.seq_number := seq_number;
hdr.facility := fa.facility;
hdr.custid := in_custid;
execute immediate 'insert into CHEP_HDR_VIEW_' || strSuffix ||
' values (:LOADNO,:COMMUNICATOR_COUNTRY,:COMMUNICATOR_CODE,:FILE_DATE,' ||
' :DTL_COUNT,:SEQ_NUMBER, :COUNTRY_AND_CODE, :FACILITY, :CUSTID )'
using hdr.LOADNO,hdr.COMMUNICATOR_COUNTRY,hdr.COMMUNICATOR_CODE,hdr.FILE_DATE,
hdr.DTL_COUNT,hdr.SEQ_NUMBER,hdr.COUNTRY_AND_CODE,hdr.facility,hdr.custid;

end;

procedure add_chep_trl_row is
begin

debugmsg('add chep trl ' || trl.dtl_count);
if trl.dtl_count = 0 then
  return;
end if;

trl.loadno := hdr.loadno;

execute immediate 'insert into CHEP_TRL_VIEW_' || strSuffix ||
' values (:LOADNO,:DTL_COUNT,:QTY_SUM )'
using trl.LOADNO,trl.DTL_COUNT,trl.QTY_SUM;

end;

procedure add_chep_dtl_rows(oh orderhdr%rowtype) is
begin

debugmsg('add chep dtl');
ph := null;
open curPalletHistory(oh.loadno,oh.fromfacility,oh.orderid,oh.shipid);
fetch curPalletHistory into ph;
close curPalletHistory;
if nvl(ph.outpallets,0) = 0 then
  return;
end if;

if seq_number = 0 then
  seq_number := find_chep_sequence(in_custid,'NEXT');
  strseq_number := trim(to_char(seq_number));
  debugmsg('strseq_number is ' || strseq_number);
  while Length(trim(strseq_number)) < 4
  loop
    strseq_number := '0' || strseq_number;
  end loop;
  debugmsg('strseq_number is ' || strseq_number);
end if;

debugmsg('set dtl values');
dtl.loadno := hdr.loadno;
dtl.detail_number := dtl.detail_number + 1;
strdetail_number := trim(to_char(dtl.detail_number));
while Length(trim(strdetail_number)) < 5
loop
  strdetail_number := '0' || strdetail_number;
end loop;
dtl.INFORMER_FLAG := '1'; -- shipper
dtl.INFORMER_COUNTRY := fa.countrycode;
dtl.SENDER_CODE_QUALIFIER := 'SA';
dtl.SENDER_CODE := substr(fa.chep_communicator_code,1,13);
dtl.RECEIVER_CODE_QUALIFIER := 'SA';
if length(nvl(oh.hdrpassthruchar05,'')) > 0 then
  dtl.RECEIVER_CODE := 'Z'||substr(oh.hdrpassthruchar05,1,12);
else
	dtl.RECEIVER_CODE := ' ';
end if;
dtl.EQUIP_CODE_QUALIFIER := '90';
dtl.EQUIP_CODE := '4001';
dtl.DATE_OF_DISPATCH := oh.statusupdate;
dtl.DATE_OF_RECEIPT := null;
dtl.QTY := ph.outpallets;
dtl.REFERENCE_1 := strChepCustId ||
                   substr(strseq_number,1,4) ||
                   substr(strdetail_number,1,5);
debugmsg('reference1 ' || dtl.reference_1);
dtl.REFERENCE_2 := substr(oh.reference,1,13);
debugmsg('reference2 ' || oh.reference);
dtl.REFERENCE_3 := substr(oh.po,1,13);
debugmsg('reference3 ' || substr(oh.po,1,13));
dtl.TRANSPORT_RESPONSIBILITY := '2';
debugmsg('transport resp');
dtl.SYS_PARM_1 := '';
dtl.SYS_PARM_2 := '';
dtl.SYS_PARM_3 := '';
dtl.SPECIAL_PROCESSING_CODE := '';
dtl.FLOW_CODE := '';
if oh.shipto is not null then
  co := null;
  open curConsignee(oh.shipto);
  fetch curConsignee into co;
  close curConsignee;
  debugmsg('con name');
  dtl.COUNTER_PART_NAME := co.name;
  debugmsg('con addr1');
  dtl.COUNTER_PART_ADDR := co.addr1;
  debugmsg('con city');
  dtl.COUNTER_PART_CITY := co.city;
  debugmsg('con postal');
  dtl.COUNTER_PART_POSTAL_CODE := co.postalcode;
  debugmsg('con state');
  dtl.COUNTER_PART_STATE := co.state;
  debugmsg('con country');
  dtl.COUNTER_PART_COUNTRY := co.countrycode;
else
  debugmsg('st name');
  dtl.COUNTER_PART_NAME := oh.shiptoname;
  debugmsg('st addr');
  dtl.COUNTER_PART_ADDR := oh.shiptoaddr1;
  debugmsg('st city');
  dtl.COUNTER_PART_CITY := oh.shiptocity;
  debugmsg('st postal');
  dtl.COUNTER_PART_POSTAL_CODE := oh.shiptopostalcode;
  debugmsg('st state');
  dtl.COUNTER_PART_STATE := oh.shiptostate;
  debugmsg('st country');
  dtl.COUNTER_PART_COUNTRY := oh.shiptocountrycode;
end if;
dtl.THIRD_PARTY_CODE_QUALIFIER := '';
dtl.THIRD_PARTY_CODE := '';

if strDebugYN = 'Y' then
zut.prt('LOADNO ' || dtl.LOADNO || length(dtl.LOADNO));
zut.prt('DETAIL_NUMBER ' || dtl.DETAIL_NUMBER || length(dtl.DETAIL_NUMBER));
zut.prt('INFORMER_FLAG ' || dtl.INFORMER_FLAG || length(dtl.INFORMER_FLAG));
zut.prt('INFORMER_COUNTRY ' || dtl.INFORMER_COUNTRY || length(dtl.INFORMER_COUNTRY));
zut.prt('SENDER_CODE_QUALIFIER ' || dtl.SENDER_CODE_QUALIFIER || length(dtl.SENDER_CODE_QUALIFIER));
zut.prt('SENDER_CODE ' || dtl.SENDER_CODE || length(dtl.SENDER_CODE));
zut.prt('RECEIVER_CODE_QUALIFIER ' || dtl.RECEIVER_CODE_QUALIFIER || length(dtl.RECEIVER_CODE_QUALIFIER));
zut.prt('RECEIVER_CODE ' || dtl.RECEIVER_CODE || length(dtl.RECEIVER_CODE));
zut.prt('EQUIP_CODE_QUALIFIER ' || dtl.EQUIP_CODE_QUALIFIER || length(dtl.EQUIP_CODE_QUALIFIER));
zut.prt('EQUIP_CODE ' || dtl.EQUIP_CODE || length(dtl.EQUIP_CODE));
zut.prt('DATE_OF_DISPATCH ' || dtl.DATE_OF_DISPATCH || length(dtl.DATE_OF_DISPATCH));
zut.prt('DATE_OF_RECEIPT ' || dtl.DATE_OF_RECEIPT || length(dtl.DATE_OF_RECEIPT));
zut.prt('QTY ' || dtl.QTY || length(dtl.QTY));
zut.prt('REFERENCE_1 ' || dtl.REFERENCE_1 || length(dtl.REFERENCE_1));
zut.prt('REFERENCE_2 ' || dtl.REFERENCE_2 || length(dtl.REFERENCE_2));
zut.prt('REFERENCE_3 ' || dtl.REFERENCE_3 || length(dtl.REFERENCE_3));
zut.prt('TRANSPORT_RESPONSIBILITY ' || dtl.TRANSPORT_RESPONSIBILITY || length(dtl.TRANSPORT_RESPONSIBILITY));
zut.prt('SYS_PARM_1 ' || dtl.SYS_PARM_1 || length(dtl.SYS_PARM_1));
zut.prt('SYS_PARM_2 ' || dtl.SYS_PARM_2 || length(dtl.SYS_PARM_2));
zut.prt('SYS_PARM_3 ' || dtl.SYS_PARM_3 || length(dtl.SYS_PARM_3));
zut.prt('SPECIAL_PROCESSING_CODE ' || dtl.SPECIAL_PROCESSING_CODE || length(dtl.SPECIAL_PROCESSING_CODE));
zut.prt('FLOW_CODE ' || dtl.FLOW_CODE || length(dtl.FLOW_CODE));
zut.prt('COUNTER_PART_NAME ' || dtl.COUNTER_PART_NAME || length(dtl.COUNTER_PART_NAME));
zut.prt('COUNTER_PART_ADDR ' || dtl.COUNTER_PART_ADDR || length(dtl.COUNTER_PART_ADDR));
zut.prt('COUNTER_PART_CITY ' || dtl.COUNTER_PART_CITY || length(dtl.COUNTER_PART_CITY));
zut.prt('COUNTER_PART_POSTAL_CODE ' || dtl.COUNTER_PART_POSTAL_CODE || length(dtl.COUNTER_PART_POSTAL_CODE));
zut.prt('COUNTER_PART_STATE ' || dtl.COUNTER_PART_STATE || length(dtl.COUNTER_PART_STATE));
zut.prt('COUNTER_PART_COUNTRY ' || dtl.COUNTER_PART_COUNTRY || length(dtl.COUNTER_PART_COUNTRY));
zut.prt('THIRD_PARTY_CODE_QUALIFIER ' || dtl.THIRD_PARTY_CODE_QUALIFIER || length(dtl.THIRD_PARTY_CODE_QUALIFIER));
zut.prt('THIRD_PARTY_CODE ' || dtl.THIRD_PARTY_CODE || length(dtl.THIRD_PARTY_CODE));
end if;


debugmsg('insert dtl');
execute immediate 'insert into CHEP_DTL_VIEW_' || strSuffix ||
' values (:LOADNO,:DETAIL_NUMBER,:INFORMER_FLAG,:INFORMER_COUNTRY,' ||
' :SENDER_CODE_QUALIFIER,:SENDER_CODE,:RECEIVER_CODE_QUALIFIER,:RECEIVER_CODE,' ||
' :EQUIP_CODE_QUALIFIER,:EQUIP_CODE,:DATE_OF_DISPATCH,:DATE_OF_RECEIPT,' ||
' :QTY,:REFERENCE_1,:REFERENCE_2,:REFERENCE_3,:TRANSPORT_RESPONSIBILITY,' ||
' :SYS_PARM_1,:SYS_PARM_2,:SYS_PARM_3,:SPECIAL_PROCESSING_CODE,:FLOW_CODE,' ||
' :COUNTER_PART_NAME,:COUNTER_PART_ADDR,:COUNTER_PART_CITY,:COUNTER_PART_POSTAL_CODE,' ||
' :COUNTER_PART_STATE,:COUNTER_PART_COUNTRY,:THIRD_PARTY_CODE_QUALIFIER,' ||
' :THIRD_PARTY_CODE )'
using dtl.LOADNO,dtl.DETAIL_NUMBER,dtl.INFORMER_FLAG,dtl.INFORMER_COUNTRY,
dtl.SENDER_CODE_QUALIFIER,dtl.SENDER_CODE,dtl.RECEIVER_CODE_QUALIFIER,
dtl.RECEIVER_CODE,dtl.EQUIP_CODE_QUALIFIER,dtl.EQUIP_CODE,dtl.DATE_OF_DISPATCH,
dtl.DATE_OF_RECEIPT,dtl.QTY,dtl.REFERENCE_1,dtl.REFERENCE_2,dtl.REFERENCE_3,
dtl.TRANSPORT_RESPONSIBILITY,dtl.SYS_PARM_1,dtl.SYS_PARM_2,dtl.SYS_PARM_3,
dtl.SPECIAL_PROCESSING_CODE,dtl.FLOW_CODE,dtl.COUNTER_PART_NAME,dtl.COUNTER_PART_ADDR,
dtl.COUNTER_PART_CITY,dtl.COUNTER_PART_POSTAL_CODE,dtl.COUNTER_PART_STATE,
dtl.COUNTER_PART_COUNTRY,dtl.THIRD_PARTY_CODE_QUALIFIER,dtl.THIRD_PARTY_CODE;

debugmsg('accum counts');
hdr.dtl_count := hdr.dtl_count + 1;
trl.dtl_count := trl.dtl_count + 1;
trl.qty_sum := trl.qty_sum + ph.outpallets;

end;

procedure process_chep_orders(oh orderhdr%rowtype) is
begin
  debugmsg('process_chep_orders');
  if oh.loadno <> hdr.loadno then
    if hdr.loadno = -1 then
      strChepCustId := substr(zci.default_value('CHEPCUSTID'),1,4);
      hdr.dtl_count := 0;
      trl.dtl_count := 0;
      trl.qty_sum := 0;
      dtl.detail_number := 0;
    end if;
    fa := null;
    open curFacility(oh.fromfacility);
    fetch curFacility into fa;
    close curFacility;
    hdr.loadno := oh.loadno;
  end if;
  add_chep_dtl_rows(oh);
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

debugmsg('find view suffix');
viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'CHEP_HDR_VIEW_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

debugmsg('get customer');
cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;


debugmsg('create chep hdr');
cmdSql := 'create table chep_hdr_view_' || strSuffix ||
' (LOADNO NUMBER,COMMUNICATOR_COUNTRY CHAR(3),COMMUNICATOR_CODE CHAR(18),' ||
' FILE_DATE DATE,DTL_COUNT NUMBER,SEQ_NUMBER NUMBER, COUNTRY_AND_CODE VARCHAR2(32),'||
' FACILITY CHAR(3), CUSTID CHAR(10) )';
debugmsg(cmdSql);
execute immediate cmdSql;

debugmsg('create table CHEP_DTL_VIEW_' || strSuffix);
cmdSql := 'create table CHEP_DTL_VIEW_' || strSuffix ||
' (LOADNO NUMBER,DETAIL_NUMBER NUMBER,INFORMER_FLAG CHAR(1),INFORMER_COUNTRY CHAR(3),' ||
' SENDER_CODE_QUALIFIER CHAR(2),SENDER_CODE CHAR(35),RECEIVER_CODE_QUALIFIER CHAR(2),' ||
' RECEIVER_CODE CHAR(35),EQUIP_CODE_QUALIFIER CHAR(2),EQUIP_CODE CHAR(35),' ||
' DATE_OF_DISPATCH DATE,DATE_OF_RECEIPT DATE,QTY NUMBER,REFERENCE_1 CHAR(36),' ||
' REFERENCE_2 CHAR(36),REFERENCE_3 CHAR(36),TRANSPORT_RESPONSIBILITY CHAR(1),' ||
' SYS_PARM_1 CHAR(1),SYS_PARM_2 CHAR(1),SYS_PARM_3 CHAR(6),SPECIAL_PROCESSING_CODE CHAR(3),' ||
' FLOW_CODE CHAR(1),COUNTER_PART_NAME CHAR(40),COUNTER_PART_ADDR CHAR(60),' ||
' COUNTER_PART_CITY CHAR(40),COUNTER_PART_POSTAL_CODE CHAR(30),COUNTER_PART_STATE CHAR(35),' ||
' COUNTER_PART_COUNTRY CHAR(3),THIRD_PARTY_CODE_QUALIFIER CHAR(2),' ||
' THIRD_PARTY_CODE CHAR(35) )';
debugmsg(cmdSql);
execute immediate cmdSql;

debugmsg('create table CHEP_TRL_VIEW_' || strSuffix);
cmdSql := 'create table CHEP_TRL_VIEW_' || strSuffix ||
' (LOADNO NUMBER,DTL_COUNT NUMBER,QTY_SUM NUMBER )';
debugmsg(cmdSql);
execute immediate cmdSql;

strChepType := trim(substr(zci.default_value('PALLETTYPECHEP'),1,12));
hdr.loadno := -1;
seq_number := 0;

if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    process_chep_orders(oh);
  end loop;
elsif in_loadno != 0 then  for oh in curOrderHdrByLoad
  loop
    process_chep_orders(oh);
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
    process_chep_orders(oh);
  end loop;
end if;

add_chep_hdr_row;
add_chep_trl_row;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimchepb ' || sqlerrm;
  out_errorno := sqlcode;
end begin_dre_chep_global_format;

procedure begin_dre_chep2_global_format
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

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
     and statusupdate <  to_date(in_enddatestr,'yyyymmddhh24miss')
   order by loadno;

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and orderstatus = '9'
     and loadno = in_loadno;

cursor curCustomer is
  select custid,
         chep_communicator_code
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility(in_facility varchar2) is
  select facility,
         name,
         countrycode,
         chep_communicator_code
    from facility
   where facility = in_facility;
fa curFacility%rowtype;

strChepType pallethistory.pallettype%type;

cursor curPalletHistory (in_loadno number,in_facility varchar2,
                         in_orderid number,in_shipid number ) is
  select sum(nvl(outpallets,0)) as outpallets
    from pallethistory
   where loadno = in_loadno
     and custid = in_custid
     and facility = in_facility
     and orderid = in_orderid
     and shipid = in_shipid
     and pallettype = strChepType;
ph curPalletHistory%rowtype;

cursor curConsignee (in_shipto varchar2)
is
  select *
    from consignee
   where consignee = in_shipto;
co curConsignee%rowtype;

cursor curColumns(in_tablename varchar2) is
  select *
    from user_tab_columns
   where table_name = in_tablename
   order by table_name,column_id;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
viewcount integer;
strDebugYN char(1);
cntDtl integer;
sumQty integer;
dteTest date;
hdr chep_hdr_view%rowtype;
dtl chep_dtl_view%rowtype;
trl chep_trl_view%rowtype;
seq_number integer;
strseq_number varchar2(4);
strdetail_number varchar2(5);
strChepCustId varchar2(4);

procedure debugmsg(in_text varchar2)
as

cntChar integer;

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

exception when others then
  null;
end;

procedure add_chep_hdr_row is
begin

debugmsg('add chep hdr ' || hdr.dtl_count);
if hdr.dtl_count = 0 then
  return;
end if;
hdr.communicator_country := fa.countrycode;
hdr.communicator_code := cu.chep_communicator_code;
hdr.country_and_code := 'CHEP-US' || substr(cu.chep_communicator_code,1,10);
hdr.file_date := sysdate;
hdr.seq_number := seq_number;
hdr.facility := fa.facility;
hdr.custid := in_custid;
execute immediate 'insert into CHEP_HDR_VIEW_' || strSuffix ||
' values (:LOADNO,:COMMUNICATOR_COUNTRY,:COMMUNICATOR_CODE,:FILE_DATE,' ||
' :DTL_COUNT,:SEQ_NUMBER, :COUNTRY_AND_CODE, :FACILITY, :CUSTID )'
using hdr.LOADNO,hdr.COMMUNICATOR_COUNTRY,hdr.COMMUNICATOR_CODE,hdr.FILE_DATE,
hdr.DTL_COUNT,hdr.SEQ_NUMBER,hdr.COUNTRY_AND_CODE,hdr.facility,hdr.custid;

end;

procedure add_chep_trl_row is
begin

debugmsg('add chep trl ' || trl.dtl_count);
if trl.dtl_count = 0 then
  return;
end if;

trl.loadno := hdr.loadno;

execute immediate 'insert into CHEP_TRL_VIEW_' || strSuffix ||
' values (:LOADNO,:DTL_COUNT,:QTY_SUM )'
using trl.LOADNO,trl.DTL_COUNT,trl.QTY_SUM;

end;

procedure add_chep_dtl_rows(oh orderhdr%rowtype) is
begin

debugmsg('add chep dtl');
ph := null;
open curPalletHistory(oh.loadno,oh.fromfacility,oh.orderid,oh.shipid);
fetch curPalletHistory into ph;
close curPalletHistory;
if nvl(ph.outpallets,0) = 0 then
  return;
end if;

if seq_number = 0 then
  seq_number := find_chep_sequence(in_custid,'NEXT');
  strseq_number := trim(to_char(seq_number));
  debugmsg('strseq_number is ' || strseq_number);
  while Length(trim(strseq_number)) < 4
  loop
    strseq_number := '0' || strseq_number;
  end loop;
  debugmsg('strseq_number is ' || strseq_number);
end if;

debugmsg('set dtl values');
dtl.loadno := hdr.loadno;
dtl.detail_number := dtl.detail_number + 1;
strdetail_number := trim(to_char(dtl.detail_number));
while Length(trim(strdetail_number)) < 5
loop
  strdetail_number := '0' || strdetail_number;
end loop;
dtl.INFORMER_FLAG := '1'; -- shipper
dtl.INFORMER_COUNTRY := fa.countrycode;
dtl.SENDER_CODE_QUALIFIER := 'SA';
dtl.SENDER_CODE := substr(fa.chep_communicator_code,1,13);
dtl.RECEIVER_CODE_QUALIFIER := 'SA';
if length(nvl(oh.shipto,'')) > 0 then
  dtl.RECEIVER_CODE := 'Z'||substr(oh.shipto,1,12);
else
  dtl.RECEIVER_CODE := '!';
end if;
dtl.EQUIP_CODE_QUALIFIER := '90';
dtl.EQUIP_CODE := '4001';
dtl.DATE_OF_DISPATCH := oh.statusupdate;
dtl.DATE_OF_RECEIPT := null;
dtl.QTY := ph.outpallets;
dtl.REFERENCE_1 := strChepCustId ||
                   substr(strseq_number,1,4) ||
                   substr(strdetail_number,1,5);
debugmsg('reference1 ' || dtl.reference_1);
dtl.REFERENCE_2 := substr(oh.reference,1,13);
debugmsg('reference2 ' || oh.reference);
dtl.REFERENCE_3 := substr(oh.po,1,13);
debugmsg('reference3 ' || substr(oh.po,1,13));
dtl.TRANSPORT_RESPONSIBILITY := '2';
debugmsg('transport resp');
dtl.SYS_PARM_1 := '';
dtl.SYS_PARM_2 := '';
dtl.SYS_PARM_3 := '';
dtl.SPECIAL_PROCESSING_CODE := '';
dtl.FLOW_CODE := '';
if oh.shipto is not null then
  co := null;
  open curConsignee(oh.shipto);
  fetch curConsignee into co;
  close curConsignee;
  debugmsg('con name');
  dtl.COUNTER_PART_NAME := co.name;
  debugmsg('con addr1');
  dtl.COUNTER_PART_ADDR := co.addr1;
  debugmsg('con city');
  dtl.COUNTER_PART_CITY := co.city;
  debugmsg('con postal');
  dtl.COUNTER_PART_POSTAL_CODE := co.postalcode;
  debugmsg('con state');
  dtl.COUNTER_PART_STATE := co.state;
  debugmsg('con country');
  dtl.COUNTER_PART_COUNTRY := co.countrycode;
else
  debugmsg('st name');
  dtl.COUNTER_PART_NAME := oh.shiptoname;
  debugmsg('st addr');
  dtl.COUNTER_PART_ADDR := oh.shiptoaddr1;
  debugmsg('st city');
  dtl.COUNTER_PART_CITY := oh.shiptocity;
  debugmsg('st postal');
  dtl.COUNTER_PART_POSTAL_CODE := oh.shiptopostalcode;
  debugmsg('st state');
  dtl.COUNTER_PART_STATE := oh.shiptostate;
  debugmsg('st country');
  dtl.COUNTER_PART_COUNTRY := oh.shiptocountrycode;
end if;
dtl.THIRD_PARTY_CODE_QUALIFIER := '';
dtl.THIRD_PARTY_CODE := '';

if strDebugYN = 'Y' then
zut.prt('LOADNO ' || dtl.LOADNO || length(dtl.LOADNO));
zut.prt('DETAIL_NUMBER ' || dtl.DETAIL_NUMBER || length(dtl.DETAIL_NUMBER));
zut.prt('INFORMER_FLAG ' || dtl.INFORMER_FLAG || length(dtl.INFORMER_FLAG));
zut.prt('INFORMER_COUNTRY ' || dtl.INFORMER_COUNTRY || length(dtl.INFORMER_COUNTRY));
zut.prt('SENDER_CODE_QUALIFIER ' || dtl.SENDER_CODE_QUALIFIER || length(dtl.SENDER_CODE_QUALIFIER));
zut.prt('SENDER_CODE ' || dtl.SENDER_CODE || length(dtl.SENDER_CODE));
zut.prt('RECEIVER_CODE_QUALIFIER ' || dtl.RECEIVER_CODE_QUALIFIER || length(dtl.RECEIVER_CODE_QUALIFIER));
zut.prt('RECEIVER_CODE ' || dtl.RECEIVER_CODE || length(dtl.RECEIVER_CODE));
zut.prt('EQUIP_CODE_QUALIFIER ' || dtl.EQUIP_CODE_QUALIFIER || length(dtl.EQUIP_CODE_QUALIFIER));
zut.prt('EQUIP_CODE ' || dtl.EQUIP_CODE || length(dtl.EQUIP_CODE));
zut.prt('DATE_OF_DISPATCH ' || dtl.DATE_OF_DISPATCH || length(dtl.DATE_OF_DISPATCH));
zut.prt('DATE_OF_RECEIPT ' || dtl.DATE_OF_RECEIPT || length(dtl.DATE_OF_RECEIPT));
zut.prt('QTY ' || dtl.QTY || length(dtl.QTY));
zut.prt('REFERENCE_1 ' || dtl.REFERENCE_1 || length(dtl.REFERENCE_1));
zut.prt('REFERENCE_2 ' || dtl.REFERENCE_2 || length(dtl.REFERENCE_2));
zut.prt('REFERENCE_3 ' || dtl.REFERENCE_3 || length(dtl.REFERENCE_3));
zut.prt('TRANSPORT_RESPONSIBILITY ' || dtl.TRANSPORT_RESPONSIBILITY || length(dtl.TRANSPORT_RESPONSIBILITY));
zut.prt('SYS_PARM_1 ' || dtl.SYS_PARM_1 || length(dtl.SYS_PARM_1));
zut.prt('SYS_PARM_2 ' || dtl.SYS_PARM_2 || length(dtl.SYS_PARM_2));
zut.prt('SYS_PARM_3 ' || dtl.SYS_PARM_3 || length(dtl.SYS_PARM_3));
zut.prt('SPECIAL_PROCESSING_CODE ' || dtl.SPECIAL_PROCESSING_CODE || length(dtl.SPECIAL_PROCESSING_CODE));
zut.prt('FLOW_CODE ' || dtl.FLOW_CODE || length(dtl.FLOW_CODE));
zut.prt('COUNTER_PART_NAME ' || dtl.COUNTER_PART_NAME || length(dtl.COUNTER_PART_NAME));
zut.prt('COUNTER_PART_ADDR ' || dtl.COUNTER_PART_ADDR || length(dtl.COUNTER_PART_ADDR));
zut.prt('COUNTER_PART_CITY ' || dtl.COUNTER_PART_CITY || length(dtl.COUNTER_PART_CITY));
zut.prt('COUNTER_PART_POSTAL_CODE ' || dtl.COUNTER_PART_POSTAL_CODE || length(dtl.COUNTER_PART_POSTAL_CODE));
zut.prt('COUNTER_PART_STATE ' || dtl.COUNTER_PART_STATE || length(dtl.COUNTER_PART_STATE));
zut.prt('COUNTER_PART_COUNTRY ' || dtl.COUNTER_PART_COUNTRY || length(dtl.COUNTER_PART_COUNTRY));
zut.prt('THIRD_PARTY_CODE_QUALIFIER ' || dtl.THIRD_PARTY_CODE_QUALIFIER || length(dtl.THIRD_PARTY_CODE_QUALIFIER));
zut.prt('THIRD_PARTY_CODE ' || dtl.THIRD_PARTY_CODE || length(dtl.THIRD_PARTY_CODE));
end if;


debugmsg('insert dtl');
execute immediate 'insert into CHEP_DTL_VIEW_' || strSuffix ||
' values (:LOADNO,:DETAIL_NUMBER,:INFORMER_FLAG,:INFORMER_COUNTRY,' ||
' :SENDER_CODE_QUALIFIER,:SENDER_CODE,:RECEIVER_CODE_QUALIFIER,:RECEIVER_CODE,' ||
' :EQUIP_CODE_QUALIFIER,:EQUIP_CODE,:DATE_OF_DISPATCH,:DATE_OF_RECEIPT,' ||
' :QTY,:REFERENCE_1,:REFERENCE_2,:REFERENCE_3,:TRANSPORT_RESPONSIBILITY,' ||
' :SYS_PARM_1,:SYS_PARM_2,:SYS_PARM_3,:SPECIAL_PROCESSING_CODE,:FLOW_CODE,' ||
' :COUNTER_PART_NAME,:COUNTER_PART_ADDR,:COUNTER_PART_CITY,:COUNTER_PART_POSTAL_CODE,' ||
' :COUNTER_PART_STATE,:COUNTER_PART_COUNTRY,:THIRD_PARTY_CODE_QUALIFIER,' ||
' :THIRD_PARTY_CODE )'
using dtl.LOADNO,dtl.DETAIL_NUMBER,dtl.INFORMER_FLAG,dtl.INFORMER_COUNTRY,
dtl.SENDER_CODE_QUALIFIER,dtl.SENDER_CODE,dtl.RECEIVER_CODE_QUALIFIER,
dtl.RECEIVER_CODE,dtl.EQUIP_CODE_QUALIFIER,dtl.EQUIP_CODE,dtl.DATE_OF_DISPATCH,
dtl.DATE_OF_RECEIPT,dtl.QTY,dtl.REFERENCE_1,dtl.REFERENCE_2,dtl.REFERENCE_3,
dtl.TRANSPORT_RESPONSIBILITY,dtl.SYS_PARM_1,dtl.SYS_PARM_2,dtl.SYS_PARM_3,
dtl.SPECIAL_PROCESSING_CODE,dtl.FLOW_CODE,dtl.COUNTER_PART_NAME,dtl.COUNTER_PART_ADDR,
dtl.COUNTER_PART_CITY,dtl.COUNTER_PART_POSTAL_CODE,dtl.COUNTER_PART_STATE,
dtl.COUNTER_PART_COUNTRY,dtl.THIRD_PARTY_CODE_QUALIFIER,dtl.THIRD_PARTY_CODE;

debugmsg('accum counts');
hdr.dtl_count := hdr.dtl_count + 1;
trl.dtl_count := trl.dtl_count + 1;
trl.qty_sum := trl.qty_sum + ph.outpallets;

end;

procedure process_chep_orders(oh orderhdr%rowtype) is
begin
  debugmsg('process_chep_orders');
  if oh.loadno <> hdr.loadno then
    if hdr.loadno = -1 then
      strChepCustId := substr(zci.default_value('CHEPCUSTID'),1,4);
      hdr.dtl_count := 0;
      trl.dtl_count := 0;
      trl.qty_sum := 0;
      dtl.detail_number := 0;
    end if;
    fa := null;
    open curFacility(oh.fromfacility);
    fetch curFacility into fa;
    close curFacility;
    hdr.loadno := oh.loadno;
  end if;
  add_chep_dtl_rows(oh);
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

debugmsg('find view suffix');
viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'CHEP_HDR_VIEW_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

debugmsg('get customer');
cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;


debugmsg('create chep hdr');
cmdSql := 'create table chep_hdr_view_' || strSuffix ||
' (LOADNO NUMBER,COMMUNICATOR_COUNTRY CHAR(3),COMMUNICATOR_CODE CHAR(18),' ||
' FILE_DATE DATE,DTL_COUNT NUMBER,SEQ_NUMBER NUMBER, COUNTRY_AND_CODE VARCHAR2(32),'||
' FACILITY CHAR(3), CUSTID CHAR(10) )';
debugmsg(cmdSql);
execute immediate cmdSql;

debugmsg('create table CHEP_DTL_VIEW_' || strSuffix);
cmdSql := 'create table CHEP_DTL_VIEW_' || strSuffix ||
' (LOADNO NUMBER,DETAIL_NUMBER NUMBER,INFORMER_FLAG CHAR(1),INFORMER_COUNTRY CHAR(3),' ||
' SENDER_CODE_QUALIFIER CHAR(2),SENDER_CODE CHAR(35),RECEIVER_CODE_QUALIFIER CHAR(2),' ||
' RECEIVER_CODE CHAR(35),EQUIP_CODE_QUALIFIER CHAR(2),EQUIP_CODE CHAR(35),' ||
' DATE_OF_DISPATCH DATE,DATE_OF_RECEIPT DATE,QTY NUMBER,REFERENCE_1 CHAR(36),' ||
' REFERENCE_2 CHAR(36),REFERENCE_3 CHAR(36),TRANSPORT_RESPONSIBILITY CHAR(1),' ||
' SYS_PARM_1 CHAR(1),SYS_PARM_2 CHAR(1),SYS_PARM_3 CHAR(6),SPECIAL_PROCESSING_CODE CHAR(3),' ||
' FLOW_CODE CHAR(1),COUNTER_PART_NAME CHAR(40),COUNTER_PART_ADDR CHAR(60),' ||
' COUNTER_PART_CITY CHAR(40),COUNTER_PART_POSTAL_CODE CHAR(30),COUNTER_PART_STATE CHAR(35),' ||
' COUNTER_PART_COUNTRY CHAR(3),THIRD_PARTY_CODE_QUALIFIER CHAR(2),' ||
' THIRD_PARTY_CODE CHAR(35) )';
debugmsg(cmdSql);
execute immediate cmdSql;

debugmsg('create table CHEP_TRL_VIEW_' || strSuffix);
cmdSql := 'create table CHEP_TRL_VIEW_' || strSuffix ||
' (LOADNO NUMBER,DTL_COUNT NUMBER,QTY_SUM NUMBER )';
debugmsg(cmdSql);
execute immediate cmdSql;

strChepType := trim(substr(zci.default_value('PALLETTYPECHEP'),1,12));
hdr.loadno := -1;
seq_number := 0;

if in_orderid != 0 then
  for oh in curOrderHdr
  loop
    process_chep_orders(oh);
  end loop;
elsif in_loadno != 0 then  for oh in curOrderHdrByLoad
  loop
    process_chep_orders(oh);
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
    process_chep_orders(oh);
  end loop;
end if;

add_chep_hdr_row;
add_chep_trl_row;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimchepb ' || sqlerrm;
  out_errorno := sqlcode;
end begin_dre_chep2_global_format;

procedure end_dre_chep_global_format
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'drop table chep_hdr_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table chep_dtl_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table chep_trl_view_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimchepe ' || sqlerrm;
  out_errorno := sqlcode;
end end_dre_chep_global_format;

PROCEDURE get_chepfileseq
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_chepfileseq OUT varchar2
) is

strSuffix varchar2(32);

begin

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

execute immediate
  'select seq_number from chep_hdr_view_' || strSuffix
    into out_chepfileseq;

while length(out_chepfileseq) < 4
loop
  out_chepfileseq := '0' || out_chepfileseq;
end loop;

exception when others then
  out_chepfileseq := '0000';
end get_chepfileseq;

end zimportprocchep;
/
show error package body zimportprocchep;
exit;
