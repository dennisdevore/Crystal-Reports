create or replace package body alps.zimportprocfreight as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

function case_count
(in_loadno IN number
,in_hdrpassthruchar02 IN varchar2
) return number

is

cursor curItemSum is
  select custid,item,unitofmeasure,sum(nvl(quantity,0)) as quantity
    from shippingplate sp
   where sp.loadno = in_loadno
     and exists (select *
                   from orderhdr oh
                  where oh.orderid = sp.orderid
                    and oh.shipid = sp.shipid
                    and nvl(oh.hdrpassthruchar02,'x') =
                        nvl(in_hdrpassthruchar02,'x') )
     and sp.type in ('F','P')
     and zmp.shipplate_type(sp.parentlpid) != 'C'
   group by custid,item,unitofmeasure;

out_count shippingplate.quantity%type;
numEquivQty shippingplate.quantity%type;

begin

out_count := 0;

for cc in curItemSum
loop
  numEquivQty :=
      nvl(zcu.equiv_uom_qty(cc.custid,cc.Item,cc.UnitOfMeasure,cc.Quantity,'CS'),0);
  if numEquivQty = cc.quantity and
     cc.unitofmeasure != 'CS' then
    numEquivQty := 1;
  end if;
  if numEquivQty = 0 then
    numEquivQty := cc.quantity;
  end if;
  out_count := out_count + numEquivQty;
end loop;

return out_count;

exception when others then
  return out_count;
end;

function carton_count
(in_loadno IN number
,in_hdrpassthruchar02 IN varchar2
) return number

is

cursor curStandAlone is
  select count(1) as count
    from shippingplate sp
   where sp.loadno = in_loadno
     and exists (select *
                   from orderhdr oh
                  where oh.orderid = sp.orderid
                    and oh.shipid = sp.shipid
                    and nvl(oh.hdrpassthruchar02,'x') =
                        nvl(in_hdrpassthruchar02,'x') )
     and type = 'C'
     and parentlpid is null;

cursor curOnMaster is
  select distinct parentlpid
    from shippingplate sp
   where sp.loadno = in_loadno
     and exists (select *
                   from orderhdr oh
                  where oh.orderid = sp.orderid
                    and oh.shipid = sp.shipid
                    and nvl(oh.hdrpassthruchar02,'x') =
                        nvl(in_hdrpassthruchar02,'x') )
     and type = 'C'
     and parentlpid is not null;
out_count shippingplate.quantity%type;
numEquivQty shippingplate.quantity%type;

begin

out_count := 0;

for sa in curStandAlone
loop
  out_count := sa.count;
end loop;

for om in curOnMaster
loop
  out_count := out_count + 1;
end loop;

return out_count;

exception when others then
  return out_count;
end;

procedure begin_freight_aims_format
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_consolidate_field IN varchar2
,in_detail_extract IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select *
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid
     and orderstatus = '9';
oh1 curOrderHdr%rowtype;
oh1st curOrderHdr%rowtype;

cursor curCustomer is
  select custid,name,city,state,postalcode
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curFacility(in_facility varchar2) is
  select facility,
         name,
         countrycode
    from facility
   where facility = in_facility;
fa curFacility%rowtype;


cursor curConsignee (in_shipto varchar2)
is
  select *
    from consignee
   where consignee = in_shipto;
co curConsignee%rowtype;

cursor curLoads(in_loadno number) is
  select *
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strSuffix varchar2(32);
viewcount integer;
strDebugYN char(1);
cntDtl integer;
sumQty integer;
dteTest date;
aims_st freight_aims_st%rowtype;
aims_bol freight_aims_bol%rowtype;
aims_b2a freight_aims_b2a%rowtype;
aims_g62 freight_aims_g62%rowtype;
aims_k1 freight_aims_k1%rowtype;
aims_n1 freight_aims_n1%rowtype;
aims_n4 freight_aims_n4%rowtype;
aims_at1 freight_aims_at1%rowtype;
aims_at2 freight_aims_at2%rowtype;
aims_se freight_aims_se%rowtype;
aims_cod freight_aims_cod%rowtype;
aims_itd freight_aims_itd%rowtype;
seq_number integer;
strseq_number varchar2(4);
strdetail_number varchar2(5);
curSql integer;
curAt2 integer;
numOrderId number;
numShipId number;
strShipto_Link orderhdr.hdrpassthruchar01%type;
numPalletQuantity number;
numPiecesQuantity number;
numWeightShip number;
strItem shippingplate.item%type;
strLpid shippingplate.lpid%type;
strUnitOfMeasure shippingplate.unitofmeasure%type;
numQuantity shippingplate.quantity%type;
numEquivQty shippingplate.quantity%type;
numCartonCount shippingplate.quantity%type;
loadcarrier carrier.carrier%type;
multiship carrier.multiship%type;


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

function find_aims_sequence(in_custid varchar2)
return integer
is

out_sequence integer;
begin

  debugmsg('begin find aims sequence');
  begin
    select count(1)
      into out_sequence
      from user_objects
     where object_name = 'AIMSSEQ' || upper(in_custid);
  exception when others then
    out_sequence := 0;
  end;

  if out_sequence = 0 then
    debugmsg('create sequence');
    execute immediate
      'create sequence ' || 'aimsseq' || upper(in_custid) ||
      ' increment by 1 ' ||
       'start with 1000 maxvalue 999999999 minvalue 1 nocache cycle ';
  end if;

  execute immediate
    'select aimsseq' || in_custid || '.nextval from dual'
    into out_sequence;

  debugmsg('out sequence is ' || out_sequence);
  return out_sequence;
exception when others then
  debugmsg(sqlerrm);
  out_sequence := 0;
end;

procedure add_aims_st_row is
begin

debugmsg('add aims_st_row ' || aims_st.controlno);

if aims_st.ShipTo_Link is null then
  debugmsg('skip st insert');
  return;
end if;

aims_st.controlno := find_aims_sequence(oh1st.custid);
aims_st.facility := oh1st.fromfacility;
debugmsg('control no is ' || aims_st.controlno);

