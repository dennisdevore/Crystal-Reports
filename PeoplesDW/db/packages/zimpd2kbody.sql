create or replace package body alps.zimportprocsD2k as
--
-- $Id: zimpbody.sql 1738 2007-03-12 21:55:08Z brianb $
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure import_order_headerD2k
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_ordertype IN varchar2
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
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
,in_arrivaldate IN DATE
,in_validate_shipto in varchar2
,in_abc_revision in varchar2
,in_bolcomment in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

l_shipterms orderhdr.shipterms%type;
l_billtoname orderhdr.billtoname%type;
l_billtoaddr1 orderhdr.billtoaddr1%type;
l_billtoaddr2 orderhdr.billtoaddr1%type;
l_billtocity orderhdr.billtocity%type;
l_billtostate orderhdr.billtostate%type;
l_billtopostalcode orderhdr.billtopostalcode%type;
l_consignee orderhdr.consignee%type;

cmdSql varchar2(2000);

TYPE cur_type is REF CURSOR;
cr cur_type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(in_fromfacility,in_tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;


begin
out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
out_msg := 'Car ' || in_carrier || ' PO ' || in_po || ' ST ' || in_shiptoname ||
           ' terms ' || in_shipterms;
order_msg('I');

l_billtoname := in_billtoname;
l_billtoaddr1 := in_billtoaddr1;
l_billtoaddr2 := in_billtoaddr2;
l_billtocity := in_billtocity;
l_billtostate := in_billtostate;
l_billtopostalcode := in_billtopostalcode;
l_consignee := null;
l_shipterms := in_shipterms;

if rtrim(in_shipterms) = '1' then
   l_shipterms := 'PCK';
elsif rtrim(in_shipterms) = '2' then
   l_shipterms := 'COL';
elsif rtrim(in_shipterms) = '3' then
   l_shipterms := '3RD';
   l_billtoname := null;
   l_billtoaddr1 := null;
   l_billtoaddr2 := null;
   l_billtocity := null;
   l_billtostate := null;
   l_billtopostalcode := null;
   l_consignee := 'D2K';
elsif rtrim(in_shipterms) = '4' then
   l_shipterms := '3RD';
end if;

if rtrim(in_carrier) = 'CPU' then
   l_billtoname := null;
   l_billtoaddr1 := null;
   l_billtoaddr2 := null;
   l_billtocity := null;
   l_billtostate := null;
   l_billtopostalcode := null;
end if;

if rtrim(in_carrier) = 'STA' then
   l_billtoname := 'STARLITE SERVICES';
   l_billtoaddr1 := 'PO BOX 7849';
   l_billtoaddr2 := null;
   l_billtocity := 'ROMEOVILLE';
   l_billtostate := 'IL';
   l_billtopostalcode := '60446-7849';
   l_shipterms := '3RD';
end if;

zimp.import_order_header(
   in_func
   ,in_custid
   ,in_ordertype
   ,in_apptdate
   ,in_shipdate
   ,in_po
   ,in_rma
   ,in_fromfacility
   ,in_tofacility
   ,in_shipto
   ,in_billoflading
   ,in_priority
   ,in_shipper
   ,in_consignee
   ,in_shiptype
   ,in_carrier
   ,in_reference
   ,l_shipterms
   ,in_shippername
   ,in_shippercontact
   ,in_shipperaddr1
   ,in_shipperaddr2
   ,in_shippercity
   ,in_shipperstate
   ,in_shipperpostalcode
   ,in_shippercountrycode
   ,in_shipperphone
   ,in_shipperfax
   ,in_shipperemail
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
   ,l_billtoname
   ,in_billtocontact
   ,l_billtoaddr1
   ,l_billtoaddr2
   ,l_billtocity
   ,l_billtostate
   ,l_billtopostalcode
   ,in_billtocountrycode
   ,in_billtophone
   ,in_billtofax
   ,in_billtoemail
   ,in_deliveryservice
   ,in_saturdaydelivery
   ,in_cod
   ,in_amtcod
   ,in_specialservice1
   ,in_specialservice2
   ,in_specialservice3
   ,in_specialservice4
   ,in_importfileid
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
   ,null,null,null,null,null,null,null,null,null,null
   ,null,null,null,null,null,null,null,null,null,null
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
   ,in_cancel_after
   ,in_delivery_requested
   ,in_requested_ship
   ,in_ship_not_before
   ,in_ship_no_later
   ,in_cancel_if_not_delivered_by
   ,in_do_not_deliver_after
   ,in_do_not_deliver_before
   ,in_hdrpassthrudate01
   ,in_hdrpassthrudate02
   ,in_hdrpassthrudate03
   ,in_hdrpassthrudate04
   ,in_hdrpassthrudoll01
   ,in_hdrpassthrudoll02
   ,in_rfautodisplay
   ,in_ignore_received_orders_yn
   ,in_arrivaldate
   ,in_validate_shipto
   ,in_abc_revision
   ,null --in_prono
   ,null,null,null,null,null,null,null,null,null,null,null,null,null
   ,out_orderid
   ,out_shipid
   ,out_errorno
   ,out_msg
   );
if out_msg = 'OKAY' then
   if in_bolcomment is not null then
      zimp.import_order_header_bolcomment(
         in_func
         ,in_custid
         ,in_reference
         ,in_po
         ,in_bolcomment
         ,null --in_abc_revision
         ,out_orderid
         ,out_shipid
         ,out_errorno
         ,out_msg
         );
   end if;
end if;


exception when others then
  out_msg := 'zioh2k ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_headerD2k;

procedure import_order_lineD2k
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
,in_rfautodisplay varchar2
,in_comment  long
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_variance_pct_shortage number
,in_variance_pct_overage number
,in_variance_use_default_yn varchar2
,in_abc_revision in varchar2
,in_header_carrier varchar2
,in_defaultuom IN varchar2
,in_bolcomment IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
l_uomentered orderdtl.uomentered%type;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

begin
   select baseuom into l_uomentered from custitem
      where custid = in_custid
        and item = in_itementered;
exception when others then
   if in_defaultuom is not null then
      l_uomentered := in_defaultuom;
   else
      l_uomentered := 'CS';
   end if;
end;

zimp.import_order_line(
   in_func
   ,in_custid
   ,in_reference
   ,in_po
   ,in_itementered
   ,in_lotnumber
   ,l_uomentered
   ,in_qtyentered
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
   ,null,null,null,null,null,null,null,null,null,null
   ,null,null,null,null,null,null,null,null,null,null
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
   ,null,null,null,null,null,null,null,null,null,null
   ,in_dtlpassthrudate01
   ,in_dtlpassthrudate02
   ,in_dtlpassthrudate03
   ,in_dtlpassthrudate04
   ,in_dtlpassthrudoll01
   ,in_dtlpassthrudoll02
   ,in_rfautodisplay
   ,in_comment
   ,in_weight_entered_lbs
   ,in_weight_entered_kgs
   ,in_variance_pct_shortage
   ,in_variance_pct_overage
   ,in_variance_use_default_yn
   ,in_abc_revision
   ,in_header_carrier
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null
   ,null,null
   ,out_orderid
   ,out_shipid
   ,out_errorno
   ,out_msg
   );

if out_msg = 'OKAY' then
   if in_bolcomment is not null then
      zimp.import_order_line_bolcomment(
         in_func
         ,in_custid
         ,in_reference
         ,in_po
         ,in_itementered
         ,in_lotnumber
         ,in_bolcomment
         ,in_abc_revision
         ,out_orderid
         ,out_shipid
         ,out_errorno
         ,out_msg
         );
   end if;
end if;


exception when others then
  out_msg := 'ziol2k ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_lineD2k;


procedure spreadsheet_import_orderD2k
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_apptdate IN date
,in_shipdate  IN varchar2
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
,in_rfautodisplay varchar2
,in_ignore_received_orders_yn varchar2
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
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_importfileid IN varchar2
,in_instructions varchar2
,in_include_cr_lf_yn varchar2
,in_bolcomment varchar2
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
,in_dtlrfautodisplay varchar2
,in_dtlinstructions varchar2
,in_dtlbolcomment varchar2
,in_use_base_uom varchar2
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_variance_pct_shortage number
,in_variance_pct_overage number
,in_variance_use_default_yn varchar2
,in_defaultuom IN varchar2
,in_arrivaldate IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

l_uomentered orderdtl.uomentered%type;
l_item orderdtl.itementered%type;
l_shipterms orderhdr.shipterms%type;
l_shiptype orderhdr.shiptype%type;
l_shipdate date;
l_arrivaldate date;
l_consignee VARCHAR2(10);

curFunc integer;
cntRows integer;
cmdSql varchar2(2000);

TYPE cur_type is REF CURSOR;
cr cur_type;


procedure order_msg(in_msgtype varchar2) is
pragma autonomous_transaction;
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, in_fromfacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  commit;

end;



BEGIN
   out_errorno := 0;
   out_msg := '';
   out_orderid := 0;
   out_shipid := 0;
   l_item := in_itementered;
  if rtrim(in_custid) = '01198' then
   if substr(in_itementered,1,14) = 'FG:FG - D2000:' then
      l_item := rtrim(substr(in_itementered,15));
   elsif substr(in_itementered,1,28) = 'Corrugated:Corrugated - D2K:' then
      l_item := rtrim(substr(in_itementered,29));
   elsif substr(in_itementered,1,9) = 'MD - D2K:' then
        l_item := rtrim(substr(in_itementered,10));
     else
         out_errorno := -1;
         out_msg := 'Skipping item ' || in_itementered;
         order_msg('I');
         return;
     end if;

  elsif rtrim(in_custid) = '02012' then
     if substr(in_itementered,1,9) = 'FG - D2K:' then
      l_item := rtrim(substr(in_itementered,10));
   else
       out_errorno := -1;
       out_msg := 'Skipping item ' || in_itementered;
       order_msg('I');
       return;
     end if;

  elsif rtrim(in_custid) = '01218' or
        rtrim(in_custid) = '02000' or
        rtrim(in_custid) = '01220' or
        rtrim(in_custid) = '02002' or
        rtrim(in_custid) = '02007' or
        rtrim(in_custid) = '02008' or
        rtrim(in_custid) = '02027' or
        rtrim(in_custid) = '02034' or
        rtrim(in_custid) = '02036' or
        rtrim(in_custid) = '02040' or
        rtrim(in_custid) = '02066' then
      l_item := in_itementered;
      if rtrim(in_carrier) = 'STA' then
        l_consignee := 'STA';
      elsif substr(in_carrier,1,2) = 'UP' then
        l_consignee := 'EDI';
      elsif rtrim(in_carrier) = 'STL' and
        rtrim(in_custid) = '02002' then
        l_consignee := 'STL';
      end if;
   end if;


   begin
      select baseuom into l_uomentered from custitem
         where custid = in_custid
           and item = in_itementered;
   exception when others then
      if in_defaultuom is not null then
         l_uomentered := in_defaultuom;
      else
         l_uomentered := 'CS';
      end if;
   end;

   l_shipterms := null;
   if in_carrier is null then
      out_msg := 'No carrier - no ship terms';
      order_msg('E');
   else
      begin

         cmdSql := 'select abbrev ' ||
                   ' from CarrierTableXref' || in_custid ||
                   ' where rtrim(code) = rtrim('''||in_carrier||''')';
         open cr for cmdsql;
         fetch cr into l_shipterms;
         close cr;
      exception when others then
         out_msg := 'Carrier '|| in_carrier ||' not found in CarrierTableXref' || in_custid;
         order_msg('E');
      end;
   end if;
   begin
      if rtrim(in_custid) = '02054' then
          l_arrivaldate := to_date(in_arrivaldate,'YYYY-MM-DD');
      else
      l_arrivaldate := to_date(in_arrivaldate,'MM/DD/YYYY');
      end if;
   exception when others then
      l_arrivaldate := null;
   end;

   begin
      if rtrim(in_custid) = '01218' or rtrim(in_custid) = '02000' or rtrim(in_custid) = '02007' or rtrim(in_custid) = '02012' or rtrim(in_custid) = '02027' then
          l_shipdate := to_date(in_arrivaldate,'MM/DD/YYYY');
      elsif rtrim(in_custid) = '02054' then
          l_shipdate := to_date(in_shipdate,'YYYY-MM-DD');
      else
          l_shipdate := to_date(in_shipdate,'MM/DD/YYYY');
      end if;
   exception when others then
      l_shipdate := null;
   end;

   zimportprocspreadsheet.spreadsheet_import_order
      (in_func
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
      ,l_consignee
      ,in_shiptype
      ,in_carrier
      ,in_reference
      ,l_shipterms
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
      ,in_deliveryservice
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
      ,in_hdrpassthruchar20
      ,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
      ,null,null,null,null,null,null,null,null,null,null
      ,null,null
      ,null,null,null,null,null,null,null,null,null,null
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
      ,l_item
      ,in_lotnumber
      ,in_uomentered
      ,in_qtyentered
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
      ,null,null,null,null,null,null,null,null,null,null
      ,null,null,null,null,null,null,null,null,null,null
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
      ,null,null,null,null,null,null,null,null,null,null
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
      ,null -- in_prono
      ,in_weight_entered_lbs
      ,in_weight_entered_kgs
      ,in_variance_pct_shortage
      ,in_variance_pct_overage
      ,in_variance_use_default_yn
      ,l_arrivaldate
      ,null
      ,null
      ,null
      ,null
      ,out_orderid
      ,out_shipid
      ,out_errorno
      ,out_msg
      );


END spreadsheet_import_orderD2k;


end zimportprocsD2k;
/
show error package body zimportprocsD2k;
exit;
