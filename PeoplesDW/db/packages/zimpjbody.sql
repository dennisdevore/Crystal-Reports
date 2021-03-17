create or replace package body alps.zimportprocpj as
--
-- $Id: zimpjbody.sql 8807 2012-08-22 20:08:23Z jean $
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure import_order_940
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_apptdate IN DATE
,in_shipdate IN varchar2    -- to handle first line in world centric import 
,in_po IN varchar2
,in_rma IN varchar2
,in_fromfacility IN varchar2
,in_shipto IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_consignee IN varchar2
,in_shiptype IN varchar2
,in_carrier IN varchar2
,in_carrier_descr IN varchar2
,in_reference IN varchar2
,in_shipterms IN varchar2
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
,in_cancel_after IN date
,in_delivery_requested IN date
,in_requested_ship IN date
,in_ship_not_before IN date
,in_ship_no_later IN date
,in_cancel_if_not_delivered_by IN date
,in_do_not_deliver_after IN date
,in_do_not_deliver_before IN date
,in_rfautodisplay IN varchar2
,in_ignore_received_orders_yn IN varchar2
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
,in_hdrpassthrudate01 IN date
,in_hdrpassthrudate02 IN date
,in_hdrpassthrudate03 IN date
,in_hdrpassthrudate04 IN date
,in_hdrpassthrudoll01 IN number
,in_hdrpassthrudoll02 IN number
,in_importfileid IN varchar2
,in_instructions IN varchar2
,in_include_cr_lf_yn IN varchar2
,in_bolcomment IN varchar2
,in_itementered IN varchar2
,in_lotNUMBER IN varchar2
,in_uomentered IN varchar2
,in_qtyentered IN varchar2       -- to handle first line in world centric import 
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
,in_dtlpassthruchar21 IN varchar2
,in_dtlpassthruchar22 IN varchar2
,in_dtlpassthruchar23 IN varchar2
,in_dtlpassthruchar24 IN varchar2
,in_dtlpassthruchar25 IN varchar2
,in_dtlpassthruchar26 IN varchar2
,in_dtlpassthruchar27 IN varchar2
,in_dtlpassthruchar28 IN varchar2
,in_dtlpassthruchar29 IN varchar2
,in_dtlpassthruchar30 IN varchar2
,in_dtlpassthruchar31 IN varchar2
,in_dtlpassthruchar32 IN varchar2
,in_dtlpassthruchar33 IN varchar2
,in_dtlpassthruchar34 IN varchar2
,in_dtlpassthruchar35 IN varchar2
,in_dtlpassthruchar36 IN varchar2
,in_dtlpassthruchar37 IN varchar2
,in_dtlpassthruchar38 IN varchar2
,in_dtlpassthruchar39 IN varchar2
,in_dtlpassthruchar40 IN varchar2
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
,in_dtlpassthrunum11 IN number
,in_dtlpassthrunum12 IN number
,in_dtlpassthrunum13 IN number
,in_dtlpassthrunum14 IN number
,in_dtlpassthrunum15 IN number
,in_dtlpassthrunum16 IN number
,in_dtlpassthrunum17 IN number
,in_dtlpassthrunum18 IN number
,in_dtlpassthrunum19 IN number
,in_dtlpassthrunum20 IN number
,in_dtlpassthrudate01 IN date
,in_dtlpassthrudate02 IN date
,in_dtlpassthrudate03 IN date
,in_dtlpassthrudate04 IN date
,in_dtlpassthrudoll01 IN number
,in_dtlpassthrudoll02 IN number
,in_dtlrfautodisplay IN varchar2
,in_dtlinstructions IN varchar2
,in_dtlbolcomment IN varchar2
,in_use_base_uom IN varchar2
,in_prono IN varchar2
,in_weight_entered_lbs IN number
,in_weight_entered_kgs IN number
,in_variance_pct_shortage IN number
,in_variance_pct_overage IN number
,in_variance_use_default_yn IN varchar2
,in_arrivaldate IN date
,in_validate_shipto IN varchar2
,in_cancel_productgroup IN varchar2
,in_weight_productgroups IN varchar2
,in_cancel_item_eoi_yn IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor C_CSC(in_carrier_descr varchar2) is
    select  carrier,
            servicecode,
            decode(carrier,
                'ODFL',    'L',
                'DAYL',    'L',
                'UPSF',    'L',
                'FEDG',    'S',
                'UPSC',    'S',
                'UPS2',    'S',
                'UPS3',    'S',
                'UPSR',    'S',
                'UPSH',    'S',
                'UPSA',    'S',
                'UPSS',    'S',
                'UPSW',    'S',
                'ZZZZ',    'L')
     from carrierservicecodes
    where upper(regexp_replace(descr,'[^[:alnum:]]')) =
          upper(regexp_replace(in_carrier_descr,'[^[:alnum:]]'))
      and rownum = 1;