execute immediate 'insert into FREIGHT_AIMS_ST_' || strSuffix ||
' values (:LOADNO,:CUSTID,:FACILITY,:SHIPTO_LINK,:CONTROLNO )'
using aims_st.LOADNO,aims_st.custid,aims_st.facility,aims_st.SHIPTO_LINK,aims_st.CONTROLNO;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_bol_row is
begin

debugmsg('add aims_bol_row ' || aims_st.controlno);

aims_bol.carrier := nvl(ld.carrier,oh1st.carrier);
aims_bol.shipterms := nvl(ld.shipterms,oh1st.shipterms);
aims_bol.orderid := oh1st.orderid;
aims_bol.shipid := oh1st.shipid;
aims_bol.facility := oh1st.fromfacility;
aims_bol.shipdate := nvl(ld.statusupdate,oh1st.statusupdate);
if nvl(oh1st.prono,ld.prono) is null then
  aims_bol.prono := 'N' || trim(to_char(oh1st.orderid));
  while length(aims_bol.prono) < 7
  loop
    aims_bol.prono := '0' || aims_bol.prono;
  end loop;
  if oh1st.shipid < 100 then
    aims_bol.prono := aims_bol.prono || '0';
  end if;
  aims_bol.prono := aims_bol.prono || trim(to_char(oh1st.shipid));
else
  aims_bol.prono := nvl(oh1st.prono,ld.prono);
end if;
execute immediate 'insert into FREIGHT_AIMS_BOL_' || strSuffix ||
' values (:LOADNO,:CUSTID,:FACILITY,:SHIPTO_LINK,:CARRIER,:SHIPTERMS,:ORDERID,:SHIPID,' ||
' :SHIPDATE,:PRONO,:HDRPASSTHRUCHAR01,:HDRPASSTHRUCHAR02,:HDRPASSTHRUCHAR03,' ||
':HDRPASSTHRUCHAR04,:HDRPASSTHRUCHAR05,:HDRPASSTHRUCHAR06,:HDRPASSTHRUCHAR07,' ||
':HDRPASSTHRUCHAR08,:HDRPASSTHRUCHAR09,:HDRPASSTHRUCHAR10,:HDRPASSTHRUCHAR11,' ||
':HDRPASSTHRUCHAR12,:HDRPASSTHRUCHAR13,:HDRPASSTHRUCHAR14,:HDRPASSTHRUCHAR15,' ||
':HDRPASSTHRUCHAR16,:HDRPASSTHRUCHAR17,:HDRPASSTHRUCHAR18,:HDRPASSTHRUCHAR19,' ||
':HDRPASSTHRUCHAR20,:HDRPASSTHRUNUM01,:HDRPASSTHRUNUM02,:HDRPASSTHRUNUM03,' ||
':HDRPASSTHRUNUM04,:HDRPASSTHRUNUM05,:HDRPASSTHRUNUM06,:HDRPASSTHRUNUM07,' ||
':HDRPASSTHRUNUM08,:HDRPASSTHRUNUM09,:HDRPASSTHRUNUM10,:HDRPASSTHRUDATE01,' ||
':HDRPASSTHRUDATE02,:HDRPASSTHRUDATE03,:HDRPASSTHRUDATE04,:HDRPASSTHRUDOLL01,' ||
':HDRPASSTHRUDOLL02, :PO, :BILLOFLADING )'
using aims_bol.LOADNO,aims_bol.custid,aims_bol.facility,
aims_bol.SHIPTO_LINK,aims_bol.CARRIER,aims_bol.SHIPTERMS,aims_bol.ORDERID,
aims_bol.SHIPID,aims_bol.SHIPDATE,aims_bol.PRONO,
oh1st.HDRPASSTHRUCHAR01,oh1st.HDRPASSTHRUCHAR02,
oh1st.HDRPASSTHRUCHAR03,oh1st.HDRPASSTHRUCHAR04,oh1st.HDRPASSTHRUCHAR05,oh1st.HDRPASSTHRUCHAR06,
oh1st.HDRPASSTHRUCHAR07,oh1st.HDRPASSTHRUCHAR08,oh1st.HDRPASSTHRUCHAR09,oh1st.HDRPASSTHRUCHAR10,
oh1st.HDRPASSTHRUCHAR11,oh1st.HDRPASSTHRUCHAR12,oh1st.HDRPASSTHRUCHAR13,oh1st.HDRPASSTHRUCHAR14,
oh1st.HDRPASSTHRUCHAR15,oh1st.HDRPASSTHRUCHAR16,oh1st.HDRPASSTHRUCHAR17,oh1st.HDRPASSTHRUCHAR18,
oh1st.HDRPASSTHRUCHAR19,oh1st.HDRPASSTHRUCHAR20,oh1st.HDRPASSTHRUNUM01,oh1st.HDRPASSTHRUNUM02,
oh1st.HDRPASSTHRUNUM03,oh1st.HDRPASSTHRUNUM04,oh1st.HDRPASSTHRUNUM05,oh1st.HDRPASSTHRUNUM06,
oh1st.HDRPASSTHRUNUM07,oh1st.HDRPASSTHRUNUM08,oh1st.HDRPASSTHRUNUM09,oh1st.HDRPASSTHRUNUM10,
oh1st.HDRPASSTHRUDATE01,oh1st.HDRPASSTHRUDATE02,oh1st.HDRPASSTHRUDATE03,oh1st.HDRPASSTHRUDATE04,
oh1st.HDRPASSTHRUDOLL01,oh1st.HDRPASSTHRUDOLL02, oh1st.PO, oh1st.BILLOFLADING;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_b2a_row is
begin

debugmsg('add aims_bol_row ' || aims_st.controlno);

aims_b2a.purpose_code := '00';

execute immediate 'insert into FREIGHT_AIMS_B2A_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:PURPOSE_CODE )'
using aims_b2a.LOADNO,aims_b2a.custid,aims_b2a.SHIPTO_LINK,aims_b2a.PURPOSE_CODE;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_g62_row is
begin

debugmsg('add aims_g62_row ' || aims_st.controlno);
aims_g62.date_qualifier := '11';
aims_g62.date_value := nvl(ld.statusupdate,oh1st.statusupdate);

