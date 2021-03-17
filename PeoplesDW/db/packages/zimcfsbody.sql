create or replace package body alps.zimportproccfs as
--
-- $Id: zimcfsbody.sql 8807 2012-08-22 20:08:23Z jean $
--

IMP_USERID constant varchar2(8) := 'IMPORDER';
 strMsg appmsgs.msgtext%type;

procedure import_order_header_cfs
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
,in_prono varchar2
,in_editransaction in varchar2
,in_edi_logging_yn in varchar2
,in_futurevc01 in varchar2
,in_futurevc02 in varchar2
,in_futurevc03 in varchar2
,in_futurevc04 in varchar2
,in_futurevc05 in varchar2
,in_futurevc06 in varchar2
,in_futurenum01 in number
,in_futurenum02 in number
,in_futurenum03 in number
,in_shipto_use_local_ipi_yn in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

l_shipto orderhdr.shipto%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := ' Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := ' Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(in_tofacility, in_fromfacility), rtrim(in_custid),
    'IMP HDR CFS 943 '||out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

BEGIN
--out_msg := in_reference||' - '||in_custid||' - '||in_func||' - '||in_ordertype;
--zms.log_autonomous_msg(IMP_USERID, null, rtrim(in_custid), 'IMP HDR CFS 943 '||out_msg,'I', IMP_USERID, strMsg);

out_errorno := 0;
out_msg := null;

if nvl(in_reference, 'none') = 'none' then
 out_msg := 'Missing reference';
 order_msg('E');
 return;
end if;

if nvl(in_custid, 'none') = 'none' then
 out_msg := 'Missing customer ID.';
 order_msg('E');
 return;
end if;

if nvl(in_func, 'none') = 'none' then
 out_msg := 'Missing Action';
 order_msg('E');
 return;
end if;

if nvl(in_carrier, 'none') = 'none' then
 out_msg := 'Missing carrier';
 order_msg('E');
 return;
end if;

if nvl(rtrim(in_shipto_use_local_ipi_yn), 'x') = 'Y' then
    select decode(in_shipto,
                  null, 'LOCAL',
                  'LOCAL', 'LOCAL',
                  'IPI-'||in_shipto)
    into l_shipto
    from dual;
else
    l_shipto := in_shipto;
end if;

zimportprocs.import_order_header
(in_func 
,in_custid 
,in_ordertype 
,in_apptdate 
,in_shipdate 
,in_po 
,in_rma 
,in_fromfacility 
,in_tofacility 
,l_shipto 
,in_billoflading 
,in_priority 
,in_shipper 
,in_consignee 
,in_shiptype 
,in_carrier 
,in_reference 
,in_shipterms 
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
,in_prono 
,in_editransaction 
,in_edi_logging_yn 
,in_futurevc01 
,in_futurevc02 
,in_futurevc03 
,in_futurevc04 
,in_futurevc05 
,in_futurevc06 
,in_futurenum01 
,in_futurenum02 
,in_futurenum03
,null -- in_order_acknowledgment
,null -- in_canceled_new_order
,out_orderid 
,out_shipid 
,out_errorno 
,out_msg 
);

exception when others then
  out_msg := 'zimiohcfs ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_header_cfs;

procedure import_order_line_cfs
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
,in_lineorder varchar2
,in_cancel_productgroup varchar2
,in_invclass_states in varchar2
,in_invclass_states_value in varchar2
,in_upper_item_yn varchar2
,in_notnullpassthrus_yn IN varchar2
,in_delete_by_linenumber_yn in varchar2
,in_weight_acceptance_yn in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

l_itementered orderdtl.item%type;
l_invstatus orderdtl.invstatus%type;
strMsg appmsgs.msgtext%type;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || l_itementered || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_autonomous_msg(IMP_USERID, null, rtrim(in_custid),
    'IMP DTL CFS 943 '||out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

BEGIN
--out_msg := in_reference||' * '||in_custid||' * '||in_func||
--   ' * '||in_lotnumber ||' * '||in_uomentered ||
--   ' * '||in_qtyentered||' * '||in_dtlpassthruchar01;
--zms.log_autonomous_msg(IMP_USERID, null, rtrim(in_custid), 'IMP DTL CFS 943 '||out_msg,'I', IMP_USERID, strMsg);
   
out_errorno := 0;
out_msg := null;
    
if nvl(in_reference, 'none') = 'none' then
 out_msg := 'Missing reference';
 item_msg('E');
 return;
end if;

if nvl(in_custid, 'none') = 'none' then
 out_msg := 'Missing customer ID.';
 item_msg('E');
 return;
end if;

if nvl(in_func, 'none') = 'none' then
 out_msg := 'Missing Action';
 item_msg('E');
 return;
end if;

if nvl(in_lotnumber, 'none') = 'none' then
 out_msg := 'Missing lotnumber';
 item_msg('E');
 return;
end if;

if nvl(in_uomentered, 'none') = 'none' then
 out_msg := 'Missing Unit of measure';
 item_msg('E');
 return;
end if;

if nvl(in_qtyentered,0) = 0 then
 out_msg := 'Missing quantity';
 item_msg('E');
 return;
end if;

l_itementered := rtrim(in_custid)||'-'||'ITEM';

select decode(in_invstatus,
                'CHI', 'CH',
                'NYK', 'NY',
                'ATL', 'AT',
                in_invstatus)
into l_invstatus
from dual;
   
zimportprocs.import_order_line
(in_func
,in_custid 
,in_reference 
,in_po
,l_itementered
,in_lotnumber
,in_uomentered 
,in_qtyentered 
,in_backorder 
,in_allowsub 
,in_qtytype 
,in_invstatusind 
,l_invstatus 
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
,in_rfautodisplay 
,in_comment
,in_weight_entered_lbs 
,in_weight_entered_kgs 
,in_variance_pct_shortage 
,in_variance_pct_overage 
,in_variance_use_default_yn 
,in_abc_revision 
,in_header_carrier 
,in_lineorder 
,in_cancel_productgroup 
,in_invclass_states 
,in_invclass_states_value 
,in_upper_item_yn
,null
,null
,in_notnullpassthrus_yn 
,in_delete_by_linenumber_yn 
,in_weight_acceptance_yn 
,null
,null
,null
,null
,null
,out_orderid 
,out_shipid 
,out_errorno 
,out_msg
);

exception when others then
  out_msg := 'zimiolcfs ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_line_cfs;

end zimportproccfs;
/
show errors package body zimportproccfs;
exit;