cursor C_OHDR(out_orderid number, out_shipid number) is
    select ordertype, carrier, shiptype, deliveryservice
      from orderhdr
     where orderid = out_orderid
       and shipid = out_shipid;

oh                  C_OHDR%rowtype;
l_carrier           carrierservicecodes.carrier%type;
l_deliveryservice   carrierservicecodes.servicecode%type;
l_hdrpassthruchar20 carrierservicecodes.servicecode%type;
l_shiptype          orderhdr.shiptype%type;
l_shipdate          orderhdr.shipdate%type;
l_qtyentered        orderdtl.qtyentered%type;

procedure order_msg(in_msgtype varchar2) is
pragma autonomous_transaction;
strMsg appmsgs.msgtext%type;
begin
  out_msg := ' Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'IMP 940 '||' Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  else
    out_msg := 'IMP 940 '|| out_msg;
  end if;
  zms.log_msg(IMP_USERID, in_fromfacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  commit;
end;

BEGIN
out_msg := 'Begin of Import - '||rtrim(in_reference);
order_msg('I');

if nvl(in_reference, 'none') = 'Order ID' then
  --out_msg := 'Skipping line';
  --order_msg('I');
 out_errorno := 0;
 return;
end if;

l_shipdate := to_date(in_shipdate, 'MM/DD/YYYY');
l_qtyentered := to_number(in_qtyentered);

-- handle special characters in carrier name
if rtrim(in_carrier_descr) is not null then
  open  C_CSC(in_carrier_descr);
  fetch C_CSC into l_carrier, l_deliveryservice, l_shiptype;
  close C_CSC;

-- leave service code blank, except for shiptype S
  begin
    l_hdrpassthruchar20 := l_deliveryservice;
    select  decode(l_shiptype, 'S', l_deliveryservice, null)
      into  l_deliveryservice
      from  dual;
  exception when others then
    null;
  end;
end if;

zimportprocspreadsheet.spreadsheet_import_order(
 in_func
,in_custid
,in_apptdate
,l_shipdate
,in_po
,in_rma
,in_fromfacility
,in_shipto
,in_billoflading
,in_priority
,in_shipper
,in_consignee
,l_shiptype
,l_carrier
,in_reference
,in_shipterms
,in_shiptoname
,in_shiptocontact
,in_shiptoaddr1
,in_shiptoaddr2
,in_shiptocity
,in_shiptostate
,in_shiptopostalcode
,in_shiptocountrycode
,in_shiptophone
,in_shiptofax
,in_shiptoemail
,in_billtoname
,in_billtocontact
,in_billtoaddr1
,in_billtoaddr2
,in_billtocity
,in_billtostate
,in_billtopostalcode
,in_billtocountrycode
,in_billtophone
,in_billtofax
,in_billtoemail
,l_deliveryservice
,in_saturdaydelivery
,in_cod
,in_amtcod
,in_specialservice1
,in_specialservice2
,in_specialservice3
,in_specialservice4
,in_cancel_after
,in_delivery_requested
,in_requested_ship
,in_ship_not_before
,in_ship_no_later
,in_cancel_if_not_delivered_by
,in_do_not_deliver_after
,in_do_not_deliver_before
,in_rfautodisplay
,in_ignore_received_orders_yn
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
,l_hdrpassthruchar20
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
,in_hdrpassthrudoll01
,in_hdrpassthrudoll02
,in_importfileid
,in_instructions
,in_include_cr_lf_yn
,in_bolcomment
,in_itementered
,in_lotnumber
,in_uomentered
,l_qtyentered
,in_backorder
,in_allowsub
,in_qtytype
,in_invstatusind
,in_invstatus
,in_invclassind
,in_inventoryclass
,in_consigneesku
,in_dtlpassthruchar01
,in_dtlpassthruchar02
,in_dtlpassthruchar03
,in_dtlpassthruchar04
,in_dtlpassthruchar05
,in_dtlpassthruchar06
,in_dtlpassthruchar07
,in_dtlpassthruchar08
,in_dtlpassthruchar09
,in_dtlpassthruchar10
,in_dtlpassthruchar11
,in_dtlpassthruchar12
,in_dtlpassthruchar13
,in_dtlpassthruchar14
,in_dtlpassthruchar15
,in_dtlpassthruchar16
,in_dtlpassthruchar17
,in_dtlpassthruchar18
,in_dtlpassthruchar19
,in_dtlpassthruchar20
,in_dtlpassthruchar21
,in_dtlpassthruchar22
,in_dtlpassthruchar23
,in_dtlpassthruchar24
,in_dtlpassthruchar25
,in_dtlpassthruchar26
,in_dtlpassthruchar27
,in_dtlpassthruchar28
,in_dtlpassthruchar29
,in_dtlpassthruchar30
,in_dtlpassthruchar31
,in_dtlpassthruchar32
,in_dtlpassthruchar33
,in_dtlpassthruchar34
,in_dtlpassthruchar35
,in_dtlpassthruchar36
,in_dtlpassthruchar37
,in_dtlpassthruchar38
,in_dtlpassthruchar39
,in_dtlpassthruchar40
,in_dtlpassthrunum01
,in_dtlpassthrunum02
,in_dtlpassthrunum03
,in_dtlpassthrunum04
,in_dtlpassthrunum05
,in_dtlpassthrunum06
,in_dtlpassthrunum07
,in_dtlpassthrunum08
,in_dtlpassthrunum09
,in_dtlpassthrunum10
,in_dtlpassthrunum11
,in_dtlpassthrunum12
,in_dtlpassthrunum13
,in_dtlpassthrunum14
,in_dtlpassthrunum15
,in_dtlpassthrunum16
,in_dtlpassthrunum17
,in_dtlpassthrunum18
,in_dtlpassthrunum19
,in_dtlpassthrunum20
,in_dtlpassthrudate01
,in_dtlpassthrudate02
,in_dtlpassthrudate03
,in_dtlpassthrudate04
,in_dtlpassthrudoll01
,in_dtlpassthrudoll02
,in_dtlrfautodisplay
,in_dtlinstructions
,in_dtlbolcomment
,in_use_base_uom
,in_prono
,in_weight_entered_lbs
,in_weight_entered_kgs
,in_variance_pct_shortage
,in_variance_pct_overage
,in_variance_use_default_yn
,in_arrivaldate
,in_validate_shipto
,in_cancel_productgroup
,in_weight_productgroups
,in_cancel_item_eoi_yn
,out_orderid
,out_shipid
,out_errorno
,out_msg
);

out_msg :=
    'CarrierName='||in_carrier_descr||'  '||
    'CarrierCode='||l_carrier||'  '||
    'DelvServCode='||l_deliveryservice||'  '||
    'ShipType='||l_shiptype;
order_msg('I');

out_msg := 'End of Import - '||rtrim(in_importfileid);
order_msg('I');

exception when others then
  out_msg := 'io940 ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_940;

procedure begin_invstatus_846
(in_custid IN varchar2
,in_facility IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

mark varchar2(200);

curFunc integer;
cntRows integer;
cmdSql varchar2(32767);

strSuffix varchar2(32);
viewcount integer;
ddltitle varchar2(16);
strDebugYN char(1);

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
end debugmsg;

BEGIN

if out_errorno = -12345 then
  strDebugYN := 'Y';
end if;

mark := 'start';
out_errorno := 0;
out_msg := '';
ddltitle := 'INVSTAT_846';
viewcount := 1;

while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = ddltitle || '_DTL_' || strSuffix;

  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

mark := 'Cust Chk';
select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code:' ||in_custid;
  return;
end if;

mark := 'dtl table create';

cmdSql := 'create table ' || ddltitle || '_dtl_' || strSuffix  ||
'(' ||
'item varchar2(50) not null ' ||
',ITEM_DESCRIPTION VARCHAR2(40) ' ||
',UOM VARCHAR2(4) ' ||
',QUANTITY_ON_HAND VARCHAR2(40) ' ||
',QUANTITY_AVAILABLE VARCHAR2(40) ' ||
',QUANTITY_ALLOCATED  VARCHAR2(40) ' ||
',QUANTITY_IN_QA VARCHAR2(40) ' ||
',CREATED VARCHAR2(40)' ||
',CUSTID VARCHAR2(10)' ||
',ITEM_SORT VARCHAR2(20) not null ' ||
')';
--dbms_output.put_line(cmdSql);
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

--mark := 'inserting hdr into dtl table';
cmdSql := 'insert into '|| ddltitle || '_dtl_' || strSuffix ||
 ' (item, item_description, uom, quantity_on_hand, quantity_available, quantity_allocated, quantity_in_qa, created, custid, item_sort)' ||
 ' values (''ITEM'' , ' ||
 ' ''ITEM DESCRIPTION'' , ' ||
 ' ''UOM'' , ' ||
 ' ''ON HAND'' , ' ||
 ' ''AVAILABLE'' , ' ||
 ' ''ALLOCATED'' , ' ||
 ' ''IN QA'' , ' ||
 ' ''SYSTIMESTAMP'', ' ||
 '''' || in_custid || ''','|| 
 ' ''_ITEM'')';
--dbms_output.put_line(cmdSql);
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

mark := 'dtl table populate';
debugmsg('--> ' || mark);
cmdsql := 'insert into '|| ddltitle || '_dtl_' || strsuffix ||
'(item '||
' ,item_description '||
' ,uom '||
' ,quantity_on_hand '||
' ,quantity_available '||
' ,quantity_allocated ' ||
' ,quantity_in_qa '||
' ,created ' ||
' ,custid '||
', item_sort) '||
'SELECT '||
'  QOH.item  ,'||
'  QOH.itemdescr  ,'||
'  QOH.uom, '||
'  nvl(QOH.quantity_on_hand,0) ,'||
'  nvl(QAV.quantity_available,0) ,'||
'  nvl(QAL.quantity_allocated,0), '||
'  nvl(QQA.quantity_in_qa,0) , '||
'  (select systimestamp from dual), '||
'''' || in_custid ||''','|| 
'  QOH.item '||
' FROM ' ||
-- Quantity on Hand
'(select custid, item, itemdescr, uom , sum(qty) as quantity_on_hand '||
' from custitemtotsumallview '||
' group by custid, item, itemdescr, uom) QOH, '||
-- Quantity Allocated
'(select custid, item, itemdescr, uom , sum(qty) as quantity_allocated '||
' from custitemtotallocatedview '||
' where orderstatus in (''5'',''6'',''7'',''8'') '||
' group by custid, item, itemdescr, uom) QAL, '||
-- Quantity Held in QA
'(select custid, item, itemdescr, uom , sum(qty) as quantity_in_qa '||
' from custitemtotsumallview '||
' where invstatus != ''AV'' '||
' group by custid, item, itemdescr, uom) QQA, ' ||
-- Quantity Available
'(select A.custid, A.item, A.itemdescr, A.uom, nvl(A.qty,0) - nvl(B.qty,0) as quantity_available  '||
'from  (select custid, item, itemdescr, uom, sum(nvl(qty,0)) qty  '||
'         from  custitemtotsumallview ' ||
'        group by custid, item, itemdescr, uom ) A, '||
'      (select  custid, item, itemdescr, uom, sum(nvl(qty,0)) qty  '||
'         from  custitemtotallocatedview  '||
'        group by custid, item, itemdescr, uom) B '||
'where A.custid = B.custid(+) '||
'and A.item = B.item(+) '||
'and A.itemdescr = B.itemdescr(+) '||
'and A.uom = B.uom(+)) QAV '||
'WHERE QOH.custid = ''' || in_custid || '''' ||
'  AND QOH.custid = QAL.custid(+) '||
'  AND QOH.item = QAL.item(+) '||
'  AND QOH.custid = QQA.custid(+) '||
'  AND QOH.item = QQA.item(+) '||
'  AND QOH.custid = QAV.custid(+) '||
'  AND QOH.item = QAV.item(+) '||
'  AND QOH.uom = QAL.uom(+) '||
'  AND QOH.uom = QQA.uom(+) '||
'  AND QOH.uom = QAV.uom(+) '||
'  order by QOH.item asc ';
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'End inventory status 846 - ' || IMP_USERID;
debugmsg(out_msg);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbise ' || sqlerrm;
  out_errorno := sqlcode;
end begin_invstatus_846;

procedure end_invstatus_846
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

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;
begin
   cmdSql := 'drop table invstat_846_dtl_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeise ' || sqlerrm;
  out_errorno := sqlcode;
end end_invstatus_846;

end zimportprocpj;
/
show errors package body zimportprocpj;
exit;