execute immediate 'insert into FREIGHT_AIMS_G62_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:DATE_QUALIFIER,:DATE_VALUE )'
using aims_g62.LOADNO,aims_g62.custid,aims_g62.SHIPTO_LINK,aims_g62.DATE_QUALIFIER,aims_g62.DATE_VALUE;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_k1_row is
begin

debugmsg('add aims_k1_row ' || aims_st.controlno);

aims_k1.comment1 := substr(oh1st.comment1,1,255);

execute immediate 'insert into FREIGHT_AIMS_K1_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:COMMENT1 )'
using aims_k1.LOADNO,aims_k1.custid,aims_k1.SHIPTO_LINK,aims_k1.COMMENT1;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_n1_row is
begin

debugmsg('add aims_n1_row ' || aims_st.controlno);

aims_n1.entity_identifier := 'ST';
if oh1st.shipto is not null then
  co := null;
  open curConsignee(oh1st.shipto);
  fetch curConsignee into co;
  close curConsignee;
  aims_n1.name := co.name;
else
  aims_n1.name := oh1st.shiptoname;
end if;
aims_n1.code_qualifier := '94';
aims_n1.code_value := aims_n1.ShipTo_Link;
aims_n1.orderid := oh1st.orderid;
aims_n1.shipid := oh1st.shipid;

execute immediate 'insert into FREIGHT_AIMS_N1_' || strSuffix ||
' values (:LOADNO,:CUSTID,:ORDERID,:SHIPID,'||
' :SHIPTO_LINK,:ENTITY_IDENTIFIER,:NAME,' ||
' :CODE_QUALIFIER,:CODE_VALUE )'
using aims_n1.LOADNO,aims_n1.custid,aims_n1.orderid,aims_n1.shipid,
    aims_n1.SHIPTO_LINK,aims_n1.ENTITY_IDENTIFIER,aims_n1.NAME,
    aims_n1.CODE_QUALIFIER,aims_n1.CODE_VALUE;

aims_se.total_segments := aims_se.total_segments + 1;

aims_n1.entity_identifier := 'SF';
aims_n1.name := cu.name;
aims_n1.code_qualifier := '94';
aims_n1.code_value := '1025';

execute immediate 'insert into FREIGHT_AIMS_N1_' || strSuffix ||
' values (:LOADNO,:CUSTID,:ORDERID,:SHIPID,'||
' :SHIPTO_LINK,:ENTITY_IDENTIFIER,:NAME,' ||
' :CODE_QUALIFIER,:CODE_VALUE )'
using aims_n1.LOADNO,aims_n1.custid,aims_n1.orderid,aims_n1.shipid,
    aims_n1.SHIPTO_LINK,aims_n1.ENTITY_IDENTIFIER,aims_n1.NAME,
    aims_n1.CODE_QUALIFIER,aims_n1.CODE_VALUE;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_n4_row is
begin

debugmsg('add aims_n4_row ' || aims_st.controlno);

aims_n4.entity_identifier := 'ST';
if oh1st.shipto is not null then
  aims_n4.city_name := co.city;
  aims_n4.state_code := co.state;
  aims_n4.postalcode := co.postalcode;
else
  aims_n4.city_name := oh1st.shiptocity;
  aims_n4.state_code := oh1st.shiptostate;
  aims_n4.postalcode := oh1st.shiptopostalcode;
end if;

execute immediate 'insert into FREIGHT_AIMS_N4_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:ENTITY_IDENTIFIER,:CITY_NAME,:STATE_CODE,' ||
' :POSTALCODE )'
using aims_n4.LOADNO,aims_n4.custid,aims_n4.SHIPTO_LINK,aims_n4.ENTITY_IDENTIFIER,aims_n4.CITY_NAME,
aims_n4.STATE_CODE,aims_n4.POSTALCODE;

aims_se.total_segments := aims_se.total_segments + 1;

aims_n4.entity_identifier := 'SF';
aims_n4.city_name := cu.city;
aims_n4.state_code := cu.state;
aims_n4.postalcode := cu.postalcode;

execute immediate 'insert into FREIGHT_AIMS_N4_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:ENTITY_IDENTIFIER,:CITY_NAME,:STATE_CODE,' ||
' :POSTALCODE )'
using aims_n4.LOADNO,aims_n4.custid,aims_n4.SHIPTO_LINK,aims_n4.ENTITY_IDENTIFIER,aims_n4.CITY_NAME,
aims_n4.STATE_CODE,aims_n4.POSTALCODE;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_at1_row is
begin

debugmsg('add aims_at1_row ' || aims_st.controlno);

aims_at1.line_item_number := '1';

execute immediate 'insert into FREIGHT_AIMS_AT1_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:LINE_ITEM_NUMBER )'
using aims_at1.LOADNO,aims_at1.custid,aims_at1.SHIPTO_LINK,aims_at1.LINE_ITEM_NUMBER;

aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_at2_row is
begin

debugmsg('add aims_at2_row ' || aims_st.controlno);

