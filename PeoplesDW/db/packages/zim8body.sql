create or replace package body alps.zimportproc8 as
--
-- $Id: zim8body.sql 7896 2012-02-02 21:48:59Z jeff $
--


procedure begin_loadtender204
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_loadno IN number
,in_send_original_204_yn IN varchar2
,in_pallet_uom IN varchar2
,in_rounding_value IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curCustomer is
  select custid
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where custid = in_custid
     and orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderHdrByLoad is
  select *
    from orderhdr
   where custid = in_custid
     and loadno = in_loadno
   order by orderid,shipid;

cursor curAddr(in_orderid varchar2, in_shipid varchar2) is
  select decode(CN.consignee,null,shiptoname,CN.name) as shiptoname,
     decode(CN.consignee,null,shiptocontact,CN.contact) as shiptocontact,
     decode(CN.consignee,null,shiptoaddr1,CN.addr1) as shiptoaddr1,
     decode(CN.consignee,null,shiptoaddr2,CN.addr2) as shiptoaddr2,
     decode(CN.consignee,null,shiptocity,CN.city) as shiptocity,
     decode(CN.consignee,null,shiptostate,CN.state) as shiptostate,
     decode(CN.consignee,null,shiptopostalcode,CN.postalcode) as shiptopostalcode,
     decode(CN.consignee,null,shiptocountrycode,CN.countrycode) as shiptocountrycode,
     decode(CN.consignee,null,shiptophone,CN.phone) as shiptophone,
     oh.shipto,
     oh.consignee,
     decode(BCN.consignee,null,billtoname,BCN.name) as billtoname,
     decode(BCN.consignee,null,billtocontact,BCN.contact) as billtocontact,
     decode(BCN.consignee,null,billtoaddr1,BCN.addr1) as billtoaddr1,
     decode(BCN.consignee,null,billtoaddr2,BCN.addr2) as billtoaddr2,
     decode(BCN.consignee,null,billtocity,BCN.city) as billtocity,
     decode(BCN.consignee,null,billtostate,BCN.state) as billtostate,
     decode(BCN.consignee,null,billtopostalcode,BCN.postalcode) as billtopostalcode,
     decode(BCN.consignee,null,billtocountrycode,BCN.countrycode) as billtocountrycode,
     decode(BCN.consignee,null,billtophone,BCN.phone) as billtophone
   from orderhdr oh, consignee CN, consignee BCN
     where oh.orderid = in_orderid
       and oh.shipid = in_shipid
       and oh.shipto = CN.consignee(+)
       and oh.consignee = BCN.consignee(+);
ADDR curAddr %rowtype;

strDebugYN char(1);
curFunc integer;
cntRows integer;
cmdSql varchar2(25000);
strSuffix varchar2(32);
viewcount integer;
l_count integer;
l_load_order_count integer;
procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
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