aims_at2.pallet_quantity := 0;
if nvl(oh1st.loadno,0) <> 0 then
  cmdSql := 'select sum(nvl(outpallets,0)) ' ||
    ' from pallethistory ph where ph.loadno = ' || oh1st.loadno  ||
    ' and ph.custid = ''' || oh1st.custid || '''' ||
    ' and ph.facility = ''' || oh1st.fromfacility || '''' ||
    ' and exists (select * from orderhdr oh where oh.orderid = ph.orderid ' ||
    ' and oh.shipid =  ph.shipid ' ||
    ' and nvl(to_char(oh.' || in_consolidate_field || '),''x'') = ''' ||
    aims_at2.ShipTo_Link || ''')';
  debugmsg(cmdSql);
  begin
    curAt2 := dbms_sql.open_cursor;
    dbms_sql.parse(curAt2, cmdSql, dbms_sql.native);
    dbms_sql.define_column(curAt2,1,numPalletQuantity);
    cntRows := dbms_sql.execute(curAt2);
    cntRows := dbms_sql.fetch_rows(curAt2);
    if cntRows > 0 then
      dbms_sql.column_value(curAt2,1,numPalletQuantity);
      aims_at2.pallet_quantity := numPalletQuantity;
    end if;
    dbms_sql.close_cursor(curAt2);
  exception when others then
    debugmsg(sqlerrm);
    dbms_sql.close_cursor(curAt2);
  end;
/*
  aims_at2.pallet_quantity :=
     zimfreight.case_count(oh1st.loadno,aims_at2.shipto_link)
   + zimfreight.carton_count(oh1st.loadno,aims_at2.shipto_link);
*/
end if;

aims_at2.pallet_form_code := 'PLT';
aims_at2.weight_qualifier := 'G';
aims_at2.weight_unit_code := 'L';
aims_at2.weight := 0;
cmdSql := 'select sum(nvl(weightship,0)) ' ||
  ' from orderhdr oh  where oh.custid = ''' || oh1st.custid || '''';
if nvl(oh1st.loadno,0) <> 0 then
  cmdSql := cmdSql || ' and oh.loadno = ' || oh1st.loadno;
else
  cmdSql := cmdSql || ' and oh.orderid = ' || oh1st.orderid ||
    ' and oh.shipid = ' || oh1st.shipid;
end if;
cmdSql := cmdSql ||
  ' and nvl(to_char(oh.' || in_consolidate_field || '),''x'') = ''' ||
  aims_at2.ShipTo_Link || '''';
debugmsg(cmdSql);
begin
  curAt2 := dbms_sql.open_cursor;
  dbms_sql.parse(curAt2, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curAt2,1,numWeightShip);
  cntRows := dbms_sql.execute(curAt2);
  cntRows := dbms_sql.fetch_rows(curAt2);
  if cntRows > 0 then
    dbms_sql.column_value(curAt2,1,numWeightShip);
    aims_at2.weight := numWeightShip;
  end if;
  dbms_sql.close_cursor(curAt2);
exception when others then
  debugmsg(sqlerrm);
  dbms_sql.close_cursor(curAt2);
end;
aims_at2.weight := aims_at2.weight + (65 * aims_at2.pallet_quantity);
if abs(aims_at2.weight) <> aims_at2.weight then
  aims_at2.weight := floor(aims_at2.weight + 1);
end if;

aims_at2.pieces_quantity := 0;
cmdSql := 'select sum(nvl(quantity,0))  ' ||
  ' from shippingplate sp where sp.custid = ''' || oh1st.custid || '''';
if nvl(oh1st.loadno,0) <> 0 then
  cmdSql := cmdSql || ' and sp.loadno = ' || oh1st.loadno ||
    ' and exists (select * from orderhdr oh where oh.orderid = sp.orderid ' ||
    ' and oh.shipid =  sp.shipid ' ||
    ' and nvl(to_char(oh.' || in_consolidate_field || '),''x'') = ''' ||
    aims_at2.ShipTo_Link || ''')';
  cmdSql := cmdSql || ' and (sp.type = ''M'') ';
else
  cmdSql := cmdSql || ' and sp.orderid = ' || oh1st.orderid ||
   ' and sp.shipid = ' || oh1st.shipid;
  cmdSql := cmdSql || ' and sp.parentlpid is null ';
end if;


debugmsg(cmdSql);

begin
  curAt2 := dbms_sql.open_cursor;
  dbms_sql.parse(curAt2, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curAt2,1,numPiecesQuantity);
  cntRows := dbms_sql.execute(curAt2);
  cntRows := dbms_sql.fetch_rows(curAt2);
  if cntRows > 0 then
    dbms_sql.column_value(curAt2,1,numPiecesQuantity);
    aims_at2.pieces_quantity := numPiecesQuantity;
  end if;
  dbms_sql.close_cursor(curAt2);
exception when others then
  debugmsg(sqlerrm);
  dbms_sql.close_cursor(curAt2);
end;

aims_at2.pieces_form_code := 'CTN';

aims_at2.cases_quantity := 0;
cmdSql := 'select item,unitofmeasure,sum(nvl(quantity,0))  ' ||
  ' from shippingplate sp where sp.custid = ''' || oh1st.custid || '''';
if nvl(oh1st.loadno,0) <> 0 then
  cmdSql := cmdSql || ' and sp.loadno = ' || oh1st.loadno ||
    ' and exists (select * from orderhdr oh where oh.orderid = sp.orderid ' ||
    ' and oh.shipid =  sp.shipid ' ||
    ' and nvl(to_char(oh.' || in_consolidate_field || '),''x'') = ''' ||
    aims_at2.ShipTo_Link || ''')';
  cmdSql := cmdSql || ' and (sp.type in (''P'',''F'')) ';
else
  cmdSql := cmdSql || ' and sp.orderid = ' || oh1st.orderid ||
   ' and sp.shipid = ' || oh1st.shipid;
  cmdSql := cmdSql || ' and sp.type in (''P'',''F'')';
end if;
cmdSql := cmdSql || ' and zmp.shipplate_type(parentlpid) !=  ''C''';
cmdSql := cmdSql || ' group by item,unitofmeasure';
debugmsg(cmdSql);
begin
  curAt2 := dbms_sql.open_cursor;
  dbms_sql.parse(curAt2, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curAt2,1,strItem,40);
  dbms_sql.define_column(curAt2,2,strUnitOfMeasure,4);
  dbms_sql.define_column(curAt2,3,numQuantity);
  cntRows := dbms_sql.execute(curAt2);
  cntRows := dbms_sql.fetch_rows(curAt2);
  debugmsg('cnt rows is ' || cntRows);
  while cntRows > 0
  loop
    dbms_sql.column_value(curAt2,1,strItem);
    dbms_sql.column_value(curAt2,2,strUnitOfMeasure);
    dbms_sql.column_value(curAt2,3,numQuantity);
    debugmsg('item is ' || strItem);
    debugmsg('uom is ' || strUnitOfMeasure);
    debugmsg('qty is ' || numQuantity);
    numEquivQty :=
      nvl(zcu.equiv_uom_qty(oh1st.custid,strItem,strUnitOfMeasure,numQuantity,'CS'),0);
    if numEquivQty = numQuantity and
       strUnitOfMeasure != 'CS' then
      debugmsg('No case equivalent for uom ' || strUnitOfMeasure);
      numEquivQty := 1;
    end if;
    if numEquivQty = 0 then
      numEquivQty := numQuantity;
      debugmsg('Equity qty is zero');
    end if;
    debugmsg('equiv qty is ' || numEquivQty);
    aims_at2.cases_quantity := aims_at2.cases_quantity + numEquivQty;
    cntRows := dbms_sql.fetch_rows(curAt2);
  end loop;
  dbms_sql.close_cursor(curAt2);
exception when others then
  debugmsg(sqlerrm);
  dbms_sql.close_cursor(curAt2);
end;

cmdSql := 'select lpid ' ||
  ' from shippingplate sp where sp.custid = ''' || oh1st.custid || '''';
if nvl(oh1st.loadno,0) <> 0 then
  cmdSql := cmdSql || ' and sp.loadno = ' || oh1st.loadno ||
    ' and exists (select * from orderhdr oh where oh.orderid = sp.orderid ' ||
    ' and oh.shipid =  sp.shipid ' ||
    ' and nvl(to_char(oh.' || in_consolidate_field || '),''x'') = ''' ||
    aims_at2.ShipTo_Link || ''')';
else
  cmdSql := cmdSql || ' and sp.orderid = ' || oh1st.orderid ||
   ' and sp.shipid = ' || oh1st.shipid;
end if;
cmdSql := cmdSql || ' and type =  ''C'' and parentlpid is null';
debugmsg(cmdSql);
begin
  curAt2 := dbms_sql.open_cursor;
  dbms_sql.parse(curAt2, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curAt2,1,strLpid,15);
  cntRows := dbms_sql.execute(curAt2);
  cntRows := dbms_sql.fetch_rows(curAt2);
  debugmsg('cnt rows is ' || cntRows);
  while cntRows > 0
  loop
    dbms_sql.column_value(curAt2,1,strLpid);
    debugmsg('carton lpid is ' || strLpid);
    aims_at2.cases_quantity := aims_at2.cases_quantity + 1;
    cntRows := dbms_sql.fetch_rows(curAt2);
  end loop;
  dbms_sql.close_cursor(curAt2);
exception when others then
  debugmsg(sqlerrm);
  dbms_sql.close_cursor(curAt2);
end;

debugmsg(' perform at2 insert');
execute immediate 'insert into FREIGHT_AIMS_AT2_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:PALLET_QUANTITY,:PALLET_FORM_CODE,' ||
' :WEIGHT_QUALIFIER,:WEIGHT_UNIT_CODE,:WEIGHT,:PIECES_QUANTITY,:PIECES_FORM_CODE,' ||
' :CASES_QUANTITY ' ||
')'
using aims_at2.LOADNO,aims_at2.custid,aims_at2.SHIPTO_LINK,aims_at2.PALLET_QUANTITY,aims_at2.PALLET_FORM_CODE,
aims_at2.WEIGHT_QUALIFIER,aims_at2.WEIGHT_UNIT_CODE,aims_at2.WEIGHT,aims_at2.PIECES_QUANTITY,
aims_at2.PIECES_FORM_CODE, aims_at2.cases_quantity;

aims_se.total_segments := aims_se.total_segments + 1;

debugmsg('end add at2 row');
exception when others then
  zut.prt(sqlerrm);
end;

procedure add_aims_se_row is
begin

if aims_st.controlno is null then
  return;
end if;

debugmsg('add aims se ' || aims_st.controlno);

aims_se.controlno := aims_st.controlno;
aims_se.total_segments := aims_se.total_segments + 1;

execute immediate 'insert into FREIGHT_AIMS_SE_' || strSuffix ||
' values (:LOADNO,:CUSTID,:SHIPTO_LINK,:TOTAL_SEGMENTS,:CONTROLNO )'
using aims_se.LOADNO,aims_se.custid,aims_se.SHIPTO_LINK,aims_se.TOTAL_SEGMENTS,aims_se.CONTROLNO;


end;


procedure add_aims_cod_row is
CURSOR C_CON(IN_CONSIGNEE VARCHAR2)
is
SELECT *
  FROM consignee
 WHERE consignee = in_consignee;

CON consignee%rowtype;
begin


if nvl(in_detail_extract,'N') != 'Y' then
    return;
end if;

debugmsg('add aims_cod_row ' || aims_st.controlno);

CON := null;

OPEN C_CON(oh1st.consignee);
FETCH C_CON into CON;
CLOSE C_CON;

    aims_cod.billtoname := nvl(CON.name,oh1st.billtoname);
    aims_cod.billtocontact := nvl(CON.contact,oh1st.billtocontact);
    aims_cod.billtoaddr1 := nvl(CON.addr1,oh1st.billtoaddr1);
    aims_cod.billtoaddr2 := nvl(CON.addr2,oh1st.billtoaddr2);
    aims_cod.billtocity := nvl(CON.city,oh1st.billtocity);
    aims_cod.billtostate := nvl(CON.state,oh1st.billtostate);
    aims_cod.billtopostalcode := nvl(CON.postalcode,oh1st.billtopostalcode);
    aims_cod.billtocountrycode := nvl(CON.countrycode,oh1st.billtocountrycode);
    aims_cod.billtophone := nvl(CON.phone,oh1st.billtophone);
    aims_cod.billtofax := nvl(CON.fax,oh1st.billtofax);
    aims_cod.billtoemail := nvl(CON.email,oh1st.billtoemail);

    aims_cod.orderid := oh1st.orderid;
    aims_cod.shipid := oh1st.shipid;

execute immediate 'insert into FREIGHT_AIMS_COD_' || strSuffix ||
' values (:LOADNO,:CUSTID,:ORDERID,:SHIPID,'||
' :SHIPTO_LINK,:BILLTONAME,:BILLTOCONTACT,'||
':BILLTOADDR1,:BILLTOADDR2,:BILLTOCITY,:BILLTOSTATE,:BILLTOPOSTALCODE,'||
':BILLTOCOUNTRYCODE,:BILLTOPHONE,:BILLTOFAX,:BILLTOEMAIL )'
using aims_cod.loadno, aims_cod.custid, aims_cod.orderid,aims_cod.shipid,
    aims_cod.shipto_link,
    aims_cod.billtoname, aims_cod.billtocontact, aims_cod.billtoaddr1,
    aims_cod.billtoaddr2, aims_cod.billtocity, aims_cod.billtostate,
    aims_cod.billtopostalcode, aims_cod.billtocountrycode,
    aims_cod.billtophone, aims_cod.billtofax, aims_cod.billtoemail;


aims_se.total_segments := aims_se.total_segments + 1;

end;

procedure add_aims_itd_row is

TYPE cur_typ is REF CURSOR;

cr cur_typ;

begin

if nvl(in_detail_extract,'N') != 'Y' then
    return;
end if;

debugmsg('add aims_itd_row ' || aims_st.controlno);

  aims_itd.orderid := oh1st.orderid;
  aims_itd.shipid := oh1st.shipid;

  cmdSql := 'select D.item, I.descr, D.uom, sum(nvl(D.qtyship,0)), ' ||
            ' sum(nvl(D.weightship,0)) ' ||
    ' from custitem I, orderdtl D, orderhdr H ' ||
    'where H.loadno = ' || oh1st.loadno  ||
    ' and H.custid = ''' || oh1st.custid || '''' ||
    ' and H.fromfacility = ''' || oh1st.fromfacility || '''' ||
    ' and nvl(to_char(H.' || in_consolidate_field || '),''x'') = ''' ||
    aims_at2.ShipTo_Link || '''' ||
    ' and D.orderid = H.orderid and D.shipid = H.shipid '||
    ' and I.custid = D.custid and I.item = D.item ' ||
    ' group by D.item, I.descr, D.uom ';

    debugmsg(cmdsql);

    open cr for cmdSql;

    loop
        fetch cr into aims_itd.item, aims_itd.itemdesc, aims_itd.uom,
            aims_itd.quantity, aims_itd.weight;

        exit when cr%notfound;

        debugmsg('ITD Item:'||aims_itd.item);

        execute immediate 'insert into FREIGHT_AIMS_ITD_' || strSuffix ||
    ' values (:LOADNO,:CUSTID,:ORDERID,:SHIPID,'||
    ' :SHIPTO_LINK,:ITEM,:ITEMDESC,'||
    ':QUANTITY,:UOM,:WEIGHT )'
    using aims_itd.loadno, aims_itd.custid, aims_itd.orderid,aims_itd.shipid,
        aims_itd.shipto_link,
        aims_itd.item, aims_itd.itemdesc, aims_itd.quantity,
        aims_itd.uom, aims_itd.weight;


        aims_se.total_segments := aims_se.total_segments + 1;

    end loop;

    close cr;


end;

procedure reset_work_records is
begin

debugmsg('begin reset work records ' || oh1.loadno || ' ' || strShipTo_Link);
aims_st := null;
aims_st.loadno := oh1.loadno;
aims_st.shipto_link := strShipTo_Link;
aims_st.custid := oh1.custid;
aims_bol := null;
aims_bol.loadno := oh1.loadno;
aims_bol.shipto_link := strShipTo_Link;
aims_bol.custid := oh1.custid;
aims_b2a := null;
aims_b2a.loadno := oh1.loadno;
aims_b2a.shipto_link := strShipTo_Link;
aims_b2a.custid := oh1.custid;
aims_g62 := null;
aims_g62.loadno := oh1.loadno;
aims_g62.shipto_link := strShipTo_Link;
aims_g62.custid := oh1.custid;
aims_k1 := null;
aims_k1.loadno := oh1.loadno;
aims_k1.shipto_link := strShipTo_Link;
aims_k1.custid := oh1.custid;
aims_n1 := null;
aims_n1.loadno := oh1.loadno;
aims_n1.shipto_link := strShipTo_Link;
aims_n1.custid := oh1.custid;
aims_n4 := null;
aims_n4.loadno := oh1.loadno;
aims_n4.shipto_link := strShipTo_Link;
aims_n4.custid := oh1.custid;
aims_at1 := null;
aims_at1.loadno := oh1.loadno;
aims_at1.shipto_link := strShipTo_Link;
aims_at1.custid := oh1.custid;
aims_at2 := null;
aims_at2.loadno := oh1.loadno;
aims_at2.shipto_link := strShipTo_Link;
aims_at2.custid := oh1.custid;
aims_se := null;
aims_se.loadno := oh1.loadno;
aims_se.shipto_link := strShipTo_Link;
aims_se.custid := oh1.custid;
aims_se.total_segments := 0;
aims_cod := null;
aims_cod.loadno := oh1.loadno;
aims_cod.shipto_link := strShipTo_Link;
aims_cod.custid := oh1.custid;
aims_itd := null;
aims_itd.loadno := oh1.loadno;
aims_itd.shipto_link := strShipTo_Link;
aims_itd.custid := oh1.custid;

oh1st := oh1;

ld := null;
if nvl(oh1.loadno,0) <> 0 then
  open curLoads(oh1.Loadno);
  fetch curLoads into ld;
  close curLoads;
end if;

debugmsg('end reset work records');

end;

procedure process_freight_order(in_orderid number, in_shipid number) is
begin

  debugmsg('process_freight_order ' || in_orderid || '-' || in_shipid);

  oh1 := null;
  open curOrderHdr(in_orderid, in_shipid);
  fetch curOrderHdr into oh1;
  close curOrderHdr;

  if oh1.orderid is null then
    return;
  end if;

  if strShipTo_Link is null then
    strShipTo_Link := '(NONE)';
    debugmsg('ship to link field is null');
  end if;

  debugmsg(' str link is ' || strShipTo_Link);
  debugmsg('  st link is ' || aims_st.ShipTo_Link);

  loadcarrier := null;
  if nvl(oh1.loadno,0) <> 0 then
    select carrier
      into loadcarrier
      from loads
     where loadno = oh1.loadno;
  end if;
  multiship := 'N';
  select nvl(multiship,'N')
    into multiship
    from carrier
   where carrier = nvl(loadcarrier,oh1.carrier);
  if multiship = 'Y' then
    return;
  end if;

  if strShipTo_Link <> nvl(aims_st.ShipTo_Link,'$?$') or
     nvl(oh1.loadno,0) <> nvl(aims_st.loadno,0) then
    if aims_st.ShipTo_Link is not null then
      debugmsg('aims_st shipto_link is ' || aims_st.shipto_link);
      add_aims_se_row;
    end if;
    reset_work_records;
    debugmsg('do adds');
    add_aims_st_row;
    add_aims_bol_row;
    add_aims_b2a_row;
    add_aims_g62_row;
    add_aims_k1_row;
    add_aims_n1_row;
    add_aims_n4_row;
    add_aims_at1_row;
    add_aims_at2_row;
    add_aims_cod_row;
    add_aims_itd_row;
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

debugmsg('find view suffix');
viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'FREIGHT_AIMS_ST_' || strSuffix;
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


cmdSql := 'create table FREIGHT_AIMS_ST_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,FACILITY VARCHAR2(3),SHIPTO_LINK VARCHAR2(255),' ||
' CONTROLNO NUMBER(7) not null )';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_BOL_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,FACILITY VARCHAR2(3),SHIPTO_LINK VARCHAR2(255),' ||
' CARRIER VARCHAR2(10),SHIPTERMS VARCHAR2(3),ORDERID NUMBER(9) not null,' ||
' SHIPID NUMBER(2) not null,SHIPDATE DATE,PRONO VARCHAR2(20),HDRPASSTHRUCHAR01 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR02 VARCHAR2(255),HDRPASSTHRUCHAR03 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR04 VARCHAR2(255),HDRPASSTHRUCHAR05 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR06 VARCHAR2(255),HDRPASSTHRUCHAR07 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR08 VARCHAR2(255),HDRPASSTHRUCHAR09 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR10 VARCHAR2(255),HDRPASSTHRUCHAR11 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR12 VARCHAR2(255),HDRPASSTHRUCHAR13 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR14 VARCHAR2(255),HDRPASSTHRUCHAR15 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR16 VARCHAR2(255),HDRPASSTHRUCHAR17 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR18 VARCHAR2(255),HDRPASSTHRUCHAR19 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR20 VARCHAR2(255),HDRPASSTHRUNUM01 NUMBER(16,4),HDRPASSTHRUNUM02 NUMBER(16,4),' ||
' HDRPASSTHRUNUM03 NUMBER(16,4),HDRPASSTHRUNUM04 NUMBER(16,4),HDRPASSTHRUNUM05 NUMBER(16,4),' ||
' HDRPASSTHRUNUM06 NUMBER(16,4),HDRPASSTHRUNUM07 NUMBER(16,4),HDRPASSTHRUNUM08 NUMBER(16,4),' ||
' HDRPASSTHRUNUM09 NUMBER(16,4),HDRPASSTHRUNUM10 NUMBER(16,4),HDRPASSTHRUDATE01 DATE,' ||
' HDRPASSTHRUDATE02 DATE,HDRPASSTHRUDATE03 DATE,HDRPASSTHRUDATE04 DATE,' ||
' HDRPASSTHRUDOLL01 NUMBER(10,2),HDRPASSTHRUDOLL02 NUMBER(10,2),'||
' PO VARCHAR2(20), BILLOFLADING VARCHAR2(40) )';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_B2A_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,SHIPTO_LINK VARCHAR2(255),' ||
' PURPOSE_CODE CHAR(2) )';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_G62_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,SHIPTO_LINK VARCHAR2(255),DATE_QUALIFIER VARCHAR2(255),' ||
' DATE_VALUE DATE )';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_K1_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,SHIPTO_LINK VARCHAR2(255),COMMENT1 VARCHAR2(255)' ||
')';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_N1_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null, '||
' ORDERID NUMBER(9), SHIPID NUMBER(2), '||
' SHIPTO_LINK VARCHAR2(255),ENTITY_IDENTIFIER VARCHAR2(255),' ||
' NAME VARCHAR2(255),CODE_QUALIFIER VARCHAR2(255),' ||
' CODE_VALUE VARCHAR2(255) )';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_N4_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,SHIPTO_LINK VARCHAR2(255),ENTITY_IDENTIFIER VARCHAR2(255),' ||
' CITY_NAME VARCHAR2(30),STATE_CODE VARCHAR2(5),POSTALCODE VARCHAR2(12)' ||
')';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_AT1_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,SHIPTO_LINK VARCHAR2(255),LINE_ITEM_NUMBER VARCHAR2(255)' ||
')';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_AT2_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,SHIPTO_LINK VARCHAR2(255),PALLET_QUANTITY NUMBER(7),' ||
' PALLET_FORM_CODE CHAR(3),WEIGHT_QUALIFIER CHAR(1),WEIGHT_UNIT_CODE CHAR(1),' ||
' WEIGHT NUMBER(17,8),PIECES_QUANTITY NUMBER(7),PIECES_FORM_CODE CHAR(3),' ||
' CASES_QUANTITY NUMBER(7)' ||
')';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_SE_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,SHIPTO_LINK VARCHAR2(255),TOTAL_SEGMENTS NUMBER(7),' ||
' CONTROLNO NUMBER(9) not null )';
debugmsg(cmdSql);
execute immediate cmdSql;


cmdSql := 'create table FREIGHT_AIMS_COD_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,'||
' ORDERID NUMBER(9), SHIPID NUMBER(2), '||
' SHIPTO_LINK VARCHAR2(255),' ||
' BILLTONAME VARCHAR2(40),BILLTOCONTACT VARCHAR2(40),'||
' BILLTOADDR1 VARCHAR2(40),BILLTOADDR2 VARCHAR2(40),'||
' BILLTOCITY VARCHAR2(30),BILLTOSTATE VARCHAR2(5),'||
' BILLTOPOSTALCODE VARCHAR2(12),BILLTOCOUNTRYCODE VARCHAR2(3),'||
' BILLTOPHONE VARCHAR2(25),BILLTOFAX VARCHAR2(25),BILLTOEMAIL VARCHAR2(255) '||
')';
debugmsg(cmdSql);
execute immediate cmdSql;

cmdSql := 'create table FREIGHT_AIMS_ITD_' || strSuffix ||
' (LOADNO NUMBER(7),CUSTID VARCHAR2(10) not null,'||
' ORDERID NUMBER(9), SHIPID NUMBER(2), '||
' SHIPTO_LINK VARCHAR2(255),' ||
' item varchar2(50), ITEMDESC VARCHAR2(255), QUANTITY NUMBER(10), ' ||
' UOM VARCHAR2(3), WEIGHT NUMBER (17,8) )';
debugmsg(cmdSql);
execute immediate cmdSql;

oh1 := null;
strShipTo_link := null;

reset_work_records;

if in_orderid != 0 then
  cmdSql := 'select orderid,shipid,nvl(to_char(' || in_consolidate_field || '),''x'') ' ||
    ' from orderhdr where custid = ''' || in_custid || ''' and orderid = ' || in_orderid ||
    ' and shipid = ' || in_shipid || ' and orderstatus = ''9''' ||
    ' order by nvl(' || in_consolidate_field || ',''xx''),orderid,shipid';
  debugmsg(cmdSql);
  begin
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
    dbms_sql.define_column(curSql,1,numOrderId);
    dbms_sql.define_column(curSql,2,numShipId);
    dbms_sql.define_column(curSql,3,strShipTo_Link,255);
    cntRows := dbms_sql.execute(curSql);
    cntRows := dbms_sql.fetch_rows(curSql);
    debugmsg('cnt rows is ' || cntRows);
    if cntRows > 0 then
      dbms_sql.column_value(curSql,1,numOrderId);
      dbms_sql.column_value(curSql,2,numShipId);
      dbms_sql.column_value(curSql,3,strShipTo_Link);
      process_freight_order(numOrderId,numShipId);
      cntRows := dbms_sql.fetch_rows(curSql);
    end if;
    dbms_sql.close_cursor(curSql);
  exception when others then
    dbms_sql.close_cursor(curSql);
  end;