procedure add_204_hdr_rows(hdr curorderhdr%rowtype) is
begin
-- Insert into header table
debugmsg('inserting HDR');
cmdSql := 'insert into LD_TDR_204_HDR_' || strSuffix ||
  ' select ' ||
  'oh.reference,oh.po,oh.carrier,oh.orderid || ''-'' || oh.shipid, decode(oh.orderstatus,''X'',''01'',''00''),' ||
  'oh.shiptype, oh.custid, oh.shipterms, oh.shipdate, ' ||
  'zim8.sum_units(oh.orderid, oh.shipid), zim8.sum_weight(oh.orderid, oh.shipid), zim8.sum_volume(oh.orderid, oh.shipid), ' ||
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
  'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
  'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
  'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
  'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
  'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,' ||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,' ||
  'oh.orderid, oh.shipid, nvl(oh.loadno, 0),oh.arrivaldate,oh.cancel_after,'||
  'oh.ship_no_later,oh.delivery_requested,oh.cancel_if_not_delivered_by,'||
  'oh.requested_ship,oh.do_not_deliver_after,oh.ship_not_before,'||
  'oh.do_not_deliver_before,oh.comment1,'||
  '(select bolcomment from orderhdrbolcomments where orderid = ' || oh.orderid ||
  ' and shipid = ' || hdr.shipid || '),'||
  'zim8.total_estimated_pallet_count(oh.custid, oh.orderid, oh.shipid, null, null, nvl('''||in_pallet_uom||''',''PT''),'||'nvl('''||in_rounding_value||''',0.4999))'||
  ' from orderhdr oh ' ||
  ' where oh.orderid = '||hdr.orderid||
  ' and oh.shipid = '||hdr.shipid||
  ' and oh.custid = '''||hdr.custid||'''';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
end add_204_hdr_rows;

procedure add_204_addr_rows(oh curorderhdr%rowtype) is
l_loadno orderhdr.loadno%type;

begin
-- Insert into address table
debugmsg('inserting ADDR');

open curAddr(oh.orderid, oh.shipid);
fetch curAddr into ADDR;
close curAddr;

execute immediate 'insert into LD_TDR_204_ADDR_' || strSuffix ||
   ' values (:ORDERID,:SHIPID,:CUSTID,:LOADNO,'||
   ' :QUALIFIER, :CODE, :NAME, :CONTACT,' ||
   ' :ADDR1, :ADDR2, :CITY, :STATE, ' ||
   ' :POSTALCODE, :COUNTRYCODE, :PHONE)'
   using oh.orderid, oh.shipid, oh.custid, nvl(oh.loadno,0),
      'CN', ADDR.shipto, ADDR.shiptoname, ADDR.shiptocontact,
      ADDR.shiptoaddr1, ADDR.shiptoaddr2, ADDR.shiptocity, ADDR.shiptostate,
      ADDR.shiptopostalcode, ADDR.shiptocountrycode, ADDR.shiptophone;

if oh.consignee is not null or
   oh.billtoname is not null then
   execute immediate 'insert into LD_TDR_204_ADDR_' || strSuffix ||
      ' values (:ORDERID,:SHIPID,:CUSTID,:LOADNO,'||
      ' :QUALIFIER, :CODE, :NAME, :CONTACT,' ||
      ' :ADDR1, :ADDR2, :CITY, :STATE, ' ||
      ' :POSTALCODE, :COUNTRYCODE, :PHONE)'
      using oh.orderid, oh.shipid, oh.custid, nvl(oh.loadno,0),
         'BT', ADDR.consignee, ADDR.billtoname, ADDR.billtocontact,
         ADDR.billtoaddr1, ADDR.billtoaddr2, ADDR.billtocity, ADDR.billtostate,
         ADDR.billtopostalcode, ADDR.billtocountrycode, ADDR.billtophone;
end if;

cmdSql := 'insert into  LD_TDR_204_ADDR_' || strSuffix ||
 ' select ' || oh.orderid ||','|| oh.shipid ||', ''' || oh.custid ||''', '|| nvl(oh.loadno,0) ||', ''SH'', '''||
         oh.fromfacility ||''', c.name, null, f.addr1, f.addr2,  '||
         'f.city, f.state, f.postalcode, f.countrycode, f.phone '||
   'from facility f, customer c ' ||
   'where f.facility = ''' || oh.fromfacility || '''' ||
    ' and c.custid = ''' || oh.custid || '''';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
end add_204_addr_rows;

procedure add_204_dtl_rows(oh curorderhdr%rowtype) is
begin
-- Insert into detail table
debugmsg('inserting DTL');
cmdSql := 'insert into LD_TDR_204_DTL_' || strSuffix ||
  ' select d.orderid, d.shipid, d.custid,'||nvl(oh.loadno,0)||',d.dtlpassthrunum10, ''OTHR'','||
  'd.weightorder,d.weightorder / 2.2046,d.weightorder / .0022046, d.weightorder * 16, '||
  'd.item,d.lotnumber,nvl(d.lotnumber,''(none)''), ''' || oh.reference || ''', '||
  'd.dtlpassthrunum10, ''' || to_char(oh.entrydate, 'mmddyyyy') || ''', ''' || oh.po ||''','||
  'd.qtyorder, 0, d.qtyorder,d.uom,null,d.weightorder, ''G'',''L'','||
  'i.descr,U.upc,I.nmfc,N.class, '||
  'd.dtlpassthruchar01,d.dtlpassthruchar02,d.dtlpassthruchar03,d.dtlpassthruchar04,'||
  'd.dtlpassthruchar05,d.dtlpassthruchar06,d.dtlpassthruchar07,d.dtlpassthruchar08,'||
  'd.dtlpassthruchar09,d.dtlpassthruchar10,d.dtlpassthruchar11,d.dtlpassthruchar12,'||
  'd.dtlpassthruchar13,d.dtlpassthruchar14,d.dtlpassthruchar15,d.dtlpassthruchar16,'||
  'd.dtlpassthruchar17,d.dtlpassthruchar18,d.dtlpassthruchar19,d.dtlpassthruchar20,'||
  'd.dtlpassthruchar21,d.dtlpassthruchar22,d.dtlpassthruchar23,d.dtlpassthruchar24,'||
  'd.dtlpassthruchar25,d.dtlpassthruchar26,d.dtlpassthruchar27,d.dtlpassthruchar28,'||
  'd.dtlpassthruchar29,d.dtlpassthruchar30,d.dtlpassthruchar31,d.dtlpassthruchar32,'||
  'd.dtlpassthruchar33,d.dtlpassthruchar34,d.dtlpassthruchar35,d.dtlpassthruchar36,'||
  'd.dtlpassthruchar37,d.dtlpassthruchar38,d.dtlpassthruchar39,d.dtlpassthruchar40,'||
  'd.dtlpassthrunum01,d.dtlpassthrunum02,d.dtlpassthrunum03,d.dtlpassthrunum04,'||
  'd.dtlpassthrunum05,d.dtlpassthrunum06,d.dtlpassthrunum07,d.dtlpassthrunum08,'||
  'd.dtlpassthrunum09,d.dtlpassthrunum10,d.dtlpassthrunum11,d.dtlpassthrunum12,'||
  'd.dtlpassthrunum13,d.dtlpassthrunum14,d.dtlpassthrunum15,d.dtlpassthrunum16,'||
  'd.dtlpassthrunum17,d.dtlpassthrunum18,d.dtlpassthrunum19,d.dtlpassthrunum20,'||
  'd.dtlpassthrudate01,d.dtlpassthrudate02,d.dtlpassthrudate03,d.dtlpassthrudate04,'||
  'd.dtlpassthrudoll01,d.dtlpassthrudoll02,null,d.uomentered, d.qtytotcommit,'||
  'zim8.total_estimated_pallet_count(d.custid, d.orderid, d.shipid, null, null, nvl('''||in_pallet_uom||''',''PT''),'||'nvl('''||in_rounding_value||''',0.4999)),'||
  'zim8.total_cases(d.orderid,d.shipid) '||
  'from custitemupcview U, custitem I, nmfclasscodes N, orderdtl d '||
  'where d.orderid = '|| oh.orderid || ' ' ||
    'and d.shipid = '|| oh.shipid || ' '||
    'and d.custid = I.custid(+) '||
    'and d.item = i.item(+) '||
    'and d.custid = U.custid(+) '||
    'and D.item = U.item(+) '||
    'and I.nmfc = N.nmfc(+)';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
end add_204_dtl_rows;


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

if in_orderid != 0 then
  open curOrderHdr;
  fetch curOrderHdr into oh;
  if curOrderHdr%notfound then
    close curOrderHdr;
    out_errorno := -2;
    out_msg := 'Invalid Orderid - Shipid ' || in_orderid || '-' || in_shipid;
    return;
  end if;
  close curOrderHdr;
elsif in_loadno != 0 then
  open curOrderHdrByLoad;
  fetch curOrderHdrByLoad into oh;
  if curOrderHdrByLoad%notfound then
    close curOrderHdrByLoad;
    out_errorno := -2;
    out_msg := 'Invalid Loadno ' || in_loadno;
    return;
  end if;
  close curOrderHdrByLoad;
end if;

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'LD_TDR_204_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

-- Create header table
debugmsg('creating HDR');
cmdSql := 'create table LD_TDR_204_HDR_' || strSuffix ||
 '(reference VARCHAR2(20), po VARCHAR2(20),carrier VARCHAR2(10),orderid_shipid VARCHAR2(20),'||
 'status VARCHAR2(3),shiptype VARCHAR2(1),custid VARCHAR2(10) not null,shipterms VARCHAR2(3),'||
 'shipdate DATE,totalunits NUMBER(10),totalweight NUMBER(17,8),totalvolume NUMBER(10,4),'||
 'HDRPASSTHRUCHAR01 VARCHAR2(255),HDRPASSTHRUCHAR02 VARCHAR2(255),HDRPASSTHRUCHAR03 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR04 VARCHAR2(255),HDRPASSTHRUCHAR05 VARCHAR2(255),HDRPASSTHRUCHAR06 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR07 VARCHAR2(255),HDRPASSTHRUCHAR08 VARCHAR2(255),HDRPASSTHRUCHAR09 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR10 VARCHAR2(255),HDRPASSTHRUCHAR11 VARCHAR2(255),HDRPASSTHRUCHAR12 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR13 VARCHAR2(255),HDRPASSTHRUCHAR14 VARCHAR2(255),HDRPASSTHRUCHAR15 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR16 VARCHAR2(255),HDRPASSTHRUCHAR17 VARCHAR2(255),HDRPASSTHRUCHAR18 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR19 VARCHAR2(255),HDRPASSTHRUCHAR20 VARCHAR2(255),HDRPASSTHRUCHAR21 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR22 VARCHAR2(255),HDRPASSTHRUCHAR23 VARCHAR2(255),HDRPASSTHRUCHAR24 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR25 VARCHAR2(255),HDRPASSTHRUCHAR26 VARCHAR2(255),HDRPASSTHRUCHAR27 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR28 VARCHAR2(255),HDRPASSTHRUCHAR29 VARCHAR2(255),HDRPASSTHRUCHAR30 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR31 VARCHAR2(255),HDRPASSTHRUCHAR32 VARCHAR2(255),HDRPASSTHRUCHAR33 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR34 VARCHAR2(255),HDRPASSTHRUCHAR35 VARCHAR2(255),HDRPASSTHRUCHAR36 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR37 VARCHAR2(255),HDRPASSTHRUCHAR38 VARCHAR2(255),HDRPASSTHRUCHAR39 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR40 VARCHAR2(255),HDRPASSTHRUCHAR41 VARCHAR2(255),HDRPASSTHRUCHAR42 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR43 VARCHAR2(255),HDRPASSTHRUCHAR44 VARCHAR2(255),HDRPASSTHRUCHAR45 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR46 VARCHAR2(255),HDRPASSTHRUCHAR47 VARCHAR2(255),HDRPASSTHRUCHAR48 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR49 VARCHAR2(255),HDRPASSTHRUCHAR50 VARCHAR2(255),HDRPASSTHRUCHAR51 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR52 VARCHAR2(255),HDRPASSTHRUCHAR53 VARCHAR2(255),HDRPASSTHRUCHAR54 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR55 VARCHAR2(255),HDRPASSTHRUCHAR56 VARCHAR2(255),HDRPASSTHRUCHAR57 VARCHAR2(255),'||
 'HDRPASSTHRUCHAR58 VARCHAR2(255),HDRPASSTHRUCHAR59 VARCHAR2(255),HDRPASSTHRUCHAR60 VARCHAR2(255),'||
 'HDRPASSTHRUNUM01 NUMBER(16,4),HDRPASSTHRUNUM02 NUMBER(16,4),HDRPASSTHRUNUM03 NUMBER(16,4),'||
 'HDRPASSTHRUNUM04 NUMBER(16,4),HDRPASSTHRUNUM05 NUMBER(16,4),HDRPASSTHRUNUM06 NUMBER(16,4),'||
 'HDRPASSTHRUNUM07 NUMBER(16,4),HDRPASSTHRUNUM08 NUMBER(16,4),HDRPASSTHRUNUM09 NUMBER(16,4),'||
 'HDRPASSTHRUNUM10 NUMBER(16,4),HDRPASSTHRUDATE01 DATE,HDRPASSTHRUDATE02 DATE,HDRPASSTHRUDATE03 DATE,'||
 'HDRPASSTHRUDATE04 DATE,HDRPASSTHRUDOLL01 NUMBER(10,2),HDRPASSTHRUDOLL02 NUMBER(10,2),'||
 'ORDERID NUMBER(9) not null, SHIPID NUMBER(2) not null, LOADNO NUMBER(7) not null,'||
 'ARRIVALDATE DATE,CANCEL_AFTER DATE,SHIP_NO_LATER DATE,DELIVERY_REQUESTED DATE,'||
 'CANCEL_IF_NOT_DELIVERED_BY DATE,REQUESTED_SHIP DATE,DO_NOT_DELIVER_AFTER DATE,'||
 'SHIP_NOT_BEFORE DATE,DO_NOT_DELIVER_BEFORE DATE,COMMENT1 CLOB,BOLCOMMENT CLOB,'||
 'TOTAL_ESTIMATED_PALLET_COUNT NUMBER(9)'||
 ')';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Create address table
debugmsg('creating ADDR');
cmdSql := 'create table LD_TDR_204_ADDR_' || strSuffix ||
' (ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,CUSTID VARCHAR2(10) not null,LOADNO NUMBER(7) not null,' ||
' QUALIFIER VARCHAR2(2), CODE VARCHAR2(10), NAME VARCHAR2(40), CONTACT VARCHAR2(40),' ||
' ADDR1 VARCHAR2(40), ADDR2 VARCHAR2(40), CITY VARCHAR2(30), STATE VARCHAR2(5), ' ||
' POSTALCODE VARCHAR(12), COUNTRYCODE VARCHAR2(3), PHONE VARCHAR2(40))';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

-- Create detail table
debugmsg('creating DTL');
cmdSql := 'create table LD_TDR_204_dtl_' || strSuffix ||
  '(orderid  NUMBER(9) not null,shipid NUMBER(2) not null,custid VARCHAR2(10) not null,loadno NUMBER(7) not null,'||
  'assignedid VARCHAR2(255),servicecode VARCHAR2(4),lbs NUMBER(17,8),kgs NUMBER(17,8),gms NUMBER(17,8),ozs NUMBER(17,8),'||
  'item varchar2(50),lotnumber VARCHAR2(30),link_lotnumber VARCHAR2(30),reference VARCHAR2(20),'||
  'linenumber VARCHAR2(255),orderdate VARCHAR2(9),po VARCHAR2(20),qtyordered NUMBER(10),qtyshipped NUMBER(10),qtydiff NUMBER(10),'||
  'uom VARCHAR2(4),packlistshipdate VARCHAR2(9),weight NUMBER(17,8),weightqualifier  VARCHAR2(1),weightunit  VARCHAR2(1),'||
  'description VARCHAR2(40),upc VARCHAR2(20) ,nmfc VARCHAR2(12),freightclass NUMBER(4,1),'||
  'DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255),DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR21 VARCHAR2(255),DTLPASSTHRUCHAR22 VARCHAR2(255),DTLPASSTHRUCHAR23 VARCHAR2(255),DTLPASSTHRUCHAR24 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR25 VARCHAR2(255),DTLPASSTHRUCHAR26 VARCHAR2(255),DTLPASSTHRUCHAR27 VARCHAR2(255),DTLPASSTHRUCHAR28 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR29 VARCHAR2(255),DTLPASSTHRUCHAR30 VARCHAR2(255),DTLPASSTHRUCHAR31 VARCHAR2(255),DTLPASSTHRUCHAR32 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR33 VARCHAR2(255),DTLPASSTHRUCHAR34 VARCHAR2(255),DTLPASSTHRUCHAR35 VARCHAR2(255),DTLPASSTHRUCHAR36 VARCHAR2(255),'||
  'DTLPASSTHRUCHAR37 VARCHAR2(255),DTLPASSTHRUCHAR38 VARCHAR2(255),DTLPASSTHRUCHAR39 VARCHAR2(255),DTLPASSTHRUCHAR40 VARCHAR2(255),'||
  'DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),DTLPASSTHRUNUM03 NUMBER(16,4),DTLPASSTHRUNUM04 NUMBER(16,4),'||
  'DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),'||
  'DTLPASSTHRUNUM09 NUMBER(16,4),DTLPASSTHRUNUM10 NUMBER(16,4),DTLPASSTHRUNUM11 NUMBER(16,4),DTLPASSTHRUNUM12 NUMBER(16,4),'||
  'DTLPASSTHRUNUM13 NUMBER(16,4),DTLPASSTHRUNUM14 NUMBER(16,4),DTLPASSTHRUNUM15 NUMBER(16,4),DTLPASSTHRUNUM16 NUMBER(16,4),'||
  'DTLPASSTHRUNUM17 NUMBER(16,4),DTLPASSTHRUNUM18 NUMBER(16,4),DTLPASSTHRUNUM19 NUMBER(16,4),DTLPASSTHRUNUM20 NUMBER(16,4),'||
  'DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,'||
  'DTLPASSTHRUDOLL01 NUMBER(10,2),DTLPASSTHRUDOLL02 NUMBER(10,2),deliveryservice VARCHAR2(4),entereduom VARCHAR2(4), qtytotcommit NUMBER(10),'||
  'PALLETCOUNT NUMBER(7),TOTCASES NUMBER(7)'||
  ')';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

if in_orderid != 0 then
  debugmsg('by order ' || in_orderid || '-' || in_shipid);
  for oh in curOrderHdr
  loop
    debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
   if nvl(in_send_original_204_yn,'N') = 'Y' then
    debugmsg('in_send_original_204_yn = '||in_send_original_204_yn);
     begin
      select count(regexp_substr(oh.editransaction, '204'))
       into l_count
       from dual;
     exception when others then
      l_count := 0;
     end;
     if l_count > 0 then
      debugmsg('edi transaction already done: '||oh.editransaction);
      return;
     end if;
   end if;
    add_204_hdr_rows(oh);
    add_204_addr_rows(oh);
    add_204_dtl_rows(oh);
  end loop;
elsif in_loadno != 0 then
  debugmsg('by loadno ' || in_loadno);
  l_load_order_count := 0;
  for oh in curOrderHdrByLoad
  loop
   if nvl(in_send_original_204_yn,'N') = 'Y' then
    debugmsg('in_send_original_204_yn = '||in_send_original_204_yn);
     begin
      select count(regexp_substr(oh.editransaction, '204'))
       into l_count
       from dual;
     exception when others then
      l_count := 0;
     end;
     if l_count > 0 then
      debugmsg('edi transaction already done: '||oh.editransaction);
      else
       l_load_order_count := l_load_order_count + 1;
      debugmsg('processing ' || oh.orderid || '-' || oh.shipid);
      add_204_hdr_rows(oh);
      add_204_addr_rows(oh);
      add_204_dtl_rows(oh);
     end if;
   end if;
  end loop;
  if l_load_order_count = 0 then
    return;
  end if;
end if;

cmdSql := 'create view load_tdr_204_nte_' || strSuffix ||
          '(orderid,shipid,comment1)'||
          'as select orderid, shipid, column_value'||
          ' from orderhdr, table (zim8.parseclob(comment1))'||
          ' union all'||
          ' select orderid, shipid, column_value'||
          ' from orderhdrbolcomments, table (zim8.parseclob(bolcomment))';
debugmsg(cmdSql);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbsn204 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_loadtender204;


procedure end_loadtender204
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strObject varchar2(32);
strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

for obj in (select object_name, object_type
              from user_objects
             where object_name like 'LD_TDR_204_%_' || strSuffix
               and object_name != 'LD_TDR_204_HDR_' || strSuffix )
loop

  cmdSql := 'drop ' || obj.object_type || ' ' || obj.object_name;

  execute immediate cmdSql;

end loop;

cmdsql := 'drop view LD_TDR_204_HDR_' || strSuffix;
execute immediate cmdSql;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimesn204 ' || sqlerrm;
  out_errorno := sqlcode;
end end_loadtender204;

FUNCTION sum_units
(in_orderid IN number
,in_shipid IN number
) return integer
IS
cnt integer;
BEGIN
    cnt := 0;
    select sum(qtyorder)
      into cnt
      from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid;
    return nvl(cnt, 0);

EXCEPTION WHEN OTHERS THEN
    return 0;
END sum_units;

FUNCTION sum_volume
(in_orderid IN number
,in_shipid IN number
) return number
IS
volume number;
BEGIN
    volume := 0;
    select sum(cubeorder)
      into volume
      from orderdtl od
     where orderid = in_orderid
       and shipid = in_shipid;
    return nvl(volume, 0);

EXCEPTION WHEN OTHERS THEN
    return 0;
END sum_volume;

FUNCTION sum_weight
(in_orderid IN number
,in_shipid IN number
) return number
IS
weight number;
BEGIN
    weight := 0;
    select sum(weightorder)
      into weight
      from orderdtl od
     where orderid = in_orderid
       and shipid = in_shipid;
    return nvl(weight, 0);

EXCEPTION WHEN OTHERS THEN
    return 0;
END sum_weight;


FUNCTION check_orderstatus_for_load
(in_orderid IN number
,in_shipid IN number
) return number
IS
  MT EXCEPTION;
  PRAGMA EXCEPTION_INIT(MT, -04091);
   l_msg varchar2(255);
cursor c_orders(in_orderid number, in_shipid number) is
  select loadno, orderid, shipid, nvl(orderstatus, 'x') orderstatus
   from  orderhdr
  where  loadno = (select loadno
                     from orderhdr
                    where orderid = in_orderid
                      and shipid = in_shipid);
ORD c_orders%rowtype;

BEGIN

  begin
  open c_orders(in_orderid, in_shipid);
  fetch c_orders into ORD;
  close c_orders;
  if nvl(ORD.loadno,0) = 0 then
    return -1;
  end if;

  for od in c_orders(in_orderid, in_shipid)
    loop
      if nvl(od.orderstatus,'x') not in ('4' , '5', '6', '7', '8', '9') then
        return -1;
      end if;
    end loop;

  exception when MT then
    null;
  end;

  return 0;

EXCEPTION WHEN OTHERS THEN
  zms.log_autonomous_msg('TENDER', null, null, sqlcode ||' - '||sqlerrm,'E', 'TENDER', l_msg);
  return -2;
END check_orderstatus_for_load;

procedure seteditransaction204
(in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is
cursor curOrderHdr is
  select editransaction,
         regexp_substr(editransaction, '204') editransaction204
   from orderhdr
  where orderid = in_orderid
    and shipid = in_shipid;
oh curOrderHdr%rowtype;

begin

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  out_errorno := -2;
  out_msg := 'Invalid Orderid - Shipid ' || in_orderid || '-' || in_shipid;
  return;
end if;

if rtrim(oh.editransaction204) is null then
  if rtrim(oh.editransaction) is null then
    update orderhdr
      set editransaction = '204'
    where orderid = in_orderid
      and shipid = in_shipid;
  else
    update orderhdr
      set editransaction = oh.editransaction || ',' || '204'
    where orderid = in_orderid
      and shipid = in_shipid;
  end if;
end if;

end seteditransaction204;

FUNCTION get_systemdefault
(in_defaultid IN varchar2
) return varchar2
IS

l_defaultvalue systemdefaults.defaultvalue%type;

BEGIN

    if nvl(in_defaultid,'xxx') = 'xxx' then
      return 'N';
    end if;

    execute immediate
     'select defaultvalue from systemdefaults where defaultid = '''||in_defaultid||''''
      into l_defaultvalue;
    return l_defaultvalue;

EXCEPTION WHEN OTHERS THEN
    return 'N';
END get_systemdefault;

FUNCTION total_estimated_pallet_count
(in_custid IN varchar2,
 in_orderid IN number,
 in_shipid IN number,
 in_item IN varchar2,
 in_qtyorder IN number,
 in_pallet_uom IN varchar2,
 in_rounding_value IN number
) return number
is

cursor c_uom(in_custid varchar2, in_item varchar2) is
  select nvl(cu.qty,0)
   from custitemuom cu, custitem ci
   where cu.custid = in_custid
     and cu.item = in_item
     and cu.custid = ci.custid
     and cu.item = ci.item
     and cu.touom = rtrim(in_pallet_uom);

cursor curOrderDtl is
 select od.custid, od.item, od.qtyorder
   from orderhdr oh, orderdtl od
  where oh.orderid = od.orderid
    and oh.shipid = od.shipid
    and oh.orderid = in_orderid
    and oh.shipid = in_shipid;

totpalletcount number(10,4);
pltqty number(10);
retval number(10,4);

begin
  totpalletcount := 0;

  if in_item is not null then
    open c_uom(in_custid, in_item);
    fetch c_uom into pltqty;
    close c_uom;
    totpalletcount := in_qtyorder / pltqty;
    return totpalletcount;
  end if;

  for od in curOrderDtl loop
    open c_uom(od.custid, od.item);
    fetch c_uom into pltqty;
    close c_uom;
    totpalletcount := totpalletcount + (od.qtyorder / pltqty);
  end loop;
  if in_rounding_value is not null then
    totpalletcount := totpalletcount + in_rounding_value;
  end if;

  select round(totpalletcount)
   into retval
   from dual;

  return retval;

exception when others then
  return  0;
end total_estimated_pallet_count;

FUNCTION total_cases
(in_orderid IN number,
 in_shipid IN number
) return number
is

cursor curOrderDtl is
 select od.custid, od.item, od.qtyorder, od.uom
   from orderhdr oh, orderdtl od
  where oh.orderid = od.orderid
    and oh.shipid = od.shipid
    and oh.orderid = in_orderid
    and oh.shipid = in_shipid;

totalcases number(10,4);

begin
  totalcases := 0;

  for od in curOrderDtl loop
    totalcases := totalcases + zlbl.uom_qty_conv(od.custid, od.item, od.qtyorder, od.uom, 'CS');
  end loop;

  return totalcases;

exception when others then
  return  0;
end total_cases;

function parseclob
(in_clob in clob
) return sys.odciVarchar2List
pipelined
as
l_offset number;
l_end    number;
l_len    number;

begin
l_len := nvl(dbms_lob.getlength(in_clob),0);
l_offset := 1;
loop
  exit when l_offset >= l_len;

  l_end := instr(in_clob, chr(13)||chr(10), l_offset);

  -- If last line has no carriage return and line feed
  if l_end = 0 and
     l_offset < l_len then
       l_end := 4000;
  end if;

  pipe row (substr( in_clob, l_offset, l_end-l_offset));

  -- Advance to beginning of next line
  l_offset := l_end + 2;
end loop;

exception when others then
  null;
end parseclob;


procedure import_inbound204_load
(in_func IN OUT varchar2
,in_facility IN varchar2
,in_shipmentid IN varchar2
,in_carrier IN varchar2
,in_billoflading IN varchar2
,in_custid IN varchar2
,in_shiptype IN varchar2
,in_shipterms IN varchar2
,in_appointmentdate IN date
,in_comment1 IN varchar2
,in_ldpassthruchar01 IN varchar2
,in_ldpassthruchar02 IN varchar2
,in_ldpassthruchar03 IN varchar2
,in_ldpassthruchar04 IN varchar2
,in_ldpassthruchar05 IN varchar2
,in_ldpassthruchar06 IN varchar2
,in_ldpassthruchar07 IN varchar2
,in_ldpassthruchar08 IN varchar2
,in_ldpassthruchar09 IN varchar2
,in_ldpassthruchar10 IN varchar2
,in_ldpassthruchar11 IN varchar2
,in_ldpassthruchar12 IN varchar2
,in_ldpassthruchar13 IN varchar2
,in_ldpassthruchar14 IN varchar2
,in_ldpassthruchar15 IN varchar2
,in_ldpassthruchar16 IN varchar2
,in_ldpassthruchar17 IN varchar2
,in_ldpassthruchar18 IN varchar2
,in_ldpassthruchar19 IN varchar2
,in_ldpassthruchar20 IN varchar2
,in_ldpassthruchar21 IN varchar2
,in_ldpassthruchar22 IN varchar2
,in_ldpassthruchar23 IN varchar2
,in_ldpassthruchar24 IN varchar2
,in_ldpassthruchar25 IN varchar2
,in_ldpassthruchar26 IN varchar2
,in_ldpassthruchar27 IN varchar2
,in_ldpassthruchar28 IN varchar2
,in_ldpassthruchar29 IN varchar2
,in_ldpassthruchar30 IN varchar2
,in_ldpassthruchar31 IN varchar2
,in_ldpassthruchar32 IN varchar2
,in_ldpassthruchar33 IN varchar2
,in_ldpassthruchar34 IN varchar2
,in_ldpassthruchar35 IN varchar2
,in_ldpassthruchar36 IN varchar2
,in_ldpassthruchar37 IN varchar2
,in_ldpassthruchar38 IN varchar2
,in_ldpassthruchar39 IN varchar2
,in_ldpassthruchar40 IN varchar2
,in_ldpassthrudate01 IN date
,in_ldpassthrudate02 IN date
,in_ldpassthrudate03 IN date
,in_ldpassthrudate04 IN date
,in_ldpassthrunum01 IN number
,in_ldpassthrunum02 IN number
,in_ldpassthrunum03 IN number
,in_ldpassthrunum04 IN number
,in_ldpassthrunum05 IN number
,in_ldpassthrunum06 IN number
,in_ldpassthrunum07 IN number
,in_ldpassthrunum08 IN number
,in_ldpassthrunum09 IN number
,in_ldpassthrunum10 IN number
,in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2)
is
begin
   out_errorno := 0;
   out_msg := 'OKAY';
   insert into import_204_load
   (importfileid
   ,seq
   ,func
   ,facility
   ,shipmentid
   ,carrier
   ,billoflading
   ,custid
   ,shiptype
   ,shipterms
   ,appointmentdate
   ,comment1
   ,ldpassthruchar01
   ,ldpassthruchar02
   ,ldpassthruchar03
   ,ldpassthruchar04
   ,ldpassthruchar05
   ,ldpassthruchar06
   ,ldpassthruchar07
   ,ldpassthruchar08
   ,ldpassthruchar09
   ,ldpassthruchar10
   ,ldpassthruchar11
   ,ldpassthruchar12
   ,ldpassthruchar13
   ,ldpassthruchar14
   ,ldpassthruchar15
   ,ldpassthruchar16
   ,ldpassthruchar17
   ,ldpassthruchar18
   ,ldpassthruchar19
   ,ldpassthruchar20
   ,ldpassthruchar21
   ,ldpassthruchar22
   ,ldpassthruchar23
   ,ldpassthruchar24
   ,ldpassthruchar25
   ,ldpassthruchar26
   ,ldpassthruchar27
   ,ldpassthruchar28
   ,ldpassthruchar29
   ,ldpassthruchar30
   ,ldpassthruchar31
   ,ldpassthruchar32
   ,ldpassthruchar33
   ,ldpassthruchar34
   ,ldpassthruchar35
   ,ldpassthruchar36
   ,ldpassthruchar37
   ,ldpassthruchar38
   ,ldpassthruchar39
   ,ldpassthruchar40
   ,ldpassthrudate01
   ,ldpassthrudate02
   ,ldpassthrudate03
   ,ldpassthrudate04
   ,ldpassthrunum01
   ,ldpassthrunum02
   ,ldpassthrunum03
   ,ldpassthrunum04
   ,ldpassthrunum05
   ,ldpassthrunum06
   ,ldpassthrunum07
   ,ldpassthrunum08
   ,ldpassthrunum09
   ,ldpassthrunum10
   ,created
   )
   values
   (in_importfileid
   ,in_seq
   ,in_func
   ,in_facility
   ,in_shipmentid
   ,in_carrier
   ,in_billoflading
   ,in_custid
   ,in_shiptype
   ,in_shipterms
   ,in_appointmentdate
   ,in_comment1
   ,in_ldpassthruchar01
   ,in_ldpassthruchar02
   ,in_ldpassthruchar03
   ,in_ldpassthruchar04
   ,in_ldpassthruchar05
   ,in_ldpassthruchar06
   ,in_ldpassthruchar07
   ,in_ldpassthruchar08
   ,in_ldpassthruchar09
   ,in_ldpassthruchar10
   ,in_ldpassthruchar11
   ,in_ldpassthruchar12
   ,in_ldpassthruchar13
   ,in_ldpassthruchar14
   ,in_ldpassthruchar15
   ,in_ldpassthruchar16
   ,in_ldpassthruchar17
   ,in_ldpassthruchar18
   ,in_ldpassthruchar19
   ,in_ldpassthruchar20
   ,in_ldpassthruchar21
   ,in_ldpassthruchar22
   ,in_ldpassthruchar23
   ,in_ldpassthruchar24
   ,in_ldpassthruchar25
   ,in_ldpassthruchar26
   ,in_ldpassthruchar27
   ,in_ldpassthruchar28
   ,in_ldpassthruchar29
   ,in_ldpassthruchar30
   ,in_ldpassthruchar31
   ,in_ldpassthruchar32
   ,in_ldpassthruchar33
   ,in_ldpassthruchar34
   ,in_ldpassthruchar35
   ,in_ldpassthruchar36
   ,in_ldpassthruchar37
   ,in_ldpassthruchar38
   ,in_ldpassthruchar39
   ,in_ldpassthruchar40
   ,in_ldpassthrudate01
   ,in_ldpassthrudate02
   ,in_ldpassthrudate03
   ,in_ldpassthrudate04
   ,in_ldpassthrunum01
   ,in_ldpassthrunum02
   ,in_ldpassthrunum03
   ,in_ldpassthrunum04
   ,in_ldpassthrunum05
   ,in_ldpassthrunum06
   ,in_ldpassthrunum07
   ,in_ldpassthrunum08
   ,in_ldpassthrunum09
   ,in_ldpassthrunum10
   ,sysTimestamp);

exception when others then
  out_msg := 'zimi204load ' || sqlerrm;
  out_errorno := sqlcode;
end import_inbound204_load;

procedure import_inbound204_stop
(in_func IN out varchar2
,in_shipmentid IN varchar2
,in_stop IN number
,in_delappt_date IN varchar2
,in_delappt_time IN varchar2
,in_comment IN varchar2
,in_date_format IN varchar2
,in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2) is
cntRows pls_integer;
begin
   select count(1) into cntRows
     from import_204_load
    where importfileid = in_importfileid
      and seq = in_seq;
   if cntRows = 0 then
         out_msg := 'import_inbound204_stop load not found ' || in_importfileid;
         out_errorno := 1;
   end if;
   out_errorno := 0;
   out_msg := 'OKAY';

   insert into import_204_stop
   (importfileid
   ,seq
   ,func
   ,shipmentid
   ,stop
   ,delappt_date
   ,delappt_time
   ,comment1
   ,date_format
   ,created
   )
   values
   (in_importfileid
   ,in_seq
   ,in_func
   ,in_shipmentid
   ,in_stop
   ,in_delappt_date
   ,in_delappt_time
   ,in_comment
   ,in_date_format
   ,systimestamp);

exception when others then
  out_msg := 'zimi204stop ' || sqlerrm;
  out_errorno := sqlcode;
end import_inbound204_stop;

procedure import_inbound204_order
(in_func IN out varchar2
,in_shipmentid IN varchar2
,in_stop IN number
,in_reference IN varchar2
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
,in_hdrpassthruchar21 IN varchar2
,in_hdrpassthruchar22 IN varchar2
,in_hdrpassthruchar23 IN varchar2
,in_hdrpassthruchar24 IN varchar2
,in_hdrpassthruchar25 IN varchar2
,in_hdrpassthruchar26 IN varchar2
,in_hdrpassthruchar27 IN varchar2
,in_hdrpassthruchar28 IN varchar2
,in_hdrpassthruchar29 IN varchar2
,in_hdrpassthruchar30 IN varchar2
,in_hdrpassthruchar31 IN varchar2
,in_hdrpassthruchar32 IN varchar2
,in_hdrpassthruchar33 IN varchar2
,in_hdrpassthruchar34 IN varchar2
,in_hdrpassthruchar35 IN varchar2
,in_hdrpassthruchar36 IN varchar2
,in_hdrpassthruchar37 IN varchar2
,in_hdrpassthruchar38 IN varchar2
,in_hdrpassthruchar39 IN varchar2
,in_hdrpassthruchar40 IN varchar2
,in_hdrpassthruchar41 IN varchar2
,in_hdrpassthruchar42 IN varchar2
,in_hdrpassthruchar43 IN varchar2
,in_hdrpassthruchar44 IN varchar2
,in_hdrpassthruchar45 IN varchar2
,in_hdrpassthruchar46 IN varchar2
,in_hdrpassthruchar47 IN varchar2
,in_hdrpassthruchar48 IN varchar2
,in_hdrpassthruchar49 IN varchar2
,in_hdrpassthruchar50 IN varchar2
,in_hdrpassthruchar51 IN varchar2
,in_hdrpassthruchar52 IN varchar2
,in_hdrpassthruchar53 IN varchar2
,in_hdrpassthruchar54 IN varchar2
,in_hdrpassthruchar55 IN varchar2
,in_hdrpassthruchar56 IN varchar2
,in_hdrpassthruchar57 IN varchar2
,in_hdrpassthruchar58 IN varchar2
,in_hdrpassthruchar59 IN varchar2
,in_hdrpassthruchar60 IN varchar2
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
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2) is
cntRows pls_integer;
begin
   select count(1) into cntRows
     from import_204_load
    where importfileid = in_importfileid
      and shipmentid = in_shipmentid;
   if cntRows = 0 then
         out_msg := 'import_inbound204_order load not found ' || in_reference || ' ' || in_importfileid;
         out_errorno := 2;
   end if;
   out_errorno := 0;
   out_msg := 'OKAY';
   insert into import_204_order
   (importfileid
   ,seq
   ,func
   ,shipmentid
   ,stop
   ,reference
   ,hdrpassthruchar01
   ,hdrpassthruchar02
   ,hdrpassthruchar03
   ,hdrpassthruchar04
   ,hdrpassthruchar05
   ,hdrpassthruchar06
   ,hdrpassthruchar07
   ,hdrpassthruchar08
   ,hdrpassthruchar09
   ,hdrpassthruchar10
   ,hdrpassthruchar11
   ,hdrpassthruchar12
   ,hdrpassthruchar13
   ,hdrpassthruchar14
   ,hdrpassthruchar15
   ,hdrpassthruchar16
   ,hdrpassthruchar17
   ,hdrpassthruchar18
   ,hdrpassthruchar19
   ,hdrpassthruchar20
   ,hdrpassthruchar21
   ,hdrpassthruchar22
   ,hdrpassthruchar23
   ,hdrpassthruchar24
   ,hdrpassthruchar25
   ,hdrpassthruchar26
   ,hdrpassthruchar27
   ,hdrpassthruchar28
   ,hdrpassthruchar29
   ,hdrpassthruchar30
   ,hdrpassthruchar31
   ,hdrpassthruchar32
   ,hdrpassthruchar33
   ,hdrpassthruchar34
   ,hdrpassthruchar35
   ,hdrpassthruchar36
   ,hdrpassthruchar37
   ,hdrpassthruchar38
   ,hdrpassthruchar39
   ,hdrpassthruchar40
   ,hdrpassthruchar41
   ,hdrpassthruchar42
   ,hdrpassthruchar43
   ,hdrpassthruchar44
   ,hdrpassthruchar45
   ,hdrpassthruchar46
   ,hdrpassthruchar47
   ,hdrpassthruchar48
   ,hdrpassthruchar49
   ,hdrpassthruchar50
   ,hdrpassthruchar51
   ,hdrpassthruchar52
   ,hdrpassthruchar53
   ,hdrpassthruchar54
   ,hdrpassthruchar55
   ,hdrpassthruchar56
   ,hdrpassthruchar57
   ,hdrpassthruchar58
   ,hdrpassthruchar59
   ,hdrpassthruchar60
   ,hdrpassthrunum01
   ,hdrpassthrunum02
   ,hdrpassthrunum03
   ,hdrpassthrunum04
   ,hdrpassthrunum05
   ,hdrpassthrunum06
   ,hdrpassthrunum07
   ,hdrpassthrunum08
   ,hdrpassthrunum09
   ,hdrpassthrunum10
   ,hdrpassthrudate01
   ,hdrpassthrudate02
   ,hdrpassthrudate03
   ,hdrpassthrudate04
   ,created
   )
   values
   (in_importfileid
   ,in_seq
   ,in_func
   ,in_shipmentid
   ,in_stop
   ,in_reference
   ,in_hdrpassthruchar01
   ,in_hdrpassthruchar02
   ,in_hdrpassthruchar03
   ,in_hdrpassthruchar04
   ,in_hdrpassthruchar05
   ,in_hdrpassthruchar06
   ,in_hdrpassthruchar07
   ,in_hdrpassthruchar08
   ,in_hdrpassthruchar09
   ,in_hdrpassthruchar10
   ,in_hdrpassthruchar11
   ,in_hdrpassthruchar12
   ,in_hdrpassthruchar13
   ,in_hdrpassthruchar14
   ,in_hdrpassthruchar15
   ,in_hdrpassthruchar16
   ,in_hdrpassthruchar17
   ,in_hdrpassthruchar18
   ,in_hdrpassthruchar19
   ,in_hdrpassthruchar20
   ,in_hdrpassthruchar21
   ,in_hdrpassthruchar22
   ,in_hdrpassthruchar23
   ,in_hdrpassthruchar24
   ,in_hdrpassthruchar25
   ,in_hdrpassthruchar26
   ,in_hdrpassthruchar27
   ,in_hdrpassthruchar28
   ,in_hdrpassthruchar29
   ,in_hdrpassthruchar30
   ,in_hdrpassthruchar31
   ,in_hdrpassthruchar32
   ,in_hdrpassthruchar33
   ,in_hdrpassthruchar34
   ,in_hdrpassthruchar35
   ,in_hdrpassthruchar36
   ,in_hdrpassthruchar37
   ,in_hdrpassthruchar38
   ,in_hdrpassthruchar39
   ,in_hdrpassthruchar40
   ,in_hdrpassthruchar41
   ,in_hdrpassthruchar42
   ,in_hdrpassthruchar43
   ,in_hdrpassthruchar44
   ,in_hdrpassthruchar45
   ,in_hdrpassthruchar46
   ,in_hdrpassthruchar47
   ,in_hdrpassthruchar48
   ,in_hdrpassthruchar49
   ,in_hdrpassthruchar50
   ,in_hdrpassthruchar51
   ,in_hdrpassthruchar52
   ,in_hdrpassthruchar53
   ,in_hdrpassthruchar54
   ,in_hdrpassthruchar55
   ,in_hdrpassthruchar56
   ,in_hdrpassthruchar57
   ,in_hdrpassthruchar58
   ,in_hdrpassthruchar59
   ,in_hdrpassthruchar60
   ,in_hdrpassthrunum01
   ,in_hdrpassthrunum02
   ,in_hdrpassthrunum03
   ,in_hdrpassthrunum04
   ,in_hdrpassthrunum05
   ,in_hdrpassthrunum06
   ,in_hdrpassthrunum07
   ,in_hdrpassthrunum08
   ,in_hdrpassthrunum09
   ,in_hdrpassthrunum10
   ,in_hdrpassthrudate01
   ,in_hdrpassthrudate02
   ,in_hdrpassthrudate03
   ,in_hdrpassthrudate04
   ,systimestamp
   );

exception when others then
  out_msg := 'zimi204order ' || sqlerrm;
  out_errorno := sqlcode;
end import_inbound204_order;

procedure end_of_inbound204_import
(in_importfileid IN varchar2
,in_seq IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is


cursor cur204_load(in_importfileid varchar2, in_seq varchar2) is
  select *
    from import_204_load
   where importfileid = in_importfileid
     and seq = in_seq;
c2l cur204_load%rowtype;

cursor cur_loads(in_bol varchar2) is
   select *
     from loads
    where billoflading = in_bol
      and loadstatus <> 'X';
cl cur_loads%rowtype;

cursor cur204_order(in_importfileid varchar2, in_seq varchar2, in_shipmentid varchar2) is
   select *
     from import_204_order
    where importfileid = in_importfileid
      and seq = in_seq
      and shipmentid = in_shipmentid;

load_exists boolean;
out_loadno loads.loadno%type;
vDate varchar2(255);
dDate date;
cntRows pls_integer;
   procedure iil_log_msg(in_msg in varchar2)
   is
     l_msg varchar2(255);
   begin
     zms.log_autonomous_msg('INBOUND204', null, null, in_msg,'E', 'TENDER', l_msg);
   end iil_log_msg;

   procedure iil_find_orders
      (c2l in cur204_load%rowtype
      ,out_errorno in out number
      ,out_msg in out varchar2)
   is
      cntRows pls_integer;
   begin
      for io in cur204_order(c2l.importfileid, c2l.seq, c2l.billoflading) loop
         select count(1) into cntRows
           from orderhdr
          where reference = io.reference
            and custid = c2l.custid;
         if cntRows = 0 then
            out_errorno := -7;
            out_msg := 'END_OF_INBOUND204_IMPORT order not found: ' || io.reference || ' ' || c2l.billoflading || ' ' ||  in_importfileid;
            return;
         end if;
      end loop;
   end iil_find_orders;

   procedure iil_delete_load
      (c2l in cur204_load%rowtype
      ,cl in cur_loads%rowtype
      ,out_errorno in out number
      ,out_msg in out varchar2)
   is
      cursor cur_orderhdr(in_loadno number) is
         select *
           from orderhdr
          where loadno = in_loadno;
   begin
      for oh in cur_orderhdr(cl.loadno) loop
         zld.deassign_order_from_load(oh.orderid, oh.shipid, oh.fromfacility, 'INBOUND204', 'N', out_errorno, out_msg);
         if out_msg <> 'OKAY' then
            return;
         end if;
      end loop;
      zld.cancel_load(cl.loadno, cl.facility, 'INBOUND204', out_msg);
   end iil_delete_load;

   procedure iil_build_load
      (c2l in cur204_load%rowtype
      ,out_loadno out number
      ,out_errorno in out number
      ,out_msg in out varchar2)
   is
      iil_orderid orderhdr.orderid%type;
      iil_shipid orderhdr.shipid%type;
      io_loadno loads.loadno%type;
      io_stopno loadstop.stopno%type;
      io_shipno loadstopship.shipno%type;

   begin
      io_loadno := 0;
      for o204 in cur204_order(c2l.importfileid, c2l.seq, c2l.billoflading) loop
         select orderid, shipid into iil_orderid, iil_shipid
            from orderhdr
          where reference = o204.reference
            and custid = c2l.custid;
         io_shipno := 1;
         io_stopno := -1 * o204.stop;
         update orderhdr
            set carrier = c2l.carrier,
                shiptype = c2l.shiptype,
                shipterms = c2l.shipterms
          where orderid = iil_orderid
            and shipid = iil_shipid;

         zld.assign_outbound_order_to_load(iil_orderid, iil_shipid, c2l.carrier, null,
            null, c2l.billoflading, null, null, c2l.facility, 'INBOUND204', io_loadno,
            io_stopno, io_shipno, out_msg);
         if out_msg <> 'OKAY' then
            out_errorno := -8;
            return;
         end if;

         out_loadno := io_loadno;
      end loop;
      /* update load and loadstop(s) */
   end iil_build_load;

begin
   out_msg := 'OKAY';
   out_errorno := 0;
   --iil_log_msg('END_OF_INBOUND204_IMPORT ' || in_seq || ' <> ' ||in_importfileid);

   select count(1) into cntRows
     from import_204_load
    where importfileid = in_importfileid
      and seq = in_seq;
   if cntRows = 0 then
         out_msg := 'end_of_inbound204_import import_204_load not found ' || in_importfileid;
         return;
   end if;

   for c2l in cur204_load(in_importfileid, in_seq) loop
      open cur_loads(c2l.billoflading);
      fetch cur_loads into cl;
      if cur_loads%notfound then
         load_exists := false;
      else
         load_exists := true;
      end if;
      close cur_loads;

      if c2l.func = 'D' and
         not load_exists then
         iil_log_msg('END_OF_INBOUND204_IMPORT load not found for deletion ' || c2l.billoflading || ' ' ||  in_importfileid);
         continue;
      end if;

      if load_exists and
         cl.loadstatus not in ('1', '2', '3', '4', '5', '6') then
         iil_log_msg('END_OF_INBOUND204_IMPORT invalid status: ' || cl.loadstatus || ' for delete/replace ' || c2l.seq || ' ' || c2l.billoflading || ' ' ||  in_importfileid);
         continue;
      end if;
      if c2l.func != 'D' then
         iil_find_orders(c2l, out_errorno, out_msg);
         if out_msg != 'OKAY' then
            iil_log_msg(out_msg);
            out_errorno := 0;
            out_msg := 'OKAY';
            continue;
         end if;
      end if;
      if load_exists  then
         iil_delete_load(c2l, cl, out_errorno, out_msg);
         if out_msg != 'OKAY' then
            iil_log_msg(out_msg);
            out_errorno := 0;
            out_msg := 'OKAY';
            continue;
         end if;
      end if;
      if c2l.func != 'D' then
         iil_build_load(c2l, out_loadno, out_errorno, out_msg);
         if out_msg != 'OKAY' then
            iil_log_msg(out_msg);
            out_errorno := 0;
            out_msg := 'OKAY';
            continue;
         end if;
         update loads
            set shiptype = nvl(shiptype, c2l.shiptype),
                shipterms = nvl(shipterms, c2l.shipterms),
                appointmentdate = nvl(appointmentdate, c2l.appointmentdate),
                comment1 = nvl(comment1, c2l.comment1),
                ldpassthruchar01 = nvl(ldpassthruchar01, c2l.ldpassthruchar01),
                ldpassthruchar02 = nvl(ldpassthruchar02, c2l.ldpassthruchar02),
                ldpassthruchar03 = nvl(ldpassthruchar03, c2l.ldpassthruchar03),
                ldpassthruchar04 = nvl(ldpassthruchar04, c2l.ldpassthruchar04),
                ldpassthruchar05 = nvl(ldpassthruchar05, c2l.ldpassthruchar05),
                ldpassthruchar06 = nvl(ldpassthruchar06, c2l.ldpassthruchar06),
                ldpassthruchar07 = nvl(ldpassthruchar07, c2l.ldpassthruchar07),
                ldpassthruchar08 = nvl(ldpassthruchar08, c2l.ldpassthruchar08),
                ldpassthruchar09 = nvl(ldpassthruchar09, c2l.ldpassthruchar09),
                ldpassthruchar10 = nvl(ldpassthruchar10, c2l.ldpassthruchar10),
                ldpassthruchar11 = nvl(ldpassthruchar11, c2l.ldpassthruchar11),
                ldpassthruchar12 = nvl(ldpassthruchar12, c2l.ldpassthruchar12),
                ldpassthruchar13 = nvl(ldpassthruchar13, c2l.ldpassthruchar13),
                ldpassthruchar14 = nvl(ldpassthruchar14, c2l.ldpassthruchar14),
                ldpassthruchar15 = nvl(ldpassthruchar15, c2l.ldpassthruchar15),
                ldpassthruchar16 = nvl(ldpassthruchar16, c2l.ldpassthruchar16),
                ldpassthruchar17 = nvl(ldpassthruchar17, c2l.ldpassthruchar17),
                ldpassthruchar18 = nvl(ldpassthruchar18, c2l.ldpassthruchar18),
                ldpassthruchar19 = nvl(ldpassthruchar19, c2l.ldpassthruchar19),
                ldpassthruchar20 = nvl(ldpassthruchar20, c2l.ldpassthruchar20),
                ldpassthruchar21 = nvl(ldpassthruchar21, c2l.ldpassthruchar21),
                ldpassthruchar22 = nvl(ldpassthruchar22, c2l.ldpassthruchar22),
                ldpassthruchar23 = nvl(ldpassthruchar23, c2l.ldpassthruchar23),
                ldpassthruchar24 = nvl(ldpassthruchar24, c2l.ldpassthruchar24),
                ldpassthruchar25 = nvl(ldpassthruchar25, c2l.ldpassthruchar25),
                ldpassthruchar26 = nvl(ldpassthruchar26, c2l.ldpassthruchar26),
                ldpassthruchar27 = nvl(ldpassthruchar27, c2l.ldpassthruchar27),
                ldpassthruchar28 = nvl(ldpassthruchar28, c2l.ldpassthruchar28),
                ldpassthruchar29 = nvl(ldpassthruchar29, c2l.ldpassthruchar29),
                ldpassthruchar30 = nvl(ldpassthruchar30, c2l.ldpassthruchar30),
                ldpassthruchar31 = nvl(ldpassthruchar31, c2l.ldpassthruchar31),
                ldpassthruchar32 = nvl(ldpassthruchar32, c2l.ldpassthruchar32),
                ldpassthruchar33 = nvl(ldpassthruchar33, c2l.ldpassthruchar33),
                ldpassthruchar34 = nvl(ldpassthruchar34, c2l.ldpassthruchar34),
                ldpassthruchar35 = nvl(ldpassthruchar35, c2l.ldpassthruchar35),
                ldpassthruchar36 = nvl(ldpassthruchar36, c2l.ldpassthruchar36),
                ldpassthruchar37 = nvl(ldpassthruchar37, c2l.ldpassthruchar37),
                ldpassthruchar38 = nvl(ldpassthruchar38, c2l.ldpassthruchar38),
                ldpassthruchar39 = nvl(ldpassthruchar39, c2l.ldpassthruchar39),
                ldpassthruchar40 = nvl(ldpassthruchar40, c2l.ldpassthruchar40),
                ldpassthrudate01 = nvl(ldpassthrudate01, c2l.ldpassthrudate01),
                ldpassthrudate02 = nvl(ldpassthrudate02, c2l.ldpassthrudate02),
                ldpassthrudate03 = nvl(ldpassthrudate03, c2l.ldpassthrudate03),
                ldpassthrudate04 = nvl(ldpassthrudate04, c2l.ldpassthrudate04),
                ldpassthrunum01 = nvl(ldpassthrunum01, c2l.ldpassthrunum01),
                ldpassthrunum02 = nvl(ldpassthrunum02, c2l.ldpassthrunum02),
                ldpassthrunum03 = nvl(ldpassthrunum03, c2l.ldpassthrunum03),
                ldpassthrunum04 = nvl(ldpassthrunum04, c2l.ldpassthrunum04),
                ldpassthrunum05 = nvl(ldpassthrunum05, c2l.ldpassthrunum05),
                ldpassthrunum06 = nvl(ldpassthrunum06, c2l.ldpassthrunum06),
                ldpassthrunum07 = nvl(ldpassthrunum07, c2l.ldpassthrunum07),
                ldpassthrunum08 = nvl(ldpassthrunum08, c2l.ldpassthrunum08),
                ldpassthrunum09 = nvl(ldpassthrunum09, c2l.ldpassthrunum09),
                ldpassthrunum10 = nvl(ldpassthrunum10, c2l.ldpassthrunum10)
          where loadno = out_loadno;
         for c2s in (select * from import_204_stop
                      where importfileid = c2l.importfileid
                        and seq = c2l.seq
                        and shipmentid = c2l.billoflading) loop
            vDate := c2s.delappt_date || c2s.delappt_time;
            begin
               dDate := to_date(vdate, c2s.date_format);
            exception when others then
               dDate := null;
            end;
            if dDate is not null then
               update loadstop
                 set delappt = dDate
               where loadno = out_loadno
                 and stopno = c2s.stop;
            end if;
         end loop;
      end if;

   end loop;

exception when others then
   out_msg := 'eoii ' || sqlerrm;
   out_errorno := sqlcode;
end end_of_inbound204_import;


end zimportproc8;
/
show error package body zimportproc8;
exit;