elsif in_loadno != 0 then
  cmdSql := 'select orderid,shipid,nvl(to_char(' || in_consolidate_field || '),''x'') ' ||
    ' from orderhdr where custid = ''' || in_custid || ''' and loadno = ' || in_loadno ||
    ' and orderstatus = ''9''' ||
    ' order by nvl(' || in_consolidate_field || ',''x''),orderid,shipid';
  debugmsg(cmdSql);
  begin
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
    dbms_sql.define_column(curSql,1,numOrderId);
    dbms_sql.define_column(curSql,2,numShipId);
    dbms_sql.define_column(curSql,3,strShipTo_Link,255);
    cntRows := dbms_sql.execute(curSql);
    cntRows := dbms_sql.fetch_rows(curSql);
    debugmsg('cnt rows is ' || cntRows);
    while cntRows > 0
    loop
      dbms_sql.column_value(curSql,1,numOrderId);
      dbms_sql.column_value(curSql,2,numShipId);
      dbms_sql.column_value(curSql,3,strShipTo_Link);
      process_freight_order(numOrderId,numShipId);
      cntRows := dbms_sql.fetch_rows(curSql);
    end loop;
    dbms_sql.close_cursor(curSql);
  exception when others then
    dbms_sql.close_cursor(curSql);
  end;
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
  cmdSql := 'select orderid,shipid,nvl(to_char(' || in_consolidate_field || '),''x'') ' ||
    ' from orderhdr where custid = ''' || in_custid || '''' ||
    ' and statusupdate >= to_date(''' || in_begdatestr ||
    ''', ''yyyymmddhh24miss'')' ||
    ' and statusupdate <  to_date(''' || in_enddatestr ||
    ''', ''yyyymmddhh24miss'') ' ||
    ' and orderstatus = ''9''' ||
    ' order by loadno,nvl(' || in_consolidate_field || ',''x''),orderid,shipid';
  debugmsg(cmdSql);
  begin
    curSql := dbms_sql.open_cursor;
    dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
    dbms_sql.define_column(curSql,1,numOrderId);
    dbms_sql.define_column(curSql,2,numShipId);
    dbms_sql.define_column(curSql,3,strShipTo_Link,255);
    cntRows := dbms_sql.execute(curSql);
    cntRows := dbms_sql.fetch_rows(curSql);
    debugmsg('cnt rows is ' || cntRows);
    while cntRows > 0
    loop
      dbms_sql.column_value(curSql,1,numOrderId);
      dbms_sql.column_value(curSql,2,numShipId);
      dbms_sql.column_value(curSql,3,strShipTo_Link);
      process_freight_order(numOrderId,numShipId);
      cntRows := dbms_sql.fetch_rows(curSql);
    end loop;
    dbms_sql.close_cursor(curSql);
  exception when others then
    dbms_sql.close_cursor(curSql);
  end;
end if;

add_aims_se_row;

commit;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimfreightb ' || sqlerrm;
  out_errorno := sqlcode;
end begin_freight_aims_format;

procedure end_freight_aims_format
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

cmdSql := 'drop table freight_aims_bol_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_b2a_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_g62_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_k1_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_n1_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_n4_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_at1_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_at2_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_se_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_cod_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_itd_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table freight_aims_st_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimfreighte ' || sqlerrm;
  out_errorno := sqlcode;
end end_freight_aims_format;

PROCEDURE get_aimsfileseq
(in_custid IN varchar2
,in_loop_count IN number
,in_viewsuffix IN varchar2
,out_aimsfileseq OUT varchar2
) is

strSuffix varchar2(32);
numLoop_Count number;
numControlNo freight_aims_st.controlno%type;
curSql integer;
cmdSql varchar2(255);
cntRows integer;

begin

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

numLoop_Count := 0;
numControlNo := 0;
out_aimsfileseq := '';

cmdSql := 'select controlno ' ||
    ' from freight_aims_st_' || strSuffix;
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,numControlNo);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  while cntRows > 0
  loop
    dbms_sql.column_value(curSql,1,numControlNo);
    numLoop_Count := numLoop_Count + 1;
    if numLoop_Count >= nvl(in_loop_count,0) then
      out_aimsfileseq := trim(to_char(numControlNo));
      exit;
    end if;
    cntRows := dbms_sql.fetch_rows(curSql);
  end loop;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

while length(out_aimsfileseq) < 9
loop
  out_aimsfileseq := '0' || out_aimsfileseq;
end loop;

exception when others then
  out_aimsfileseq := '000000000';
end get_aimsfileseq;

end zimportprocfreight;
/
show error package body zimportprocfreight;
exit;
