create or replace package body alps.zimportprocs as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure import_order_header
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
,in_order_acknowledgment in varchar2
,in_canceled_new_order in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         nvl(fromfacility,tofacility) facility,
         ordertype,
         nvl(loadno, 0) as loadno
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdr_not_canceled (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         nvl(fromfacility,tofacility) facility,
         ordertype,
         nvl(loadno, 0) as loadno
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and orderstatus <> 'X'
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(resubmitorder,'N') as resubmitorder,
        unique_order_identifier,
        nvl(dup_reference_ynw,'N') as dup_reference_ynw,
        nvl(bbb_routing_yn, 'N') as bbb_routing_yn,
        bbb_control_value_passthru_col,
        bbb_control_value,
        include_ack_cancel_orders_yn
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;
cursor curConsignee(in_consignee varchar2) is
  select consignee,consorderupdate,facilitycode,shiplabelcode,retailabelcode,
         packslipcode,tpacct,storenumber,distctrnumber,
       name,contact,addr1,addr2,city,state,postalcode,countrycode,
       phone,fax,email
    from consignee
   where consignee = in_consignee;
co curConsignee%rowtype;

cntCons integer;
cntRows integer;
strShipto orderhdr.shipto%type;
strShiptoname orderhdr.shiptoname%type;
strShiptocontact orderhdr.shiptocontact%type;
strShiptoaddr1 orderhdr.shiptoaddr1%type;
strShiptoaddr2 orderhdr.shiptoaddr2%type;
strShiptocity orderhdr.shiptocity%type;
strShiptostate orderhdr.shiptostate%type;
strShiptopostalcode orderhdr.shiptopostalcode%type;
strShiptophone orderhdr.shiptophone%type;
strShiptofax orderhdr.shiptofax%type;
strShiptoemail orderhdr.shiptoemail%type;
strShiptocountrycode orderhdr.shiptocountrycode%type;
strReference orderhdr.reference%type;
strHdrPassThruChar06 orderhdr.hdrpassthruchar06%type;
strHdrPassThruChar08 orderhdr.hdrpassthruchar08%type;
strHdrPassThruChar10 orderhdr.hdrpassthruchar10%type;
strHdrPassThruChar11 orderhdr.hdrpassthruchar11%type;
strHdrPassThruChar12 orderhdr.hdrpassthruchar12%type;
strHdrPassThruChar33 orderhdr.hdrpassthruchar33%type;
strHdrPassThruChar50 orderhdr.hdrpassthruchar50%type;
ediMsg varchar(255);
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
dtearrivaldate DATE;
l_consigneestatus consignee.consigneestatus%type;
l_shipto_master consignee.shipto_master%type;
msg varchar2(255) := null;
l_cmd varchar2(255);
errorno integer;

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
strStatus char(1);
begin
  if nvl(cs.unique_order_identifier,'R') = 'P' then
    out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference)
        ||' PO. '||rtrim(in_po)|| ': ' || out_msg;
  else
    out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference)
        || ': ' || out_msg;
  end if;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(in_fromfacility,in_tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  if nvl(in_order_acknowledgment,'N') = 'Y' then
     if in_msgtype = 'E' then
        strStatus := 'E';
     else
        strStatus := 'A';
     end if;
     zimportprocs.log_order_import_ack(in_importfileid, in_custid, in_po , in_reference,
                                       out_orderid, out_shipid, strStatus, out_msg, in_func);
  end if;
end;

procedure update_cancel_importfileid(in_orderid number,in_shipid number, in_importfileid varchar2)
is pragma AUTONOMOUS_TRANSACTION;
strMsg appmsgs.msgtext%type;
begin
    update orderhdr 
       set cancel_importfileid = upper(rtrim(in_importfileid))
    where orderid = in_orderid
      and shipid = in_shipid;
   commit;
exception when others then
  rollback;
end update_cancel_importfileid;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
if nvl(in_edi_logging_yn,'N') = 'Y' then
   ediMsg := 'ORDERIMPORT '|| in_reference;
   zedi.edi_import_log(in_editransaction, in_importfileid, in_custid, ediMsg, out_msg);
end if;

if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

if nvl(rtrim(in_func),'x') = 'E' then
  out_errorno := 4;
  out_msg := 'func E, skip order import ';
  order_msg('W');
  return;
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code: ' || nvl(in_func,'null');
  order_msg('E');
  return;
end if;

if nvl(in_canceled_new_order, 'N') = 'Y' then
   open curOrderHdr_not_canceled(strReference);
   fetch curOrderHdr_not_canceled into oh;
   if curOrderHdr_not_canceled%found then
     if nvl(rtrim(in_ignore_received_orders_yn),'N') = 'Y' and
        oh.ordertype in ('R','Q','P','A','C','I') and
        oh.orderstatus in ('R','X') then
       null;
     else
       out_orderid := oh.orderid;
       out_shipid := oh.shipid;
     end if;
   end if;
   close curOrderHdr_not_canceled;
else
   open curOrderhdr(strReference);
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     if nvl(rtrim(in_ignore_received_orders_yn),'N') = 'Y' and
        oh.ordertype in ('R','Q','P','A','C','I') and
        oh.orderstatus in ('R','X') then
       null;
     else
       out_orderid := oh.orderid;
       out_shipid := oh.shipid;
     end if;
   end if;
   close curOrderhdr;
end if;

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

BEGIN
  IF TRUNC(in_arrivaldate) = TO_DATE('12/30/1899','mm/dd/yyyy') THEN
    dtearrivaldate := NULL;
  ELSE
    dtearrivaldate := in_arrivaldate;
  END IF;
EXCEPTION WHEN OTHERS THEN
  dtehdrpassthrudate04 := NULL;
END;

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.resubmitorder := 'N';
  cs.dup_reference_ynw := 'N';
  cs.bbb_routing_yn := 'N';
end if;
close curCustomer;

if rtrim(in_func) = 'A' then
  if out_orderid != 0 then
    if cs.dup_reference_ynw = 'H' then
       out_orderid := 0; -- force new orderid
       out_msg := 'Warning: duplicate reference: ' || in_reference;
       order_msg('W');
    else
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
end if;

if rtrim(in_func) = 'U' then
  if out_orderid = 0 then
    out_msg := 'Update requested--order not on file--add performed';
    order_msg('W');
    in_func := 'A';
  else
    if oh.orderstatus > '1' then
      out_errorno := 2;
      out_msg := 'Invalid Order Status for update: ' || oh.orderstatus;
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
    if oh.loadno > 0 then
      zld.deassign_order_from_load(out_orderid, out_shipid, oh.facility, IMP_USERID,
        'N', errorno, msg);
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

strShipto := in_shipto;
strShiptoname := in_shiptoname;
strShiptocontact := in_shiptocontact;
strShiptoaddr1 := in_shiptoaddr1;
strShiptoaddr2 := in_shiptoaddr2;
strShiptocity := in_shiptocity;
strShiptostate := in_shiptostate;
strShiptopostalcode := in_shiptopostalcode;
strShiptophone := in_shiptophone;
strShiptofax := in_shiptofax;
strShiptoemail := in_shiptoemail;
strShiptocountrycode := in_shiptocountrycode;

if nvl(in_validate_shipto,'n') = 'Y' then
   select count(1) into cntCons
      from custconsignee
      where custid = in_custid
        and consignee = in_shipto;
   if cntCons = 0 then
      strShipto := null;
   else
      strShiptoname := null;
      strShiptocontact := null;
      strShiptoaddr1 := null;
      strShiptoaddr2 := null;
      strShiptocity := null;
      strShiptostate := null;
      strShiptopostalcode := null;
      strShiptophone := null;
      strShiptofax := null;
      strShiptoemail := null;
      strShiptocountrycode := null;
   end if;
end if;


strHdrPassThruChar06 := in_hdrpassthruchar06;
strHdrPassThruChar08 := in_hdrpassthruchar08;
strHdrPassThruChar10 := in_hdrpassthruchar10;
strHdrPassThruChar11 := in_hdrpassthruchar11;
strHdrPassThruChar12 := in_hdrpassthruchar12;
strHdrPassThruChar33 := in_hdrpassthruchar33;
strHdrPassThruChar50 := in_hdrpassthruchar50;
if in_ordertype = 'O' and
   in_shipto is not null then
   open curConsignee(in_shipto);
   fetch curConsignee into co;
   close curConsignee;
   if nvl(co.consorderupdate,'N') = 'Y' then
      strHdrPassThruChar06 := nvl(co.packslipcode,in_hdrpassthruchar06);
      strHdrPassThruChar08 := nvl(co.tpacct,in_hdrpassthruchar08);
      strHdrPassThruChar10 := nvl(co.shiplabelcode,in_hdrpassthruchar10);
      strHdrPassThruChar11 := nvl(co.retailabelcode,in_hdrpassthruchar11);
      strHdrPassThruChar12 := nvl(co.facilitycode,in_hdrpassthruchar12);
      strHdrPassThruChar33 := nvl(co.storenumber,in_hdrpassthruchar33);
      strHdrPassThruChar50 := nvl(co.distctrnumber,in_hdrpassthruchar50);
     strShipTo := null;
      strShiptoname := co.name;
      strShiptocontact := co.contact;
      strShiptoaddr1 := co.addr1;
      strShiptoaddr2 := co.addr2;
      strShiptocity := co.city;
      strShiptostate := co.state;
      strShiptopostalcode := co.postalcode;
      strShiptophone := co.phone;
      strShiptofax := co.fax;
      strShiptoemail := co.email;
      strShiptocountrycode := co.countrycode;
   end if;
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
   hdrpassthruchar21, hdrpassthruchar22, hdrpassthruchar23, hdrpassthruchar24,
   hdrpassthruchar25, hdrpassthruchar26, hdrpassthruchar27, hdrpassthruchar28,
   hdrpassthruchar29, hdrpassthruchar30, hdrpassthruchar31, hdrpassthruchar32,
   hdrpassthruchar33, hdrpassthruchar34, hdrpassthruchar35, hdrpassthruchar36,
   hdrpassthruchar37, hdrpassthruchar38, hdrpassthruchar39, hdrpassthruchar40,
   hdrpassthruchar41, hdrpassthruchar42, hdrpassthruchar43, hdrpassthruchar44,
   hdrpassthruchar45, hdrpassthruchar46, hdrpassthruchar47, hdrpassthruchar48,
   hdrpassthruchar49, hdrpassthruchar50, hdrpassthruchar51, hdrpassthruchar52,
   hdrpassthruchar53, hdrpassthruchar54, hdrpassthruchar55, hdrpassthruchar56,
   hdrpassthruchar57, hdrpassthruchar58, hdrpassthruchar59, hdrpassthruchar60,
   hdrpassthrunum01, hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04,
   hdrpassthrunum05, hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08,
   hdrpassthrunum09, hdrpassthrunum10, importfileid, deliveryservice,
   saturdaydelivery, cod, amtcod,
   specialservice1, specialservice2,
   specialservice3, specialservice4, source,
   cancel_after, delivery_requested, requested_ship,
   ship_not_before, ship_no_later, cancel_if_not_delivered_by,
   do_not_deliver_after, do_not_deliver_before,
   hdrpassthrudate01, hdrpassthrudate02,
   hdrpassthrudate03, hdrpassthrudate04,
   hdrpassthrudoll01, hdrpassthrudoll02,
   rfautodisplay, arrivaldate, prono, editransaction
   )
  values
  (out_orderid,out_shipid,nvl(rtrim(in_custid),' '),nvl(rtrim(in_ordertype),' '),
  dteApptdate,dteShipDate,rtrim(in_po),rtrim(in_rma),rtrim(in_fromfacility),
  rtrim(in_tofacility),rtrim(strShipto),rtrim(in_billoflading),
  rtrim(in_priority),rtrim(in_shipper),rtrim(in_consignee),rtrim(in_shiptype),
  rtrim(in_carrier),rtrim(strReference),rtrim(in_shipterms),rtrim(in_shippername),
  rtrim(in_shippercontact),
  rtrim(in_shipperaddr1),rtrim(in_shipperaddr2),rtrim(in_shippercity),
  rtrim(in_shipperstate),rtrim(in_shipperpostalcode),rtrim(in_shippercountrycode),
  rtrim(in_shipperphone),rtrim(in_shipperfax),rtrim(in_shipperemail),rtrim(strShiptoname),
  rtrim(strShiptocontact),
  rtrim(strShiptoaddr1),rtrim(strShiptoaddr2),rtrim(strShiptocity),
  rtrim(strShiptostate),rtrim(strShiptopostalcode),rtrim(strShiptocountrycode),
  rtrim(strShiptophone),rtrim(strShiptofax),rtrim(strShiptoemail),
  rtrim(in_billtoname),rtrim(in_billtocontact),rtrim(in_billtoaddr1),rtrim(in_billtoaddr2),
  rtrim(in_billtocity),rtrim(in_billtostate),rtrim(in_billtopostalcode),
  rtrim(in_billtocountrycode),rtrim(in_billtophone),rtrim(in_billtofax),
  rtrim(in_billtoemail),IMP_USERID,sysdate,
  '0','0',IMP_USERID,sysdate,
  rtrim(in_hdrpassthruchar01),rtrim(in_hdrpassthruchar02),
  rtrim(in_hdrpassthruchar03),rtrim(in_hdrpassthruchar04),
  rtrim(in_hdrpassthruchar05),rtrim(strhdrpassthruchar06),
  rtrim(in_hdrpassthruchar07),rtrim(strhdrpassthruchar08),
  rtrim(in_hdrpassthruchar09),rtrim(strhdrpassthruchar10),
  rtrim(strhdrpassthruchar11),rtrim(strhdrpassthruchar12),
  rtrim(in_hdrpassthruchar13),rtrim(in_hdrpassthruchar14),
  rtrim(in_hdrpassthruchar15),rtrim(in_hdrpassthruchar16),
  rtrim(in_hdrpassthruchar17),rtrim(in_hdrpassthruchar18),
  rtrim(in_hdrpassthruchar19),rtrim(in_hdrpassthruchar20),
  rtrim(in_hdrpassthruchar21),rtrim(in_hdrpassthruchar22),
  rtrim(in_hdrpassthruchar23),rtrim(in_hdrpassthruchar24),
  rtrim(in_hdrpassthruchar25),rtrim(in_hdrpassthruchar26),
  rtrim(in_hdrpassthruchar27),rtrim(in_hdrpassthruchar28),
  rtrim(in_hdrpassthruchar29),rtrim(in_hdrpassthruchar30),
  rtrim(in_hdrpassthruchar31),rtrim(in_hdrpassthruchar32),
  rtrim(strhdrpassthruchar33),rtrim(in_hdrpassthruchar34),
  rtrim(in_hdrpassthruchar35),rtrim(in_hdrpassthruchar36),
  rtrim(in_hdrpassthruchar37),rtrim(in_hdrpassthruchar38),
  rtrim(in_hdrpassthruchar39),rtrim(in_hdrpassthruchar40),
  rtrim(in_hdrpassthruchar41),rtrim(in_hdrpassthruchar42),
  rtrim(in_hdrpassthruchar43),rtrim(in_hdrpassthruchar44),
  rtrim(in_hdrpassthruchar45),rtrim(in_hdrpassthruchar46),
  rtrim(in_hdrpassthruchar47),rtrim(in_hdrpassthruchar48),
  rtrim(in_hdrpassthruchar49),rtrim(strhdrpassthruchar50),
  rtrim(in_hdrpassthruchar51),rtrim(in_hdrpassthruchar52),
  rtrim(in_hdrpassthruchar53),rtrim(in_hdrpassthruchar54),
  rtrim(in_hdrpassthruchar55),rtrim(in_hdrpassthruchar56),
  rtrim(in_hdrpassthruchar57),rtrim(in_hdrpassthruchar58),
  rtrim(in_hdrpassthruchar59),rtrim(in_hdrpassthruchar60),
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
  'EDI',
  dtecancel_after, dtedelivery_requested, dterequested_ship,
  dteship_not_before, dteship_no_later, dtecancel_if_not_delivered_by,
  dtedo_not_deliver_after, dtedo_not_deliver_before,
  dtehdrpassthrudate01, dtehdrpassthrudate02,
  dtehdrpassthrudate03, dtehdrpassthrudate04,
  decode(in_hdrpassthrudoll01,0,null,in_hdrpassthrudoll01),
  decode(in_hdrpassthrudoll02,0,null,in_hdrpassthrudoll02),
  in_rfautodisplay, dtearrivaldate, rtrim(in_prono),  rtrim(in_editransaction)
  );
  if (cs.bbb_routing_yn != 'N') and
     (zbbb.is_a_bbb_order(rtrim(in_custid),out_orderid,out_shipid) = 'Y')  then
    begin
      select consigneestatus, shipto_master
        into l_consigneestatus, l_shipto_master
        from consignee
       where consignee = in_shipto;
    exception when others then
      l_consigneestatus := 'A';
      l_shipto_master := '';
    end;
    begin
      l_cmd := 'update orderhdr set ' ||
                cs.bbb_control_value_passthru_col ||
               ' = ''';
      if l_consigneestatus = 'I' then
        l_cmd := l_cmd || 'INACTIVE';
      else
        l_cmd := l_cmd || cs.bbb_control_value;
      end if;
      l_cmd := l_cmd ||
               ''', shipto_master = ''' || l_shipto_master ||
               ''' where orderid = ' || out_orderid ||
               ' and shipid = ' || out_shipid;
      execute immediate l_cmd;
    exception when others then
      out_msg := 'Unable to update routing control value: ' || l_cmd;
      order_msg('W');
    end;
  end if;
elsif rtrim(in_func) = 'U' then
  update orderhdr
     set orderstatus = '0',
         commitstatus = '0',
         apptdate = nvl(dteapptdate,apptdate),
         shipdate = nvl(dteShipDate,shipdate),
         shipto = nvl(rtrim(strShipto),shipto),
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
         shiptoname = nvl(rtrim(strShiptoname),shiptoname),
         shiptocontact = nvl(rtrim(strShiptocontact),shiptocontact),
         shiptoaddr1 = nvl(rtrim(strShiptoaddr1),shiptoaddr1),
         shiptoaddr2 = nvl(rtrim(strShiptoaddr2),shiptoaddr2),
         shiptocity = nvl(rtrim(strShiptocity),shiptocity),
         shiptostate = nvl(rtrim(strShiptostate),shiptostate),
         shiptopostalcode = nvl(rtrim(strShiptopostalcode),shiptopostalcode),
         shiptocountrycode = nvl(rtrim(strShiptocountrycode),shiptocountrycode),
         shiptophone = nvl(rtrim(strShiptophone),shiptophone),
         shiptofax = nvl(rtrim(strShiptofax),shiptofax),
         shiptoemail = nvl(rtrim(strShiptoemail),shiptoemail),
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
         hdrpassthruchar06 = nvl(rtrim(strhdrpassthruchar06),hdrpassthruchar06),
         hdrpassthruchar07 = nvl(rtrim(in_hdrpassthruchar07),hdrpassthruchar07),
         hdrpassthruchar08 = nvl(rtrim(strhdrpassthruchar08),hdrpassthruchar08),
         hdrpassthruchar09 = nvl(rtrim(in_hdrpassthruchar09),hdrpassthruchar09),
         hdrpassthruchar10 = nvl(rtrim(strhdrpassthruchar10),hdrpassthruchar10),
         hdrpassthruchar11 = nvl(rtrim(strhdrpassthruchar11),hdrpassthruchar11),
         hdrpassthruchar12 = nvl(rtrim(strhdrpassthruchar12),hdrpassthruchar12),
         hdrpassthruchar13 = nvl(rtrim(in_hdrpassthruchar13),hdrpassthruchar13),
         hdrpassthruchar14 = nvl(rtrim(in_hdrpassthruchar14),hdrpassthruchar14),
         hdrpassthruchar15 = nvl(rtrim(in_hdrpassthruchar15),hdrpassthruchar15),
         hdrpassthruchar16 = nvl(rtrim(in_hdrpassthruchar16),hdrpassthruchar16),
         hdrpassthruchar17 = nvl(rtrim(in_hdrpassthruchar17),hdrpassthruchar17),
         hdrpassthruchar18 = nvl(rtrim(in_hdrpassthruchar18),hdrpassthruchar18),
         hdrpassthruchar19 = nvl(rtrim(in_hdrpassthruchar19),hdrpassthruchar19),
         hdrpassthruchar20 = nvl(rtrim(in_hdrpassthruchar20),hdrpassthruchar20),
         hdrpassthruchar21 = nvl(rtrim(in_hdrpassthruchar21),hdrpassthruchar21),
         hdrpassthruchar22 = nvl(rtrim(in_hdrpassthruchar22),hdrpassthruchar22),
         hdrpassthruchar23 = nvl(rtrim(in_hdrpassthruchar23),hdrpassthruchar23),
         hdrpassthruchar24 = nvl(rtrim(in_hdrpassthruchar24),hdrpassthruchar24),
         hdrpassthruchar25 = nvl(rtrim(in_hdrpassthruchar25),hdrpassthruchar25),
         hdrpassthruchar26 = nvl(rtrim(in_hdrpassthruchar26),hdrpassthruchar26),
         hdrpassthruchar27 = nvl(rtrim(in_hdrpassthruchar27),hdrpassthruchar27),
         hdrpassthruchar28 = nvl(rtrim(in_hdrpassthruchar28),hdrpassthruchar28),
         hdrpassthruchar29 = nvl(rtrim(in_hdrpassthruchar29),hdrpassthruchar29),
         hdrpassthruchar30 = nvl(rtrim(in_hdrpassthruchar30),hdrpassthruchar30),
         hdrpassthruchar31 = nvl(rtrim(in_hdrpassthruchar31),hdrpassthruchar31),
         hdrpassthruchar32 = nvl(rtrim(in_hdrpassthruchar32),hdrpassthruchar32),
         hdrpassthruchar33 = nvl(rtrim(strhdrpassthruchar33),hdrpassthruchar33),
         hdrpassthruchar34 = nvl(rtrim(in_hdrpassthruchar34),hdrpassthruchar34),
         hdrpassthruchar35 = nvl(rtrim(in_hdrpassthruchar35),hdrpassthruchar35),
         hdrpassthruchar36 = nvl(rtrim(in_hdrpassthruchar36),hdrpassthruchar36),
         hdrpassthruchar37 = nvl(rtrim(in_hdrpassthruchar37),hdrpassthruchar37),
         hdrpassthruchar38 = nvl(rtrim(in_hdrpassthruchar38),hdrpassthruchar38),
         hdrpassthruchar39 = nvl(rtrim(in_hdrpassthruchar39),hdrpassthruchar39),
         hdrpassthruchar40 = nvl(rtrim(in_hdrpassthruchar40),hdrpassthruchar40),
         hdrpassthruchar41 = nvl(rtrim(in_hdrpassthruchar41),hdrpassthruchar41),
         hdrpassthruchar42 = nvl(rtrim(in_hdrpassthruchar42),hdrpassthruchar42),
         hdrpassthruchar43 = nvl(rtrim(in_hdrpassthruchar43),hdrpassthruchar43),
         hdrpassthruchar44 = nvl(rtrim(in_hdrpassthruchar44),hdrpassthruchar44),
         hdrpassthruchar45 = nvl(rtrim(in_hdrpassthruchar45),hdrpassthruchar45),
         hdrpassthruchar46 = nvl(rtrim(in_hdrpassthruchar46),hdrpassthruchar46),
         hdrpassthruchar47 = nvl(rtrim(in_hdrpassthruchar47),hdrpassthruchar47),
         hdrpassthruchar48 = nvl(rtrim(in_hdrpassthruchar48),hdrpassthruchar48),
         hdrpassthruchar49 = nvl(rtrim(in_hdrpassthruchar49),hdrpassthruchar49),
         hdrpassthruchar50 = nvl(rtrim(strhdrpassthruchar50),hdrpassthruchar50),
         hdrpassthruchar51 = nvl(rtrim(in_hdrpassthruchar51),hdrpassthruchar51),
         hdrpassthruchar52 = nvl(rtrim(in_hdrpassthruchar52),hdrpassthruchar52),
         hdrpassthruchar53 = nvl(rtrim(in_hdrpassthruchar53),hdrpassthruchar53),
         hdrpassthruchar54 = nvl(rtrim(in_hdrpassthruchar54),hdrpassthruchar54),
         hdrpassthruchar55 = nvl(rtrim(in_hdrpassthruchar55),hdrpassthruchar55),
         hdrpassthruchar56 = nvl(rtrim(in_hdrpassthruchar56),hdrpassthruchar56),
         hdrpassthruchar57 = nvl(rtrim(in_hdrpassthruchar57),hdrpassthruchar57),
         hdrpassthruchar58 = nvl(rtrim(in_hdrpassthruchar58),hdrpassthruchar58),
         hdrpassthruchar59 = nvl(rtrim(in_hdrpassthruchar59),hdrpassthruchar59),
         hdrpassthruchar60 = nvl(rtrim(in_hdrpassthruchar60),hdrpassthruchar60),
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
         importfileid = nvl(upper(rtrim(in_importfileid)),importfileid),
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
         rfautodisplay = NVL(RTRIM(in_rfautodisplay),rfautodisplay),
         arrivaldate = NVL(dtearrivaldate,arrivaldate),
         prono = nvl(rtrim(in_prono), prono),
         editransaction = nvl(rtrim(in_editransaction),editransaction)
   where orderid = out_orderid
     and shipid = out_shipid;
elsif rtrim(in_func) = 'D' then
   update_cancel_importfileid(out_orderid, out_shipid, in_importfileid);
   zoe.cancel_order_request(out_orderid, out_shipid, oh.facility,
       'EDI',IMP_USERID, out_msg);
end if;
/*
out_msg := 'reached end-of-proc';
order_msg('I');
*/
out_msg := 'OKAY';
  if nvl(in_order_acknowledgment,'N') = 'Y' and
     rtrim(in_func) != 'D' then
     zimportprocs.log_order_import_ack(in_importfileid, in_custid, in_po , in_reference,
                                       out_orderid, out_shipid, 'A', '', in_func);
  end if;

exception when others then
  out_msg := 'zioh ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_header;

procedure import_order_line
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
,in_order_acknowledgment varchar2
,in_importfileid IN varchar2
,in_notnullpassthrus_yn IN varchar2
,in_delete_by_linenumber_yn in varchar2
,in_weight_acceptance_yn in varchar2
,in_dtl_passthru_item_xref in varchar2
,in_itm_passthru_item_xref in varchar2
,in_canceled_new_order in varchar2
,in_up_to_base_yn in varchar2
,in_style_color_size_columns IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr(in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         ordertype,
         shipto,
         shiptostate
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;

cursor curOrderHdr_not_canceled(in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         ordertype,
         shipto,
         shiptostate
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and orderstatus <> 'X'
   order by orderstatus;

cursor curOrderhdrHold(in_reference varchar2) is
   select orderid,
          shipid,
          orderstatus,
          fromfacility,
          tofacility,
          ordertype,
          shipto,
          shiptostate
     from orderhdr
    where custid = rtrim(in_custid)
      and reference = rtrim(in_reference)
      and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
    order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

cursor curOrderhdrHold_not_canceled(in_reference varchar2) is
   select orderid,
          shipid,
          orderstatus,
          fromfacility,
          tofacility,
          ordertype,
          shipto,
          shiptostate
     from orderhdr
    where custid = rtrim(in_custid)
      and reference = rtrim(in_reference)
      and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
    order by orderid desc, shipid desc;

cursor curCustomer is
  select nvl(linenumbersyn,'N') as linenumbersyn,
         nvl(recv_line_check_yn,'N') as recv_line_check_yn,
         nvl(dup_reference_ynw,'N') as dup_reference_ynw,
         nvl(bbb_routing_yn,'N') as bbb_routing_yn
    from customer cu, customer_aux ca
   where cu.custid = rtrim(in_custid)
     and cu.custid = ca.custid(+);
cs curCustomer%rowtype;

cursor curOrderDtl(in_itementered varchar2) is
  select *
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

cursor curOrderDtlLine(in_item varchar2, in_linenumber number) is
  select *
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = rtrim(in_item)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
     and linenumber = in_linenumber;
ol curOrderDtlLine%rowtype;

cursor curCustItem(in_item varchar2) is
  select civ.useramt1,
         civ.backorder,
         civ.allowsub,
         civ.invstatusind,
         civ.invstatus,
         civ.invclassind,
         civ.inventoryclass,
         civ.qtytype,
         civ.baseuom,
         ci.itmpassthruchar01,
         ci.itmpassthruchar02,
         ci.nmfc
    from custitemview civ, custitem ci
   where civ.custid = rtrim(in_custid)
     and civ.item = rtrim(in_item)
     and ci.custid = civ.custid
     and ci.item = civ.item;
ci curCustItem%rowtype;

chk orderdtlline%rowtype;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strItemEntered custitem.item%type;
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;
newItem custitem.item%type;
strLineNumbers char(1);
strInventoryclass orderdtl.inventoryclass%type;
dtedtlpassthrudate01 date;
dtedtlpassthrudate02 date;
dtedtlpassthrudate03 date;
dtedtlpassthrudate04 date;
l_comment long;
numQtyEntered orderdtl.qtyentered%type;
numWeightOrder orderdtl.weightorder%type;
numWeight_Entered_Lbs orderdtl.weight_entered_lbs%type;
numWeight_Entered_Kgs orderdtl.weight_entered_kgs%type;
Order_by_weight boolean;
cntEntered integer;
strReference orderhdr.reference%type;
strProductGroup custitem.productgroup%type;
strDtlPassThruChar01 orderdtl.dtlpassthruchar01%type;
strDtlPassThruChar03 orderdtl.dtlpassthruchar03%type;
strMsg varchar2(255);
strUpUOM orderdtl.uom%type;
upQty pls_integer;
chkstate orderhdr.shiptostate%type;
pos integer;
l_qty orderdtl.qtyentered%type;
l_nmfc_count pls_integer;
l_nmfc_msg varchar2(255);
l_log_msg varchar2(255);

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
strStatus char(1);
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  if nvl(in_order_acknowledgment,'N') = 'Y' then
     if in_msgtype = 'E' then
        strStatus := 'E';
     else
        strStatus := 'A';
     end if;
     zimportprocs.log_order_import_ack(in_importfileid, in_custid, in_po ,in_reference,
                                       out_orderid, out_shipid, strStatus, out_msg, in_func);
  end if;

end;

procedure update_header_carrier(in_orderid number,in_shipid number, in_header_carrier varchar2)
is pragma AUTONOMOUS_TRANSACTION;
begin
   update orderhdr                    -- for certain customers with abc revisions, the new carrier-- will be passed in the order line
      set carrier = in_header_carrier
      where orderid = in_orderid
        and shipid = in_shipid;
   commit;
exception when others then
  rollback;
end update_header_carrier;

FUNCTION get_item_from_custitem(in_dtl_passthru_item_xref in varchar2, in_itm_passthru_item_xref in varchar2)
RETURN varchar2
IS
  dtlItem varchar2(255);
  retItem custitem.item%type;
  cmdSql varchar2(2000);
  cnt integer;
begin
   retItem := in_itementered;
   case in_dtl_passthru_item_xref
      when '01' then dtlItem := in_dtlpassthruchar01;
      when '02' then dtlItem := in_dtlpassthruchar02;
      when '03' then dtlItem := in_dtlpassthruchar03;
      when '04' then dtlItem := in_dtlpassthruchar04;
      when '05' then dtlItem := in_dtlpassthruchar05;
      when '06' then dtlItem := in_dtlpassthruchar06;
      when '07' then dtlItem := in_dtlpassthruchar07;
      when '08' then dtlItem := in_dtlpassthruchar08;
      when '09' then dtlItem := in_dtlpassthruchar09;
      when '10' then dtlItem := in_dtlpassthruchar10;
      when '11' then dtlItem := in_dtlpassthruchar11;
      when '12' then dtlItem := in_dtlpassthruchar12;
      when '13' then dtlItem := in_dtlpassthruchar13;
      when '14' then dtlItem := in_dtlpassthruchar14;
      when '15' then dtlItem := in_dtlpassthruchar15;
      when '16' then dtlItem := in_dtlpassthruchar16;
      when '17' then dtlItem := in_dtlpassthruchar17;
      when '18' then dtlItem := in_dtlpassthruchar18;
      when '19' then dtlItem := in_dtlpassthruchar19;
      when '20' then dtlItem := in_dtlpassthruchar20;
      when '21' then dtlItem := in_dtlpassthruchar21;
      when '22' then dtlItem := in_dtlpassthruchar22;
      when '23' then dtlItem := in_dtlpassthruchar23;
      when '24' then dtlItem := in_dtlpassthruchar24;
      when '25' then dtlItem := in_dtlpassthruchar25;
      when '26' then dtlItem := in_dtlpassthruchar26;
      when '27' then dtlItem := in_dtlpassthruchar27;
      when '28' then dtlItem := in_dtlpassthruchar28;
      when '29' then dtlItem := in_dtlpassthruchar29;
      when '30' then dtlItem := in_dtlpassthruchar30;
      when '31' then dtlItem := in_dtlpassthruchar31;
      when '32' then dtlItem := in_dtlpassthruchar32;
      when '33' then dtlItem := in_dtlpassthruchar33;
      when '34' then dtlItem := in_dtlpassthruchar34;
      when '35' then dtlItem := in_dtlpassthruchar35;
      when '36' then dtlItem := in_dtlpassthruchar36;
      when '37' then dtlItem := in_dtlpassthruchar37;
      when '38' then dtlItem := in_dtlpassthruchar38;
      when '39' then dtlItem := in_dtlpassthruchar39;
      when '40' then dtlItem := in_dtlpassthruchar40;
      else dtlItem := in_itementered;
   end case;
   cmdSql := 'select item ' ||
               'from custitem ' ||
               'where itmpassthruchar' || in_itm_passthru_item_xref || ' = ''' || nvl(dtlItem,'(none)') || '''';
   execute immediate cmdSql into retItem;
   return retItem;

EXCEPTION WHEN OTHERS THEN
  return retItem;
end get_item_from_custitem;

procedure get_style_color_size_item(out_msg in out varchar2)
is
iStyle custitem.itmpassthruchar01%type;
iColor custitem.itmpassthruchar01%type;
iSize custitem.itmpassthruchar01%type;
styleColumn varchar2(32);
colorColumn varchar2(32);
sizeColumn varchar2(32);
pos1 pls_integer;
pos2 pls_integer;
   function get_value(in_column varchar2)
      return varchar2 is
   retval varchar2(32);
   begin
      retval := 'UNKNOWN';
      if in_column =  'in_dtlpassthruchar01' then
         retval := in_dtlpassthruchar01;
      elsif in_column = 'in_dtlpassthruchar02' then
         retval := in_dtlpassthruchar02;
      elsif in_column = 'in_dtlpassthruchar03' then
         retval := in_dtlpassthruchar03;
      elsif in_column = 'in_dtlpassthruchar04' then
         retval := in_dtlpassthruchar04;
      elsif in_column = 'in_dtlpassthruchar05' then
         retval := in_dtlpassthruchar05;
      elsif in_column = 'in_dtlpassthruchar06' then
         retval := in_dtlpassthruchar06;
      elsif in_column = 'in_dtlpassthruchar07' then
         retval := in_dtlpassthruchar07;
      elsif in_column = 'in_dtlpassthruchar08' then
         retval := in_dtlpassthruchar08;
      elsif in_column = 'in_dtlpassthruchar09' then
         retval := in_dtlpassthruchar09;
      elsif in_column = 'in_dtlpassthruchar10' then
         retval := in_dtlpassthruchar10;
      elsif in_column = 'in_dtlpassthruchar11' then
         retval := in_dtlpassthruchar11;
      elsif in_column = 'in_dtlpassthruchar12' then
         retval := in_dtlpassthruchar12;
      elsif in_column = 'in_dtlpassthruchar13' then
         retval := in_dtlpassthruchar13;
      elsif in_column = 'in_dtlpassthruchar14' then
         retval := in_dtlpassthruchar14;
      elsif in_column = 'in_dtlpassthruchar15' then
         retval := in_dtlpassthruchar15;
      elsif in_column = 'in_dtlpassthruchar16' then
         retval := in_dtlpassthruchar16;
      elsif in_column = 'in_dtlpassthruchar17' then
         retval := in_dtlpassthruchar17;
      elsif in_column = 'in_dtlpassthruchar18' then
         retval := in_dtlpassthruchar18;
      elsif in_column = 'in_dtlpassthruchar19' then
         retval := in_dtlpassthruchar19;
      elsif in_column = 'in_dtlpassthruchar20' then
         retval := in_dtlpassthruchar20;

      end if;

      return retval;
   end get_value;

begin
   -- valid values are in_passthruchar01 .. in_passthruchar10
   -- columns seperated by |
   -- example in_passthruchar05|in_passthruchar06|in_passthruchar07
   pos1 := instr(in_style_color_size_columns, '|');
   if pos1 = 0 then
      out_msg := 'Invalid format: in_style_color_size_columns ';
      return;
   end if;
   pos2 := instr(substr(in_style_color_size_columns, pos1 + 1), '|');
   if pos2 = 0 then
      out_msg := 'Invalid format: in_style_color_size_columns ';
      return;
   end if;

   styleColumn := substr(in_style_color_size_columns, 1, pos1 - 1);
   colorColumn := substr(in_style_color_size_columns, pos1 + 1, pos2 - 1);
   sizeColumn := substr(in_style_color_size_columns, pos1 + pos2 + 1);

   iStyle := get_value(styleColumn);
   if iStyle = 'UNKNOWN'  then
      out_msg := 'Invalid column for style ' || styleColumn;
      return;
   end if;
   iColor := get_value(colorColumn);
   if icolor = 'UNKNOWN'  then
      out_msg := 'Invalid column for color ' || colorColumn;
      return;
   end if;
   iSize := get_value(sizeColumn);
   if iSize = 'UNKNOWN'  then
      out_msg := 'Invalid column for size ' || sizeColumn;
      return;
   end if;
   if length(iStyle) + length(iColor) + length(iSize) + 2 > 50 then
      out_msg := 'Data too long ' || iStyle || '+' || iColor || '+' || iSize;
      return;
   end if;
   strItemEntered := iStyle || '-' || iColor || '-' || iSize;

end get_style_color_size_item;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

if nvl(rtrim(in_func),'x') = 'E' then
   in_func := 'A';
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code: ' || nvl(in_func,'null');
  item_msg('E');
  return;
end if;

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.linenumbersyn := 'N';
  cs.dup_reference_ynw := 'N';
  cs.bbb_routing_yn := 'N';
end if;
close curCustomer;
if nvl(in_canceled_new_order, 'N') = 'Y' then
   if cs.dup_reference_ynw = 'H' then
      open curOrderhdrHold_not_canceled(strReference);
      fetch curOrderhdrHold_not_canceled into oh;
      if curOrderhdrHold_not_canceled%found then
        out_orderid := oh.orderid;
        out_shipid := oh.shipid;
      end if;
      close curOrderhdrHold_not_canceled;
   else
      open curOrderhdr_not_canceled(strReference);
      fetch curOrderhdr_not_canceled into oh;
      if curOrderHdr_not_canceled%found then
        out_orderid := oh.orderid;
        out_shipid := oh.shipid;
      end if;
      close curOrderhdr_not_canceled;
   end if;
else
   if cs.dup_reference_ynw = 'H' then
      open curOrderhdrHold(strReference);
      fetch curOrderhdrHold into oh;
      if curOrderhdrHold%found then
        out_orderid := oh.orderid;
        out_shipid := oh.shipid;
      end if;
      close curOrderhdrHold;
   else
      open curOrderhdr(strReference);
      fetch curOrderhdr into oh;
      if curOrderHdr%found then
        out_orderid := oh.orderid;
        out_shipid := oh.shipid;
      end if;
      close curOrderhdr;
   end if;
end if;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  item_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  item_msg('E');
  return;
end if;
newItem := in_itementered;
if in_dtl_passthru_item_xref is not null and
   in_itm_passthru_item_xref is not null then
   newItem := get_item_from_custitem(in_dtl_passthru_item_xref, in_itm_passthru_item_xref);
end if;

if nvl(in_upper_item_yn, 'N') = 'Y' then
  newItem := upper(newItem);
end if;

if in_style_color_size_columns is not null then
   get_style_color_size_item(out_msg);
   if out_msg is not null then
      out_errorno := 11;
      item_msg('E');
      return;
   end if;
end if;

od := null;
open curOrderDtl(newItem);
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
    out_msg := 'Order-item to be cancelled not found';
    item_msg('E');
    return;
  end if;
  if od.linestatus = 'X' then
    out_errorno := 4;
    out_msg := 'Order-item already cancelled';
    item_msg('E');
    return;
  end if;
  if nvl(rtrim(in_delete_by_linenumber_yn),'N') = 'Y' then
    open curOrderDtlLine(strItem,in_dtlpassthrunum10);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      chk.linenumber := in_dtlpassthrunum10;
    end if;
    close curOrderDtlLine;
    if chk.linenumber is null then
      out_errorno := 4;
      out_msg := 'Order-line not found/already cancelled';
      item_msg('E');
      return;
    end if;
  end if;
end if;

strItemEntered := newItem;

zci.get_customer_item(rtrim(in_custid),rtrim(strItemEntered),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := strItemEntered;
end if;

numQtyEntered := nvl(in_qtyentered,0);
numWeight_Entered_Lbs := nvl(in_weight_entered_lbs,0);
numWeight_Entered_Kgs := nvl(in_weight_entered_kgs,0);

olc.count := 0;

if ( (oh.ordertype in ('O','V')) and (cs.linenumbersyn = 'Y') ) or
   ( (oh.ordertype in ('R','Q','P','A','C','I')) and (cs.recv_line_check_yn != 'N') ) then
  strLineNumbers := 'Y';
else
  strLineNumbers := 'N';
end if;

if strLineNumbers = 'Y' then
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
    open curOrderDtlLine(strItem,in_dtlpassthrunum10);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      chk.linenumber := in_dtlpassthrunum10;
    end if;
    close curOrderDtlLine;
  else
    if od.dtlpassthrunum10 = in_dtlpassthrunum10 then
      chk.linenumber := od.dtlpassthrunum10;
    end if;
  end if;
end if;

if rtrim(in_func) in ('A','R') then
  if ( (strLineNumbers != 'Y') and (chk.item is not null) ) or
     ( (strLineNumbers = 'Y') and (chk.linenumber is not null) ) then
    out_msg := 'Add requested--order-line already on file--update performed';
    item_msg('W');
    in_func := 'U';
  end if;
elsif rtrim(in_func) = 'U' then
  if ( (strLineNumbers != 'Y') and (chk.item is null) ) or
     ( (strLineNumbers = 'Y') and (chk.linenumber is null) ) then
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
else
  l_nmfc_count := 0;
  begin
    select count(1)
      into l_nmfc_count
      from nmfclasscodes
     where nmfc = ci.nmfc;
  exception when others then
    l_nmfc_count := 0;
  end;
  if (l_nmfc_count = 0) then
    l_nmfc_msg := 'Invalid NMFC code for Cust/Item ' || in_custid || '/' ||
                   strItem || '(' || rtrim(ci.nmfc) || ')';
    zms.log_autonomous_msg(
      in_author   => 'NMFC',
      in_facility => oh.fromfacility,
      in_custid   => in_custid,
      in_msgtext  => l_nmfc_msg,
      in_msgtype  => 'W',
      in_userid   => 'IMPEXP',
      out_msg     => l_log_msg);
  end if;
end if;

if rtrim(nvl(in_notnullpassthrus_yn,'N')) = 'Y' then
  strDtlPassThruChar01 := nvl(rtrim(in_dtlpassthruchar01), rtrim(ci.itmpassthruchar01));
  strDtlPassThruChar03 := nvl(rtrim(in_dtlpassthruchar03), rtrim(ci.itmpassthruchar02));
else
  strDtlPassThruChar01 := rtrim(in_dtlpassthruchar01);
  strDtlPassThruChar03 := rtrim(in_dtlpassthruchar03);
end if;

if (numQtyEntered = 0) and
   (numWeight_Entered_Lbs <> 0 or numWeight_Entered_Kgs <> 0) then
   Order_by_Weight := True;
else
   if (numQtyEntered <> 0) and
      (numWeight_Entered_Lbs <> 0 or numWeight_Entered_Kgs <> 0) and
      (nvl(in_weight_acceptance_yn,'N') = 'Y') then
      out_msg := '';
      Order_by_Weight := True;
   else
      Order_by_Weight := False;
      out_msg := '';
   end if;
end if;
cntEntered := 0;

if nvl(numQtyEntered,0) != 0 then
  cntEntered := cntEntered + 1;
end if;
if nvl(numWeight_Entered_Lbs,0) != 0 then
  cntEntered := cntEntered + 1;
end if;
if nvl(numWeight_Entered_Kgs,0) != 0 then
  cntEntered := cntEntered + 1;
end if;

if cntEntered = 1 then
  if numQtyEntered = 0 then
    numQtyEntered := null;
  end if;
  if numWeight_Entered_Lbs = 0 then
    numWeight_Entered_Lbs := null;
  end if;
  if numWeight_Entered_Kgs = 0 then
    numWeight_Entered_Kgs := null;
  end if;
end if;
numWeightOrder := zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered;
strUpUom := null;
if (Order_by_Weight) then
  if nvl(in_weight_acceptance_yn,'N') = 'Y' then
     qtyBase := numQtyEntered;
     numWeightOrder := nvl(numWeight_Entered_Lbs,numWeight_Entered_Kgs);
  else
     qtyBase :=
    zwt.calc_order_by_weight_qty(in_custid,strItem,ci.baseuom,
                                 numWeight_Entered_Lbs,numWeight_Entered_Kgs,
                                 nvl(rtrim(in_qtytype),ci.qtytype));
  end if;
  strUOMBase := ci.baseuom;
else
  if nvl(in_up_to_base_yn, 'N') = 'Y' then
     zoe.get_base_uom_equivalent_up(rtrim(in_custid),rtrim(strItemEntered),
                                 nvl(rtrim(in_uomentered),ci.baseuom),
                                 numQtyEntered,strItem,strUOMBase,qtyBase, strUpUOM, upQty, out_msg);
     if substr(out_msg,1,4) != 'OKAY' then
       strItem := rtrim(strItemEntered);
       strUOMBase :=  nvl(rtrim(in_uomentered),ci.baseuom);
       qtyBase := numQtyEntered;
       strUpUom := null;
     else
        numQtyEntered := upQty;
     end if;
  else
    zoe.get_base_uom_equivalent(rtrim(in_custid),rtrim(strItemEntered),
                              nvl(rtrim(in_uomentered),ci.baseuom),
                              numQtyEntered,strItem,strUOMBase,qtyBase,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      strItem := rtrim(strItemEntered);
      strUOMBase :=  nvl(rtrim(in_uomentered),ci.baseuom);
      qtyBase := numQtyEntered;
    end if;
  end if;
end if;

if in_header_carrier is not null then
   update_header_carrier(out_orderid, out_shipid, in_header_carrier);
end if;

strInventoryclass := in_inventoryclass;
if in_invclass_states is not null and
   in_invclass_states_value is not null then
   if oh.shipto is not null then
      begin
         select state into chkState
            from consignee
            where consignee = oh.shipto;
      exception when NO_DATA_FOUND then
         chkState := null;
      end;
   else
      chkState := oh.shiptostate;
   end if;
   if chkState is not null then
      pos := instr(in_invclass_states,chkState,1,1);
      if pos > 0 then
         strInventoryclass := in_invclass_states_value;
      end if;
end if;
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
    dtlpassthruchar21, dtlpassthruchar22, dtlpassthruchar23, dtlpassthruchar24,
    dtlpassthruchar25, dtlpassthruchar26, dtlpassthruchar27, dtlpassthruchar28,
    dtlpassthruchar29, dtlpassthruchar30, dtlpassthruchar31, dtlpassthruchar32,
    dtlpassthruchar33, dtlpassthruchar34, dtlpassthruchar35, dtlpassthruchar36,
    dtlpassthruchar37, dtlpassthruchar38, dtlpassthruchar39, dtlpassthruchar40,
    dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
    dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
    dtlpassthrunum09, dtlpassthrunum10,
    dtlpassthrunum11, dtlpassthrunum12, dtlpassthrunum13, dtlpassthrunum14, dtlpassthrunum15,
    dtlpassthrunum16, dtlpassthrunum17, dtlpassthrunum18, dtlpassthrunum19, dtlpassthrunum20,
    dtlpassthrudate01, dtlpassthrudate02,
    dtlpassthrudate03, dtlpassthrudate04,
    dtlpassthrudoll01, dtlpassthrudoll02,
    rfautodisplay, comment1, weight_entered_lbs, weight_entered_kgs,
    variancepct, variancepct_overage, variancepct_use_default, lineorder
    )
    values
    (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),strUOMBase,'A',
     numQtyEntered,rtrim(strItemEntered), nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom)),
     qtyBase,
     numWeightOrder,
     zci.item_cube(rtrim(in_custid),strItem,nvl(strUpUOM,nvl(rtrim(in_uomentered),ci.baseuom))) * numQtyEntered,
     qtyBase*ci.useramt1,IMP_USERID,sysdate,
     nvl(rtrim(in_backorder),ci.backorder),nvl(rtrim(in_allowsub),ci.allowsub),
     nvl(rtrim(in_qtytype),ci.qtytype),nvl(rtrim(in_invstatusind),ci.invstatusind),
     nvl(rtrim(in_invstatus),ci.invstatus),nvl(rtrim(in_invclassind),ci.invclassind),
     nvl(rtrim(strInventoryclass),ci.inventoryclass),rtrim(in_consigneesku),
     IMP_USERID,
     strDtlPassThruChar01,rtrim(in_dtlpassthruchar02),
     strDtlPassThruChar03,rtrim(in_dtlpassthruchar04),
     rtrim(in_dtlpassthruchar05),rtrim(in_dtlpassthruchar06),
     rtrim(in_dtlpassthruchar07),rtrim(in_dtlpassthruchar08),
     rtrim(in_dtlpassthruchar09),rtrim(in_dtlpassthruchar10),
     rtrim(in_dtlpassthruchar11),rtrim(in_dtlpassthruchar12),
     rtrim(in_dtlpassthruchar13),rtrim(in_dtlpassthruchar14),
     rtrim(in_dtlpassthruchar15),rtrim(in_dtlpassthruchar16),
     rtrim(in_dtlpassthruchar17),rtrim(in_dtlpassthruchar18),
     rtrim(in_dtlpassthruchar19),rtrim(in_dtlpassthruchar20),
     rtrim(in_dtlpassthruchar21),rtrim(in_dtlpassthruchar22),
     rtrim(in_dtlpassthruchar23),rtrim(in_dtlpassthruchar24),
     rtrim(in_dtlpassthruchar25),rtrim(in_dtlpassthruchar26),
     rtrim(in_dtlpassthruchar27),rtrim(in_dtlpassthruchar28),
     rtrim(in_dtlpassthruchar29),rtrim(in_dtlpassthruchar30),
     rtrim(in_dtlpassthruchar31),rtrim(in_dtlpassthruchar32),
     rtrim(in_dtlpassthruchar33),rtrim(in_dtlpassthruchar34),
     rtrim(in_dtlpassthruchar35),rtrim(in_dtlpassthruchar36),
     rtrim(in_dtlpassthruchar37),rtrim(in_dtlpassthruchar38),
     rtrim(in_dtlpassthruchar39),rtrim(in_dtlpassthruchar40),
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
     decode(in_dtlpassthrunum11,0,null,in_dtlpassthrunum11),
     decode(in_dtlpassthrunum12,0,null,in_dtlpassthrunum12),
     decode(in_dtlpassthrunum13,0,null,in_dtlpassthrunum13),
     decode(in_dtlpassthrunum14,0,null,in_dtlpassthrunum14),
     decode(in_dtlpassthrunum15,0,null,in_dtlpassthrunum15),
     decode(in_dtlpassthrunum16,0,null,in_dtlpassthrunum16),
     decode(in_dtlpassthrunum17,0,null,in_dtlpassthrunum17),
     decode(in_dtlpassthrunum18,0,null,in_dtlpassthrunum18),
     decode(in_dtlpassthrunum19,0,null,in_dtlpassthrunum19),
     decode(in_dtlpassthrunum20,0,null,in_dtlpassthrunum20),
     dtedtlpassthrudate01, dtedtlpassthrudate02,
     dtedtlpassthrudate03, dtedtlpassthrudate04,
     decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
     decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
     in_rfautodisplay, in_comment, numWeight_Entered_lbs, numWeight_Entered_kgs,
     in_variance_pct_shortage, in_variance_pct_overage, in_variance_use_default_yn, in_lineorder
     );

     -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
     -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
     update orderdtl
     set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = nvl(strItem,' ')
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');

     if strLineNumbers = 'Y' then
        insert into orderdtlline
         (orderid,shipid,item,lotnumber,
          linenumber,qty,
          dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
          dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
          dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
          dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
          dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
          dtlpassthruchar21, dtlpassthruchar22, dtlpassthruchar23, dtlpassthruchar24,
          dtlpassthruchar25, dtlpassthruchar26, dtlpassthruchar27, dtlpassthruchar28,
          dtlpassthruchar29, dtlpassthruchar30, dtlpassthruchar31, dtlpassthruchar32,
          dtlpassthruchar33, dtlpassthruchar34, dtlpassthruchar35, dtlpassthruchar36,
          dtlpassthruchar37, dtlpassthruchar38, dtlpassthruchar39, dtlpassthruchar40,
          dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
          dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
          dtlpassthrunum09, dtlpassthrunum10,
          dtlpassthrunum11, dtlpassthrunum12, dtlpassthrunum13, dtlpassthrunum14, dtlpassthrunum15,
          dtlpassthrunum16, dtlpassthrunum17, dtlpassthrunum18, dtlpassthrunum19, dtlpassthrunum20,
          DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
          DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
          lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs
         )
         values
         (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
          in_dtlpassthrunum10,qtyBase,
          decode(nvl(od.dtlpassthruchar01,'x'),nvl(strDtlPassThruChar01,'x'),
            od.dtlpassthruchar01,nvl(strDtlPassThruChar01,' ')),
          decode(nvl(od.dtlpassthruchar02,'x'),nvl(rtrim(in_dtlpassthruchar02),'x'),
            od.dtlpassthruchar02,nvl(rtrim(in_dtlpassthruchar02),' ')),
          decode(nvl(od.dtlpassthruchar03,'x'),nvl(strDtlPassThruChar03,'x'),
            od.dtlpassthruchar03,nvl(strDtlPassThruChar03,' ')),
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
          decode(nvl(od.dtlpassthruchar21,'x'),nvl(rtrim(in_dtlpassthruchar21),'x'),
            od.dtlpassthruchar21,nvl(rtrim(in_dtlpassthruchar21),' ')),
          decode(nvl(od.dtlpassthruchar22,'x'),nvl(rtrim(in_dtlpassthruchar22),'x'),
            od.dtlpassthruchar22,nvl(rtrim(in_dtlpassthruchar22),' ')),
          decode(nvl(od.dtlpassthruchar23,'x'),nvl(rtrim(in_dtlpassthruchar23),'x'),
            od.dtlpassthruchar23,nvl(rtrim(in_dtlpassthruchar23),' ')),
          decode(nvl(od.dtlpassthruchar24,'x'),nvl(rtrim(in_dtlpassthruchar24),'x'),
            od.dtlpassthruchar24,nvl(rtrim(in_dtlpassthruchar24),' ')),
          decode(nvl(od.dtlpassthruchar25,'x'),nvl(rtrim(in_dtlpassthruchar25),'x'),
            od.dtlpassthruchar25,nvl(rtrim(in_dtlpassthruchar25),' ')),
          decode(nvl(od.dtlpassthruchar26,'x'),nvl(rtrim(in_dtlpassthruchar26),'x'),
            od.dtlpassthruchar26,nvl(rtrim(in_dtlpassthruchar26),' ')),
          decode(nvl(od.dtlpassthruchar27,'x'),nvl(rtrim(in_dtlpassthruchar27),'x'),
            od.dtlpassthruchar27,nvl(rtrim(in_dtlpassthruchar27),' ')),
          decode(nvl(od.dtlpassthruchar28,'x'),nvl(rtrim(in_dtlpassthruchar28),'x'),
            od.dtlpassthruchar28,nvl(rtrim(in_dtlpassthruchar28),' ')),
          decode(nvl(od.dtlpassthruchar29,'x'),nvl(rtrim(in_dtlpassthruchar29),'x'),
            od.dtlpassthruchar29,nvl(rtrim(in_dtlpassthruchar29),' ')),
          decode(nvl(od.dtlpassthruchar30,'x'),nvl(rtrim(in_dtlpassthruchar30),'x'),
            od.dtlpassthruchar30,nvl(rtrim(in_dtlpassthruchar30),' ')),
          decode(nvl(od.dtlpassthruchar31,'x'),nvl(rtrim(in_dtlpassthruchar31),'x'),
            od.dtlpassthruchar31,nvl(rtrim(in_dtlpassthruchar31),' ')),
          decode(nvl(od.dtlpassthruchar32,'x'),nvl(rtrim(in_dtlpassthruchar32),'x'),
            od.dtlpassthruchar32,nvl(rtrim(in_dtlpassthruchar32),' ')),
          decode(nvl(od.dtlpassthruchar33,'x'),nvl(rtrim(in_dtlpassthruchar33),'x'),
            od.dtlpassthruchar33,nvl(rtrim(in_dtlpassthruchar33),' ')),
          decode(nvl(od.dtlpassthruchar34,'x'),nvl(rtrim(in_dtlpassthruchar34),'x'),
            od.dtlpassthruchar34,nvl(rtrim(in_dtlpassthruchar34),' ')),
          decode(nvl(od.dtlpassthruchar35,'x'),nvl(rtrim(in_dtlpassthruchar35),'x'),
            od.dtlpassthruchar35,nvl(rtrim(in_dtlpassthruchar35),' ')),
          decode(nvl(od.dtlpassthruchar36,'x'),nvl(rtrim(in_dtlpassthruchar36),'x'),
            od.dtlpassthruchar36,nvl(rtrim(in_dtlpassthruchar36),' ')),
          decode(nvl(od.dtlpassthruchar37,'x'),nvl(rtrim(in_dtlpassthruchar37),'x'),
            od.dtlpassthruchar37,nvl(rtrim(in_dtlpassthruchar37),' ')),
          decode(nvl(od.dtlpassthruchar38,'x'),nvl(rtrim(in_dtlpassthruchar38),'x'),
            od.dtlpassthruchar38,nvl(rtrim(in_dtlpassthruchar38),' ')),
          decode(nvl(od.dtlpassthruchar39,'x'),nvl(rtrim(in_dtlpassthruchar39),'x'),
            od.dtlpassthruchar39,nvl(rtrim(in_dtlpassthruchar39),' ')),
          decode(nvl(od.dtlpassthruchar40,'x'),nvl(rtrim(in_dtlpassthruchar40),'x'),
            od.dtlpassthruchar40,nvl(rtrim(in_dtlpassthruchar40),' ')),
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
          decode(nvl(od.dtlpassthrunum11,0),nvl(in_dtlpassthrunum11,0),
            od.dtlpassthrunum11,nvl(in_dtlpassthrunum11,0)),
          decode(nvl(od.dtlpassthrunum12,0),nvl(in_dtlpassthrunum12,0),
            od.dtlpassthrunum12,nvl(in_dtlpassthrunum12,0)),
          decode(nvl(od.dtlpassthrunum13,0),nvl(in_dtlpassthrunum13,0),
            od.dtlpassthrunum13,nvl(in_dtlpassthrunum13,0)),
          decode(nvl(od.dtlpassthrunum14,0),nvl(in_dtlpassthrunum14,0),
            od.dtlpassthrunum14,nvl(in_dtlpassthrunum14,0)),
          decode(nvl(od.dtlpassthrunum15,0),nvl(in_dtlpassthrunum15,0),
            od.dtlpassthrunum15,nvl(in_dtlpassthrunum15,0)),
          decode(nvl(od.dtlpassthrunum16,0),nvl(in_dtlpassthrunum16,0),
            od.dtlpassthrunum16,nvl(in_dtlpassthrunum16,0)),
          decode(nvl(od.dtlpassthrunum17,0),nvl(in_dtlpassthrunum17,0),
            od.dtlpassthrunum17,nvl(in_dtlpassthrunum17,0)),
          decode(nvl(od.dtlpassthrunum18,0),nvl(in_dtlpassthrunum18,0),
            od.dtlpassthrunum18,nvl(in_dtlpassthrunum18,0)),
          decode(nvl(od.dtlpassthrunum19,0),nvl(in_dtlpassthrunum19,0),
            od.dtlpassthrunum19,nvl(in_dtlpassthrunum19,0)),
          decode(nvl(od.dtlpassthrunum20,0),nvl(in_dtlpassthrunum20,0),
            od.dtlpassthrunum20,nvl(in_dtlpassthrunum20,0)),
          dtedtlpassthrudate01, dtedtlpassthrudate02,
          dtedtlpassthrudate03, dtedtlpassthrudate04,
          decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
          decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
          IMP_USERID, sysdate, numWeight_Entered_lbs, numWeight_Entered_kgs
         );
     end if;
  else
    if strLineNumbers = 'Y' then
      if olc.count = 0 then --add line record for item info that is already on file
        insert into orderdtlline
         (orderid,shipid,item,lotnumber,
          linenumber,qty,
          dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
          dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
          dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
          dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
          dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
          dtlpassthruchar21, dtlpassthruchar22, dtlpassthruchar23, dtlpassthruchar24,
          dtlpassthruchar25, dtlpassthruchar26, dtlpassthruchar27, dtlpassthruchar28,
          dtlpassthruchar29, dtlpassthruchar30, dtlpassthruchar31, dtlpassthruchar32,
          dtlpassthruchar33, dtlpassthruchar34, dtlpassthruchar35, dtlpassthruchar36,
          dtlpassthruchar37, dtlpassthruchar38, dtlpassthruchar39, dtlpassthruchar40,
          dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
          dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
          dtlpassthrunum09, dtlpassthrunum10,
          dtlpassthrunum11, dtlpassthrunum12, dtlpassthrunum13, dtlpassthrunum14, dtlpassthrunum15,
          dtlpassthrunum16, dtlpassthrunum17, dtlpassthrunum18, dtlpassthrunum19, dtlpassthrunum20,
          DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
          DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
          QTYAPPROVED, lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs
         )
         values
         (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
          od.dtlpassthrunum10,od.qtyorder,
          od.dtlpassthruchar01, od.dtlpassthruchar02, od.dtlpassthruchar03, od.dtlpassthruchar04,
          od.dtlpassthruchar05, od.dtlpassthruchar06, od.dtlpassthruchar07, od.dtlpassthruchar08,
          od.dtlpassthruchar09, od.dtlpassthruchar10, od.dtlpassthruchar11, od.dtlpassthruchar12,
          od.dtlpassthruchar13, od.dtlpassthruchar14, od.dtlpassthruchar15, od.dtlpassthruchar16,
          od.dtlpassthruchar17, od.dtlpassthruchar18, od.dtlpassthruchar19, od.dtlpassthruchar20,
          od.dtlpassthruchar21, od.dtlpassthruchar22, od.dtlpassthruchar23, od.dtlpassthruchar24,
          od.dtlpassthruchar25, od.dtlpassthruchar26, od.dtlpassthruchar27, od.dtlpassthruchar28,
          od.dtlpassthruchar29, od.dtlpassthruchar30, od.dtlpassthruchar31, od.dtlpassthruchar32,
          od.dtlpassthruchar33,
          od.dtlpassthruchar34, od.dtlpassthruchar35, od.dtlpassthruchar36,
          od.dtlpassthruchar37, od.dtlpassthruchar38, od.dtlpassthruchar39, od.dtlpassthruchar40,
          od.dtlpassthrunum01, od.dtlpassthrunum02, od.dtlpassthrunum03, od.dtlpassthrunum04,
          od.dtlpassthrunum05, od.dtlpassthrunum06, od.dtlpassthrunum07, od.dtlpassthrunum08,
          od.dtlpassthrunum09, od.dtlpassthrunum10,
          od.dtlpassthrunum11, od.dtlpassthrunum12, od.dtlpassthrunum13, od.dtlpassthrunum14, od.dtlpassthrunum15,
          od.dtlpassthrunum16, od.dtlpassthrunum17, od.dtlpassthrunum18, od.dtlpassthrunum19, od.dtlpassthrunum20,
          od.DTLPASSTHRUDATE01,od.DTLPASSTHRUDATE02,
          od.DTLPASSTHRUDATE03,od.DTLPASSTHRUDATE04,od.DTLPASSTHRUDOLL01,od.DTLPASSTHRUDOLL02,
          null, IMP_USERID, sysdate, od.weight_entered_lbs, od.weight_entered_kgs
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
        dtlpassthruchar21, dtlpassthruchar22, dtlpassthruchar23, dtlpassthruchar24,
        dtlpassthruchar25, dtlpassthruchar26, dtlpassthruchar27, dtlpassthruchar28,
        dtlpassthruchar29, dtlpassthruchar30, dtlpassthruchar31, dtlpassthruchar32,
        dtlpassthruchar33, dtlpassthruchar34, dtlpassthruchar35, dtlpassthruchar36,
        dtlpassthruchar37, dtlpassthruchar38, dtlpassthruchar39, dtlpassthruchar40,
        dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
        dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
        dtlpassthrunum09, dtlpassthrunum10,
        dtlpassthrunum11, dtlpassthrunum12, dtlpassthrunum13, dtlpassthrunum14, dtlpassthrunum15,
        dtlpassthrunum16, dtlpassthrunum17, dtlpassthrunum18, dtlpassthrunum19, dtlpassthrunum20,
        DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
        DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
        lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs
       )
       values
       (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
        in_dtlpassthrunum10,qtyBase,
        decode(nvl(od.dtlpassthruchar01,'x'),nvl(strDtlPassThruChar01,'x'),
          od.dtlpassthruchar01,nvl(strDtlPassThruChar01,' ')),
        decode(nvl(od.dtlpassthruchar02,'x'),nvl(rtrim(in_dtlpassthruchar02),'x'),
          od.dtlpassthruchar02,nvl(rtrim(in_dtlpassthruchar02),' ')),
        decode(nvl(od.dtlpassthruchar03,'x'),nvl(strDtlPassThruChar03,'x'),
          od.dtlpassthruchar03,nvl(strDtlPassThruChar03,' ')),
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
        decode(nvl(od.dtlpassthruchar21,'x'),nvl(rtrim(in_dtlpassthruchar21),'x'),
          od.dtlpassthruchar21,nvl(rtrim(in_dtlpassthruchar21),' ')),
        decode(nvl(od.dtlpassthruchar22,'x'),nvl(rtrim(in_dtlpassthruchar22),'x'),
          od.dtlpassthruchar22,nvl(rtrim(in_dtlpassthruchar22),' ')),
        decode(nvl(od.dtlpassthruchar23,'x'),nvl(rtrim(in_dtlpassthruchar23),'x'),
          od.dtlpassthruchar23,nvl(rtrim(in_dtlpassthruchar23),' ')),
        decode(nvl(od.dtlpassthruchar24,'x'),nvl(rtrim(in_dtlpassthruchar24),'x'),
          od.dtlpassthruchar24,nvl(rtrim(in_dtlpassthruchar24),' ')),
        decode(nvl(od.dtlpassthruchar25,'x'),nvl(rtrim(in_dtlpassthruchar25),'x'),
          od.dtlpassthruchar25,nvl(rtrim(in_dtlpassthruchar25),' ')),
        decode(nvl(od.dtlpassthruchar26,'x'),nvl(rtrim(in_dtlpassthruchar26),'x'),
          od.dtlpassthruchar26,nvl(rtrim(in_dtlpassthruchar26),' ')),
        decode(nvl(od.dtlpassthruchar27,'x'),nvl(rtrim(in_dtlpassthruchar27),'x'),
          od.dtlpassthruchar27,nvl(rtrim(in_dtlpassthruchar27),' ')),
        decode(nvl(od.dtlpassthruchar28,'x'),nvl(rtrim(in_dtlpassthruchar28),'x'),
          od.dtlpassthruchar28,nvl(rtrim(in_dtlpassthruchar28),' ')),
        decode(nvl(od.dtlpassthruchar29,'x'),nvl(rtrim(in_dtlpassthruchar29),'x'),
          od.dtlpassthruchar29,nvl(rtrim(in_dtlpassthruchar29),' ')),
        decode(nvl(od.dtlpassthruchar30,'x'),nvl(rtrim(in_dtlpassthruchar30),'x'),
          od.dtlpassthruchar30,nvl(rtrim(in_dtlpassthruchar30),' ')),
        decode(nvl(od.dtlpassthruchar31,'x'),nvl(rtrim(in_dtlpassthruchar31),'x'),
          od.dtlpassthruchar31,nvl(rtrim(in_dtlpassthruchar31),' ')),
        decode(nvl(od.dtlpassthruchar32,'x'),nvl(rtrim(in_dtlpassthruchar32),'x'),
          od.dtlpassthruchar32,nvl(rtrim(in_dtlpassthruchar32),' ')),
        decode(nvl(od.dtlpassthruchar33,'x'),nvl(rtrim(in_dtlpassthruchar33),'x'),
          od.dtlpassthruchar33,nvl(rtrim(in_dtlpassthruchar33),' ')),
        decode(nvl(od.dtlpassthruchar34,'x'),nvl(rtrim(in_dtlpassthruchar34),'x'),
          od.dtlpassthruchar34,nvl(rtrim(in_dtlpassthruchar34),' ')),
        decode(nvl(od.dtlpassthruchar35,'x'),nvl(rtrim(in_dtlpassthruchar35),'x'),
          od.dtlpassthruchar35,nvl(rtrim(in_dtlpassthruchar35),' ')),
        decode(nvl(od.dtlpassthruchar36,'x'),nvl(rtrim(in_dtlpassthruchar36),'x'),
          od.dtlpassthruchar36,nvl(rtrim(in_dtlpassthruchar36),' ')),
        decode(nvl(od.dtlpassthruchar37,'x'),nvl(rtrim(in_dtlpassthruchar37),'x'),
          od.dtlpassthruchar37,nvl(rtrim(in_dtlpassthruchar37),' ')),
        decode(nvl(od.dtlpassthruchar38,'x'),nvl(rtrim(in_dtlpassthruchar38),'x'),
          od.dtlpassthruchar38,nvl(rtrim(in_dtlpassthruchar38),' ')),
        decode(nvl(od.dtlpassthruchar39,'x'),nvl(rtrim(in_dtlpassthruchar39),'x'),
          od.dtlpassthruchar39,nvl(rtrim(in_dtlpassthruchar39),' ')),
        decode(nvl(od.dtlpassthruchar40,'x'),nvl(rtrim(in_dtlpassthruchar40),'x'),
          od.dtlpassthruchar40,nvl(rtrim(in_dtlpassthruchar40),' ')),
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
        decode(nvl(od.dtlpassthrunum11,0),nvl(in_dtlpassthrunum11,0),
          od.dtlpassthrunum11,nvl(in_dtlpassthrunum11,0)),
        decode(nvl(od.dtlpassthrunum12,0),nvl(in_dtlpassthrunum12,0),
          od.dtlpassthrunum12,nvl(in_dtlpassthrunum12,0)),
        decode(nvl(od.dtlpassthrunum13,0),nvl(in_dtlpassthrunum13,0),
          od.dtlpassthrunum13,nvl(in_dtlpassthrunum13,0)),
        decode(nvl(od.dtlpassthrunum14,0),nvl(in_dtlpassthrunum14,0),
          od.dtlpassthrunum14,nvl(in_dtlpassthrunum14,0)),
        decode(nvl(od.dtlpassthrunum15,0),nvl(in_dtlpassthrunum15,0),
          od.dtlpassthrunum15,nvl(in_dtlpassthrunum15,0)),
        decode(nvl(od.dtlpassthrunum16,0),nvl(in_dtlpassthrunum16,0),
          od.dtlpassthrunum16,nvl(in_dtlpassthrunum16,0)),
        decode(nvl(od.dtlpassthrunum17,0),nvl(in_dtlpassthrunum17,0),
          od.dtlpassthrunum17,nvl(in_dtlpassthrunum17,0)),
        decode(nvl(od.dtlpassthrunum18,0),nvl(in_dtlpassthrunum18,0),
          od.dtlpassthrunum18,nvl(in_dtlpassthrunum18,0)),
        decode(nvl(od.dtlpassthrunum19,0),nvl(in_dtlpassthrunum19,0),
          od.dtlpassthrunum19,nvl(in_dtlpassthrunum19,0)),
        decode(nvl(od.dtlpassthrunum20,0),nvl(in_dtlpassthrunum20,0),
          od.dtlpassthrunum20,nvl(in_dtlpassthrunum20,0)),
        dtedtlpassthrudate01, dtedtlpassthrudate02,
        dtedtlpassthrudate03, dtedtlpassthrudate04,
        decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
        decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
        IMP_USERID, sysdate, numWeight_Entered_lbs, numWeight_Entered_kgs
       );
    end if;
    update orderdtl
       set qtyentered = qtyentered + numQtyEntered,
           qtyorder = qtyorder + qtyBase,
           weightorder = weightorder
             + numWeightOrder,
           cubeorder = cubeorder
             + zci.item_cube(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * numQtyEntered,
           amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           weight_entered_lbs = weight_entered_lbs + numWeight_Entered_lbs,
           weight_entered_kgs = weight_entered_kgs + numWeight_Entered_kgs
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
           dtlpassthruchar01 = nvl(strDtlPassThruChar01,dtlpassthruchar01),
           dtlpassthruchar02 = nvl(rtrim(in_dtlpassthruchar02),dtlpassthruchar02),
           dtlpassthruchar03 = nvl(strDtlPassThruChar03,dtlpassthruchar03),
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
           dtlpassthruchar21 = nvl(rtrim(in_dtlpassthruchar21),dtlpassthruchar21),
           dtlpassthruchar22 = nvl(rtrim(in_dtlpassthruchar22),dtlpassthruchar22),
           dtlpassthruchar23 = nvl(rtrim(in_dtlpassthruchar23),dtlpassthruchar23),
           dtlpassthruchar24 = nvl(rtrim(in_dtlpassthruchar24),dtlpassthruchar24),
           dtlpassthruchar25 = nvl(rtrim(in_dtlpassthruchar25),dtlpassthruchar25),
           dtlpassthruchar26 = nvl(rtrim(in_dtlpassthruchar26),dtlpassthruchar26),
           dtlpassthruchar27 = nvl(rtrim(in_dtlpassthruchar27),dtlpassthruchar27),
           dtlpassthruchar28 = nvl(rtrim(in_dtlpassthruchar28),dtlpassthruchar28),
           dtlpassthruchar29 = nvl(rtrim(in_dtlpassthruchar29),dtlpassthruchar29),
           dtlpassthruchar30 = nvl(rtrim(in_dtlpassthruchar30),dtlpassthruchar30),
           dtlpassthruchar31 = nvl(rtrim(in_dtlpassthruchar31),dtlpassthruchar31),
           dtlpassthruchar32 = nvl(rtrim(in_dtlpassthruchar32),dtlpassthruchar32),
           dtlpassthruchar33 = nvl(rtrim(in_dtlpassthruchar33),dtlpassthruchar33),
           dtlpassthruchar34 = nvl(rtrim(in_dtlpassthruchar34),dtlpassthruchar34),
           dtlpassthruchar35 = nvl(rtrim(in_dtlpassthruchar35),dtlpassthruchar35),
           dtlpassthruchar36 = nvl(rtrim(in_dtlpassthruchar36),dtlpassthruchar36),
           dtlpassthruchar37 = nvl(rtrim(in_dtlpassthruchar37),dtlpassthruchar37),
           dtlpassthruchar38 = nvl(rtrim(in_dtlpassthruchar38),dtlpassthruchar38),
           dtlpassthruchar39 = nvl(rtrim(in_dtlpassthruchar39),dtlpassthruchar39),
           dtlpassthruchar40 = nvl(rtrim(in_dtlpassthruchar40),dtlpassthruchar40),
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
           dtlpassthrunum11 = nvl(decode(in_dtlpassthrunum11,0,null,in_dtlpassthrunum11),dtlpassthrunum11),
           dtlpassthrunum12 = nvl(decode(in_dtlpassthrunum12,0,null,in_dtlpassthrunum12),dtlpassthrunum12),
           dtlpassthrunum13 = nvl(decode(in_dtlpassthrunum13,0,null,in_dtlpassthrunum13),dtlpassthrunum13),
           dtlpassthrunum14 = nvl(decode(in_dtlpassthrunum14,0,null,in_dtlpassthrunum14),dtlpassthrunum14),
           dtlpassthrunum15 = nvl(decode(in_dtlpassthrunum15,0,null,in_dtlpassthrunum15),dtlpassthrunum15),
           dtlpassthrunum16 = nvl(decode(in_dtlpassthrunum16,0,null,in_dtlpassthrunum16),dtlpassthrunum16),
           dtlpassthrunum17 = nvl(decode(in_dtlpassthrunum17,0,null,in_dtlpassthrunum17),dtlpassthrunum17),
           dtlpassthrunum18 = nvl(decode(in_dtlpassthrunum18,0,null,in_dtlpassthrunum18),dtlpassthrunum18),
           dtlpassthrunum19 = nvl(decode(in_dtlpassthrunum19,0,null,in_dtlpassthrunum19),dtlpassthrunum19),
           dtlpassthrunum20 = nvl(decode(in_dtlpassthrunum20,0,null,in_dtlpassthrunum20),dtlpassthrunum20),
           dtlpassthrudate01 = nvl(dtedtlpassthrudate01,dtlpassthrudate01),
           dtlpassthrudate02 = nvl(dtedtlpassthrudate02,dtlpassthrudate02),
           dtlpassthrudate03 = nvl(dtedtlpassthrudate03,dtlpassthrudate03),
           dtlpassthrudate04 = nvl(dtedtlpassthrudate04,dtlpassthrudate04),
           dtlpassthrudoll01 = nvl(decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),dtlpassthrudoll01),
           dtlpassthrudoll02 = nvl(decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),dtlpassthrudoll02),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           weight_entered_lbs = numWeight_Entered_lbs,
           weight_entered_kgs = numWeight_Entered_kgs
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
       and linenumber = chk.linenumber;

    l_qty := nvl(zbut.translate_uom_function(rtrim(in_custid), strItem, ol.qty,
                          ci.baseuom, nvl(strUpUOM, nvl(rtrim(in_uomentered), ci.baseuom))),
                ol.qty);

    update orderdtl
       set qtyentered = qtyentered + numQtyEntered - l_qty,
           qtyorder = qtyorder + qtyBase - ol.qty,
           weightorder = weightorder
             + (zci.item_weight(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * numQtyEntered)
             - (zci.item_weight(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * l_qty),
           cubeorder = cubeorder
             + (zci.item_cube(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * numQtyEntered)
             - (zci.item_cube(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * l_qty),
           amtorder = amtorder + (qtyBase - ol.qty) * zci.item_amt(custid,orderid,shipid,item,lotnumber),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           weight_entered_lbs = weight_entered_lbs + numWeight_Entered_lbs - ol.weight_entered_lbs,
           weight_entered_kgs = weight_entered_kgs + numWeight_Entered_kgs - ol.weight_entered_kgs,
           variancepct = in_variance_pct_shortage,
           variancepct_overage = in_variance_pct_overage,
           variancepct_use_default = in_variance_use_default_yn,
           lineorder = nvl(in_lineorder,lineorder)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  else
    if in_comment is not null then
      l_comment := in_comment;
    else
      select comment1 into l_comment
        from orderdtl
        where orderid = out_orderid
          and shipid = out_shipid
          and item = strItem
          and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
    end if;
    update orderdtl
       set uomentered = nvl(rtrim(in_uomentered),ci.baseuom),
           qtyentered = numQtyEntered,
           uom = strUOMBase,
           qtyorder = qtyBase,
           weightorder = numWeightOrder,
           cubeorder = zci.item_cube(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * numQtyEntered,
           amtorder = qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber),
           backorder = nvl(rtrim(in_backorder),backorder),
           allowsub = nvl(rtrim(in_allowsub),allowsub),
           qtytype = nvl(rtrim(in_qtytype),qtytype),
           invstatusind = nvl(rtrim(in_invstatusind),invstatusind),
           invstatus = nvl(rtrim(in_invstatus),invstatus),
           invclassind = nvl(rtrim(in_invclassind),invclassind),
           inventoryclass = nvl(rtrim(strInventoryclass),inventoryclass),
           consigneesku = nvl(rtrim(in_consigneesku),consigneesku),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           dtlpassthruchar01 = nvl(strDtlPassThruChar01,dtlpassthruchar01),
           dtlpassthruchar02 = nvl(rtrim(in_dtlpassthruchar02),dtlpassthruchar02),
           dtlpassthruchar03 = nvl(strDtlPassThruChar03,dtlpassthruchar03),
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
           dtlpassthruchar21 = nvl(rtrim(in_dtlpassthruchar21),dtlpassthruchar21),
           dtlpassthruchar22 = nvl(rtrim(in_dtlpassthruchar22),dtlpassthruchar22),
           dtlpassthruchar23 = nvl(rtrim(in_dtlpassthruchar23),dtlpassthruchar23),
           dtlpassthruchar24 = nvl(rtrim(in_dtlpassthruchar24),dtlpassthruchar24),
           dtlpassthruchar25 = nvl(rtrim(in_dtlpassthruchar25),dtlpassthruchar25),
           dtlpassthruchar26 = nvl(rtrim(in_dtlpassthruchar26),dtlpassthruchar26),
           dtlpassthruchar27 = nvl(rtrim(in_dtlpassthruchar27),dtlpassthruchar27),
           dtlpassthruchar28 = nvl(rtrim(in_dtlpassthruchar28),dtlpassthruchar28),
           dtlpassthruchar29 = nvl(rtrim(in_dtlpassthruchar29),dtlpassthruchar29),
           dtlpassthruchar30 = nvl(rtrim(in_dtlpassthruchar30),dtlpassthruchar30),
           dtlpassthruchar31 = nvl(rtrim(in_dtlpassthruchar31),dtlpassthruchar31),
           dtlpassthruchar32 = nvl(rtrim(in_dtlpassthruchar32),dtlpassthruchar32),
           dtlpassthruchar33 = nvl(rtrim(in_dtlpassthruchar33),dtlpassthruchar33),
           dtlpassthruchar34 = nvl(rtrim(in_dtlpassthruchar34),dtlpassthruchar34),
           dtlpassthruchar35 = nvl(rtrim(in_dtlpassthruchar35),dtlpassthruchar35),
           dtlpassthruchar36 = nvl(rtrim(in_dtlpassthruchar36),dtlpassthruchar36),
           dtlpassthruchar37 = nvl(rtrim(in_dtlpassthruchar37),dtlpassthruchar37),
           dtlpassthruchar38 = nvl(rtrim(in_dtlpassthruchar38),dtlpassthruchar38),
           dtlpassthruchar39 = nvl(rtrim(in_dtlpassthruchar39),dtlpassthruchar39),
           dtlpassthruchar40 = nvl(rtrim(in_dtlpassthruchar40),dtlpassthruchar40),
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
           dtlpassthrunum11 = nvl(decode(in_dtlpassthrunum11,0,null,in_dtlpassthrunum11),dtlpassthrunum11),
           dtlpassthrunum12 = nvl(decode(in_dtlpassthrunum12,0,null,in_dtlpassthrunum12),dtlpassthrunum12),
           dtlpassthrunum13 = nvl(decode(in_dtlpassthrunum13,0,null,in_dtlpassthrunum13),dtlpassthrunum13),
           dtlpassthrunum14 = nvl(decode(in_dtlpassthrunum14,0,null,in_dtlpassthrunum14),dtlpassthrunum14),
           dtlpassthrunum15 = nvl(decode(in_dtlpassthrunum15,0,null,in_dtlpassthrunum15),dtlpassthrunum15),
           dtlpassthrunum16 = nvl(decode(in_dtlpassthrunum16,0,null,in_dtlpassthrunum16),dtlpassthrunum16),
           dtlpassthrunum17 = nvl(decode(in_dtlpassthrunum17,0,null,in_dtlpassthrunum17),dtlpassthrunum17),
           dtlpassthrunum18 = nvl(decode(in_dtlpassthrunum18,0,null,in_dtlpassthrunum18),dtlpassthrunum18),
           dtlpassthrunum19 = nvl(decode(in_dtlpassthrunum19,0,null,in_dtlpassthrunum19),dtlpassthrunum19),
           dtlpassthrunum20 = nvl(decode(in_dtlpassthrunum20,0,null,in_dtlpassthrunum20),dtlpassthrunum20),
           dtlpassthrudate01 = nvl(dtedtlpassthrudate01,dtlpassthrudate01),
           dtlpassthrudate02 = nvl(dtedtlpassthrudate02,dtlpassthrudate02),
           dtlpassthrudate03 = nvl(dtedtlpassthrudate03,dtlpassthrudate03),
           dtlpassthrudate04 = nvl(dtedtlpassthrudate04,dtlpassthrudate04),
           dtlpassthrudoll01 = nvl(decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),dtlpassthrudoll01),
           dtlpassthrudoll02 = nvl(decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),dtlpassthrudoll02),
           rfautodisplay = nvl(rtrim(in_rfautodisplay),rfautodisplay),
            comment1 = l_comment,
           weight_entered_lbs = numWeight_Entered_lbs,
           weight_entered_kgs = numWeight_Entered_kgs,
           variancepct = in_variance_pct_shortage,
           variancepct_overage = in_variance_pct_overage,
           variancepct_use_default = in_variance_use_default_yn
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  end if;
elsif rtrim(in_func) = 'D' then -- delete function (do a cancel)
  if (nvl(rtrim(in_delete_by_linenumber_yn),'N') = 'N') or
     (nvl(rtrim(in_delete_by_linenumber_yn),'N') = 'Y' and
      olc.count = 1) then
    update orderdtl
       set linestatus = 'X',
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
  end if;
  if nvl(rtrim(in_delete_by_linenumber_yn),'N') = 'N' then
    delete from orderdtlline
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
  else
    delete from orderdtlline
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
       and linenumber = chk.linenumber;
    if olc.count > 1 then
      update orderdtl
         set qtyentered = qtyentered - ol.qty,
             qtyorder = qtyorder - ol.qty,
             weightorder = weightorder
               - (zci.item_weight(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * ol.qty),
             cubeorder = cubeorder
               - (zci.item_cube(rtrim(in_custid),strItem,nvl(strUpUOM, nvl(rtrim(in_uomentered),ci.baseuom))) * ol.qty),
             amtorder = amtorder - (ol.qty*zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             lastuser = IMP_USERID,
             lastupdate = sysdate,
             weight_entered_lbs = weight_entered_lbs  - ol.weight_entered_lbs,
             weight_entered_kgs = weight_entered_kgs  - ol.weight_entered_kgs,
             variancepct = in_variance_pct_shortage,
             variancepct_overage = in_variance_pct_overage,
             variancepct_use_default = in_variance_use_default_yn,
             lineorder = nvl(in_lineorder,lineorder)
       where orderid = out_orderid
         and shipid = out_shipid
         and item = strItem
         and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
    end if;
  end if;
end if;
if nvl(in_cancel_productgroup,'zz') != 'zz' then
    select nvl(productgroup,'zzzz') into strProductGroup
       from custitemview
          where custid = rtrim(in_custid)
            and item = strItem;
    if strProductGroup = in_cancel_productgroup  and
       substr(out_msg,1,19) != 'Item is not active:' then
       zoe.cancel_item(out_orderid,out_shipid,stritem,in_lotnumber,
                       oh.fromfacility,IMP_USERID,out_msg);
       if substr(out_msg,1,4) != 'OKAY' then
         zms.log_msg('ImpOrder', oh.fromfacility, in_custid,
           'Cancel Item: ' || out_orderid || '-' || out_shipid || ' ' ||
           stritem || ' ' || in_lotnumber || ' ' ||
           out_msg, 'E', IMP_USERID, strMsg);
       end if;
    end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziol ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_line;

procedure import_order_line_pack
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_linenumber IN number
,in_itementered IN varchar2
,in_qty IN number
,in_description IN varchar2
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
,in_dtlpassthrudate01 IN date
,in_dtlpassthrudate02 IN date
,in_dtlpassthrudate03 IN date
,in_dtlpassthrudate04 IN date
,in_dtlpassthrudoll01 IN number
,in_dtlpassthrudoll02 IN number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr(in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         ordertype,
         shipto,
         shiptostate
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;

cursor curOrderhdrHold(in_reference varchar2) is
   select orderid,
          shipid,
          orderstatus,
          fromfacility,
          tofacility,
          ordertype,
          shipto,
          shiptostate
     from orderhdr
    where custid = rtrim(in_custid)
      and reference = rtrim(in_reference)
      and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
    order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(linenumbersyn,'N') as linenumbersyn,
         nvl(recv_line_check_yn,'N') as recv_line_check_yn,
         nvl(a.bbb_routing_yn, 'N') as bbb_routing_yn,
         nvl(dup_reference_ynw,'N') as dup_reference_ynw
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;

cursor curOrderDtlPack is
  select *
    from orderdtlpack
   where orderid = out_orderid
     and shipid = out_shipid
     and item = rtrim(in_item)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
     and linenumber = in_linenumber
     and itementered = rtrim(in_itementered);
odp curOrderDtlPack%rowtype;

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
Order_by_weight boolean;
cntEntered integer;
strMsg varchar2(255);
pos integer;

procedure pack_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if nvl(rtrim(in_func),'x') = 'E' then
   in_func := 'A';
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code: ' || nvl(in_func,'null');
  pack_msg('E');
  return;
end if;

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.linenumbersyn := 'N';
  cs.dup_reference_ynw := 'N';
  cs.bbb_routing_yn := 'N';
end if;
close curCustomer;

if cs.dup_reference_ynw = 'H' then
   open curOrderhdrHold(in_reference);
   fetch curOrderhdrHold into oh;
   if curOrderhdrHold%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrHold;
else
   open curOrderhdr(in_reference);
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  pack_msg('E');
  return;
end if;

--if oh.orderstatus > '1' then
--  out_errorno := 2;
--  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
--  item_msg('E');
--  return;
--end if;

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.linenumbersyn := 'N';
end if;
close curCustomer;

odp := null;
open curOrderDtlPack;
fetch curOrderDtlPack into odp;
if curOrderDtlPack%found then
  chk.item := odp.item;
  chk.lotnumber := odp.lotnumber;
else
  chk.item := null;
  chk.lotnumber := null;
end if;
close curOrderDtlPack;

if rtrim(in_func) = 'D' then -- cancel function
  if chk.item is null then
    out_errorno := 3;
    out_msg := 'Order-line to be deleted not found';
    pack_msg('E');
    return;
  end if;
end if;

zci.get_customer_item(rtrim(in_custid),rtrim(in_item),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := in_itementered;
end if;

if nvl(in_linenumber,0) <= 0 then
  out_errorno := 5;
  out_msg := 'Invalid Line Number: ' || in_linenumber;
  pack_msg('E');
  return;
end if;

if in_func = 'R' or
   (chk.item is not null and
    in_func <> 'D') then
   in_func := 'U';
end if;
if rtrim(in_func) in ('A') then
  if chk.item is null then
    insert into orderdtlpack
      (orderid,shipid,item,lotnumber,linenumber,itementered,
       qty,description,lastuser,lastupdate,
       dtlpassthruchar01,dtlpassthruchar02,dtlpassthruchar03,dtlpassthruchar04,
       dtlpassthruchar05,dtlpassthruchar06,dtlpassthruchar07,dtlpassthruchar08,
       dtlpassthruchar09,dtlpassthruchar10,dtlpassthruchar11,dtlpassthruchar12,
       dtlpassthruchar13,dtlpassthruchar14,dtlpassthruchar15,dtlpassthruchar16,
       dtlpassthruchar17,dtlpassthruchar18,dtlpassthruchar19,dtlpassthruchar20,
       dtlpassthrunum01,dtlpassthrunum02,dtlpassthrunum03,dtlpassthrunum04,
       dtlpassthrunum05,dtlpassthrunum06,dtlpassthrunum07,dtlpassthrunum08,
       dtlpassthrunum09,dtlpassthrunum10,dtlpassthrudate01,dtlpassthrudate02,
       dtlpassthrudate03,dtlpassthrudate04,dtlpassthrudoll01,dtlpassthrudoll02)
    values
       (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),nvl(in_linenumber,0), rtrim(in_itementered),
        nvl(in_qty,0),rtrim(in_description), IMP_USERID,sysdate,
        rtrim(in_dtlpassthruchar01),rtrim(in_dtlpassthruchar02),rtrim(in_dtlpassthruchar03),rtrim(in_dtlpassthruchar04),
        rtrim(in_dtlpassthruchar05),rtrim(in_dtlpassthruchar06),rtrim(in_dtlpassthruchar07),rtrim(in_dtlpassthruchar08),
        rtrim(in_dtlpassthruchar09),rtrim(in_dtlpassthruchar10),rtrim(in_dtlpassthruchar11),rtrim(in_dtlpassthruchar12),
        rtrim(in_dtlpassthruchar13),rtrim(in_dtlpassthruchar14),rtrim(in_dtlpassthruchar15),rtrim(in_dtlpassthruchar16),
        rtrim(in_dtlpassthruchar17),rtrim(in_dtlpassthruchar18),rtrim(in_dtlpassthruchar19),rtrim(in_dtlpassthruchar20),
        in_dtlpassthrunum01,in_dtlpassthrunum02,in_dtlpassthrunum03,in_dtlpassthrunum04,in_dtlpassthrunum05,
        in_dtlpassthrunum06,in_dtlpassthrunum07,in_dtlpassthrunum08,in_dtlpassthrunum09,in_dtlpassthrunum10,
        in_dtlpassthrudate01,in_dtlpassthrudate02,in_dtlpassthrudate03,in_dtlpassthrudate04,in_dtlpassthrudoll01,
        in_dtlpassthrudoll02);

  end if;
elsif rtrim(in_func) = 'U' then
  update orderdtlpack
     set qty = nvl(in_qty, qty),
         description = nvl(rtrim(in_description), description),
         dtlpassthruchar01 = nvl(rtrim(in_dtlpassthruchar01), dtlpassthruchar01),
         dtlpassthruchar02 = nvl(rtrim(in_dtlpassthruchar02), dtlpassthruchar02),
         dtlpassthruchar03 = nvl(rtrim(in_dtlpassthruchar03), dtlpassthruchar03),
         dtlpassthruchar04 = nvl(rtrim(in_dtlpassthruchar04), dtlpassthruchar04),
         dtlpassthruchar05 = nvl(rtrim(in_dtlpassthruchar05), dtlpassthruchar05),
         dtlpassthruchar06 = nvl(rtrim(in_dtlpassthruchar06), dtlpassthruchar06),
         dtlpassthruchar07 = nvl(rtrim(in_dtlpassthruchar07), dtlpassthruchar07),
         dtlpassthruchar08 = nvl(rtrim(in_dtlpassthruchar08), dtlpassthruchar08),
         dtlpassthruchar09 = nvl(rtrim(in_dtlpassthruchar09), dtlpassthruchar09),
         dtlpassthruchar10 = nvl(rtrim(in_dtlpassthruchar10), dtlpassthruchar10),
         dtlpassthruchar11 = nvl(rtrim(in_dtlpassthruchar11), dtlpassthruchar11),
         dtlpassthruchar12 = nvl(rtrim(in_dtlpassthruchar12), dtlpassthruchar12),
         dtlpassthruchar13 = nvl(rtrim(in_dtlpassthruchar13), dtlpassthruchar13),
         dtlpassthruchar14 = nvl(rtrim(in_dtlpassthruchar14), dtlpassthruchar14),
         dtlpassthruchar15 = nvl(rtrim(in_dtlpassthruchar15), dtlpassthruchar15),
         dtlpassthruchar16 = nvl(rtrim(in_dtlpassthruchar16), dtlpassthruchar16),
         dtlpassthruchar17 = nvl(rtrim(in_dtlpassthruchar17), dtlpassthruchar17),
         dtlpassthruchar18 = nvl(rtrim(in_dtlpassthruchar18), dtlpassthruchar18),
         dtlpassthruchar19 = nvl(rtrim(in_dtlpassthruchar19), dtlpassthruchar19),
         dtlpassthruchar20 = nvl(rtrim(in_dtlpassthruchar20), dtlpassthruchar20),
         dtlpassthrunum01 = nvl(in_dtlpassthrunum01, dtlpassthrunum01),
         dtlpassthrunum02 = nvl(in_dtlpassthrunum02, dtlpassthrunum02),
         dtlpassthrunum03 = nvl(in_dtlpassthrunum03, dtlpassthrunum03),
         dtlpassthrunum04 = nvl(in_dtlpassthrunum04, dtlpassthrunum04),
         dtlpassthrunum05 = nvl(in_dtlpassthrunum05, dtlpassthrunum05),
         dtlpassthrunum06 = nvl(in_dtlpassthrunum06, dtlpassthrunum06),
         dtlpassthrunum07 = nvl(in_dtlpassthrunum07, dtlpassthrunum07),
         dtlpassthrunum08 = nvl(in_dtlpassthrunum08, dtlpassthrunum08),
         dtlpassthrunum09 = nvl(in_dtlpassthrunum09, dtlpassthrunum09),
         dtlpassthrunum10 = nvl(in_dtlpassthrunum10, dtlpassthrunum10),
         dtlpassthrudate01 = nvl(in_dtlpassthrudate01, dtlpassthrudate01),
         dtlpassthrudate02 = nvl(in_dtlpassthrudate02, dtlpassthrudate02),
         dtlpassthrudate03 = nvl(in_dtlpassthrudate03, dtlpassthrudate03),
         dtlpassthrudate04 = nvl(in_dtlpassthrudate04, dtlpassthrudate04),
         dtlpassthrudoll01 = nvl(in_dtlpassthrudoll01, dtlpassthrudoll01),
         dtlpassthrudoll02 = nvl(in_dtlpassthrudoll02, dtlpassthrudoll02),
         lastuser = IMP_USERID,
         lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber, '(none)') = nvl(rtrim(in_lotnumber),'(none)')
       and in_itementered = rtrim(in_itementered);
else
   delete orderdtlpack
      where orderid = out_orderid
        and shipid = out_shipid
        and item = strItem
        and nvl(lotnumber, '(none)') = nvl(rtrim(in_lotnumber),'(none)')
        and in_itementered = rtrim(in_itementered);
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziolp ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_line_pack;

procedure import_order_header_instruct
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_instructions IN long
,in_include_cr_lf_yn IN varchar2
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrHold (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

cr varchar2(2);
strReference orderhdr.reference%type;
str_dup_reference_ynw customer.dup_reference_ynw%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

begin
select nvl(dup_reference_ynw,'N') into str_dup_reference_ynw
    from customer
   where custid = rtrim(in_custid);
exception when others then
   str_dup_reference_ynw := 'N';
end;

if str_dup_reference_ynw = 'H' then
   open curOrderhdrHold(strReference);
   fetch curOrderhdrHold into oh;
   if curOrderhdrHold%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrHold;
else
   open curOrderhdr(strReference);
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if out_orderid != 0 then
  if oh.orderstatus > '0' then
    out_errorno := 2;
    out_msg := 'Invalid Order Header Status (instruct)';
    order_msg('E');
    return;
  end if;
end if;

if out_orderid = 0 then
  out_errorno := 3;
  out_msg := 'Cannot import instructions--order not found';
  order_msg('E');
  return;
end if;

if rtrim(in_func) in ('A','U','R') then
  if oh.comment1 is not null then
    if rtrim(in_include_cr_lf_yn) = 'Y' then
      cr := chr(13) || chr(10);
    else
      cr := ' ';
    end if;
    oh.comment1 := oh.comment1 || cr
                  || rtrim(in_instructions);
  else
    oh.comment1 := rtrim(in_instructions);
  end if;
  update orderhdr
     set comment1 = oh.comment1,
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif rtrim(in_func) = 'D' then
  update orderhdr
     set comment1 = null,
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziohi ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_header_instruct;

procedure import_order_header_bolcomment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_bolcomment IN long
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrHold (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

cursor curOrderHdrBolComments(in_orderid number, in_shipid number) is
  select orderid,shipid,bolcomment
    from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
bol curOrderHdrBolComments%rowtype;

cntRows integer;
strReference orderhdr.reference%type;
str_dup_reference_ynw customer.dup_reference_ynw%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

begin
   select nvl(dup_reference_ynw,'N') into str_dup_reference_ynw
       from customer
      where custid = rtrim(in_custid);
   exception when others then
      str_dup_reference_ynw := 'N';
end;

if str_dup_reference_ynw = 'H' then
   open curOrderhdrHold(strReference);
   fetch curOrderhdrHold into oh;
   if curOrderhdrHold%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrHold;
else
   open curOrderhdr(strReference);
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if out_orderid = 0 then
  out_errorno := 3;
  out_msg := 'Invalid Order Status (bolcomment)';
  order_msg('E');
  return;
end if;

if out_orderid != 0 then
  if oh.orderstatus > '0' then
    out_errorno := 2;
    out_msg := 'Invalid Order Status (bolcomment)';
    order_msg('E');
    return;
  end if;
end if;

begin
  select count(1)
    into cntRows
    from orderhdrbolcomments
   where orderid = out_orderid
     and shipid = out_shipid;
exception when others then
  cntRows := 0;
end;

if rtrim(in_func) = 'D' then
  if cntRows = 0 then
    out_errorno := 3;
    out_msg := 'Cannot delete bolcomments--not found';
    order_msg('E');
    return;
  end if;
end if;

if rtrim(in_func) in ('A','R') then
  if cntRows != 0 then
    out_msg := 'Add requested--bol comment already on file--update performed';
    order_msg('W');
    in_func := 'U';
  end if;
elsif rtrim(in_func) = 'U' then
  if cntRows = 0 then
    out_msg := 'Update requested--bol comment not on file--add performed';
    order_msg('W');
    in_func := 'A';
  end if;
end if;

if rtrim(in_func) in ('A','R') then
  insert into orderhdrbolcomments
  (orderid,shipid,bolcomment,lastuser,lastupdate)
  values
  (out_orderid,out_shipid,rtrim(in_bolcomment),IMP_USERID,sysdate);
elsif rtrim(in_func) = 'U' then
  bol := null;
  open curOrderHdrBolComments(out_orderid,out_shipid);
  fetch curOrderHdrBolComments into bol;
  close curOrderHdrBolComments;
  bol.bolcomment := rtrim(bol.bolcomment) || CHR(13) || CHR(10) || rtrim(in_bolcomment);
  update orderhdrbolcomments
     set bolcomment = bol.bolcomment,
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
elsif rtrim(in_func) = 'D' then
  delete from orderhdrbolcomments
   where orderid = out_orderid
     and shipid = out_shipid;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zihb ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_header_bolcomment;

procedure import_order_line_instruct
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_instructions IN long
,in_include_cr_lf_yn IN varchar2
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrHold (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select item,comment1
    from orderdtl
   where orderid = out_orderid
     and shipid = out_shipid
     and itementered = rtrim(in_itementered)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
od curOrderDtl%rowtype;
strReference orderhdr.reference%type;
str_dup_reference_ynw customer.dup_reference_ynw%type;

cr varchar2(2);

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  item_msg('E');
  return;
end if;

begin
  select nvl(dup_reference_ynw,'N') into str_dup_reference_ynw
      from customer
     where custid = rtrim(in_custid);
exception when others then
   str_dup_reference_ynw := 'N';
end;

if str_dup_reference_ynw = 'H' then
   open curOrderhdrHold(strReference);
   fetch curOrderhdrHold into oh;
   if curOrderhdrHold%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrHold;
else
   open curOrderhdr(strReference);
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if out_orderid != 0 then
  if oh.orderstatus > '0' then
    out_errorno := 2;
    out_msg := 'Invalid Order Status (line instruct)';
    item_msg('E');
    return;
  end if;
end if;

if out_orderid = 0 then
  out_errorno := 3;
  out_msg := 'Cannot import instructions--order not found';
  item_msg('E');
  return;
end if;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
  od.item := null;
end if;
close curOrderDtl;

if od.item is null then
  out_errorno := 4;
  out_msg := 'Cannot import instructions--order-line not found';
  item_msg('E');
  return;
end if;

if rtrim(in_func) = 'U' and
   od.comment1 is null then
  in_func := 'A';
end if;

if rtrim(in_func) in ('A','U','R') then
   if od.comment1 is not null then
     if rtrim(in_include_cr_lf_yn) = 'Y' then
       cr := chr(13) || chr(10);
     else
       cr := ' ';
     end if;
     od.comment1 := od.comment1 || cr
                    || rtrim(in_instructions);
   else
     od.comment1 := rtrim(in_instructions);
   end if;
  update orderdtl
     set comment1 = od.comment1,
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = od.item
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
elsif rtrim(in_func) = 'D' then
  update orderdtl
     set comment1 = null,
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = od.item
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zioli ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_line_instruct;

procedure import_order_line_bolcomment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_bolcomment IN long
,in_abc_revision in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrHold (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select item
    from orderdtl
   where orderid = out_orderid
     and shipid = out_shipid
     and itementered = rtrim(in_itementered)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
od curOrderDtl%rowtype;

cursor curOrderDtlBolComments is
  select orderid,shipid,bolcomment
    from orderdtlbolcomments
   where orderid = out_orderid
     and shipid = out_shipid
     and item = od.item
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
bol curOrderDtlBolComments%rowtype;

cntRows integer;
strReference orderhdr.reference%type;
str_dup_reference_ynw customer.dup_reference_ynw%type;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  item_msg('E');
  return;
end if;

begin
  select nvl(dup_reference_ynw,'N') into str_dup_reference_ynw
      from customer
     where custid = rtrim(in_custid);
exception when others then
   str_dup_reference_ynw := 'N';
end;

if str_dup_reference_ynw = 'H' then
   open curOrderhdrHold(strReference);
   fetch curOrderhdrHold into oh;
   if curOrderhdrHold%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrHold;
else
   open curOrderhdr(strReference);
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if out_orderid != 0 then
  if oh.orderstatus > '0' then
    out_errorno := 2;
    out_msg := 'Invalid Order Status (line bolcomment)';
    item_msg('E');
    return;
  end if;
end if;

if out_orderid = 0 then
  out_errorno := 3;
  out_msg := 'Cannot import bol comments--order not found';
  item_msg('E');
  return;
end if;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
  od.item := null;
end if;
close curOrderDtl;

if od.item is null then
  out_errorno := 4;
  out_msg := 'Cannot import bol comments--order-line not found';
  item_msg('E');
  return;
end if;

begin
  select count(1)
    into cntRows
    from orderdtlbolcomments
   where orderid = out_orderid
     and shipid = out_shipid
     and item = od.item
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
exception when others then
  cntRows := 0;
end;

if rtrim(in_func) = 'D' then
  if cntRows = 0 then
    out_errorno := 3;
    out_msg := 'Cannot delete bolcomments--not found';
    item_msg('E');
    return;
  end if;
end if;

if rtrim(in_func) in ('A','R') then
  if cntRows != 0 then
    out_msg := 'Add requested--bol comment already on file--update performed';
    item_msg('W');
    in_func := 'U';
  end if;
elsif rtrim(in_func) = 'U' then
  if cntRows = 0 then
    out_msg := 'Update requested--bol comment not on file--add performed';
    item_msg('W');
    in_func := 'A';
  end if;
end if;

if rtrim(in_func) in ('A','R') then
  insert into orderdtlbolcomments
  (orderid,shipid,item,lotnumber,bolcomment,lastuser,lastupdate)
  values
  (out_orderid,out_shipid,od.item,rtrim(in_lotnumber),rtrim(in_bolcomment),
   IMP_USERID,sysdate);
elsif rtrim(in_func) = 'U' then
  bol := null;
  open curOrderDtlBolComments;
  fetch curOrderDtlBolComments into bol;
  close curOrderDtlBolComments;
  bol.bolcomment := rtrim(bol.bolcomment) || CHR(13) || CHR(10) || rtrim(in_bolcomment);
  update orderdtlbolcomments
     set bolcomment = bol.bolcomment,
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = od.item
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
elsif rtrim(in_func) = 'D' then
  delete from orderdtlbolcomments
   where orderid = out_orderid
     and shipid = out_shipid
     and item = od.item
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziolb ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_line_bolcomment;

procedure release_and_commit_order
(in_orderid IN number
,in_shipid IN number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select nvl(fromfacility,tofacility) as facility,
         ordertype,
         orderid,
         custid,
         hdrpassthruchar02,
         source
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curWave(in_descr varchar2) is
  select wave
    from waves
   where facility = oh.facility
     and wavestatus = '1'
     and descr = in_descr
   order by wave;

cursor curOrigOrder(in_custid varchar2, in_returnref varchar2) is
  select orderid,
         shipid
    from orderhdr
   where custid = in_custid
     and reference = in_returnref
     and ordertype = 'O';
oo curOrigOrder%rowtype;

cursor C_CA(in_custid varchar2)
IS
select auto_assign_inbound_load
  from customer_aux
 where custid = in_custid;

CA C_CA%rowtype;

cntWarning integer;

errmsg varchar2(255);
l_manual_removal char(1) := 'N';

begin

out_errorno := 0;
out_msg := '';
cntWarning := 0;

oh := null;
open curOrderhdr;
fetch curOrderhdr into oh;
close curOrderhdr;
if oh.orderid is null then
  out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
  out_errorno := -1;
  return;
end if;

if oh.source = 'EDI' then
  l_manual_removal := 'Y';
end if;

if oh.ordertype in ('R','Q','P','A','C','I') then
  if oh.ordertype = 'Q' then
    update orderdtl
       set invclassind = decode(invclassind,null,'I',invclassind),
           inventoryclass = decode(inventoryclass,null,'OP',inventoryclass)
     where orderid = in_orderid
       and shipid = in_shipid;
  else
    update orderdtl
       set invclassind = decode(invclassind,null,'I',invclassind),
           inventoryclass = decode(inventoryclass,null,'RG',inventoryclass)
     where orderid = in_orderid
       and shipid = in_shipid;
  end if;
  update orderhdr
     set fromfacility = null,
         shipdate = null,
         origorderid = oo.orderid,
         origshipid = oo.shipid
   where orderid = in_orderid
     and shipid = in_shipid;

  if oh.ordertype = 'R' and oh.source = 'EDI' then
    CA := null;
    OPEN C_CA(oh.custid);
    FETCH C_CA into CA;
    CLOSE C_CA;

    if nvl(CA.auto_assign_inbound_load, 'N') = 'Y' then
      zoe.remove_order_from_hold(
        in_orderid,
        in_shipid,
        oh.facility,
        IMP_USERID,
        cntWarning,
        out_errorno,
        out_msg,
        l_manual_removal);
      if out_errorno != 0 then
        return;
      end if;
    end if;
  end if;

  if oh.ordertype in ('R','C') then
    zmrl.set_master_receipt(in_orderid, in_shipid, errmsg);
  end if;
else
  update orderhdr
     set tofacility = null,
         rma = null
   where orderid = in_orderid
     and shipid = in_shipid;
  zoe.remove_order_from_hold(
    in_orderid,
    in_shipid,
    oh.facility,
    IMP_USERID,
    cntWarning,
    out_errorno,
    out_msg,
    l_manual_removal);
  if out_errorno != 0 then
    return;
  end if;
end if;

out_msg := 'OKAY-- order ' || in_orderid || '-' || in_shipid || ' processed';
out_errorno := 1;

exception when others then
  out_msg := 'zirac ' || sqlerrm;
  out_errorno := sqlcode;
end release_and_commit_order;

procedure import_order_seq_comment
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_sequence IN number
,in_comment IN varchar2
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
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrHold is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

curCust integer;
cntRows integer;
cmdSql varchar2(2000);
tbl_columnname varchar2(32);
tbl_nullcomment varchar2(1);
str_dup_reference_ynw customer.dup_reference_ynw%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
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

begin
  select nvl(dup_reference_ynw,'N') into str_dup_reference_ynw
      from customer
      where custid = rtrim(in_custid);
exception when others then
   str_dup_reference_ynw := 'N';
end;

if str_dup_reference_ynw = 'H' then
   open curOrderhdrHold;
   fetch curOrderhdrHold into oh;
   if curOrderhdrHold%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrHold;
else
   open curOrderhdr;
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if out_orderid != 0 then
  if oh.orderstatus > '0' then
    out_errorno := 2;
    out_msg := 'Invalid Order Status (comment seq)';
    order_msg('E');
    return;
  end if;
end if;

if out_orderid = 0 then
  out_errorno := 3;
  out_msg := 'Cannot import instructions--order not found';
  order_msg('E');
  return;
end if;

tbl_columnname := '';
tbl_nullcomment := null;
cmdSql := 'select descr from comment_seq_map_' || rtrim(in_custid) ||
  ' where to_number(code) = ' || in_sequence;
begin
  curCust := dbms_sql.open_cursor;
  dbms_sql.parse(curCust, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curCust,1,tbl_columnname,32);
  cntRows := dbms_sql.execute(curCust);
  cntRows := dbms_sql.fetch_rows(curCust);
  if cntRows <= 0 then
    dbms_sql.close_cursor(curCust);
    out_errorno := -1;
    out_msg := 'Cannot find sequence map entry '|| in_sequence;
    return;
  end if;
  dbms_sql.column_value(curCust,1,tbl_columnname);
  dbms_sql.close_cursor(curCust);
exception when no_data_found then
  dbms_sql.close_cursor(curCust);
end;

begin
  curCust := dbms_sql.open_cursor;
  dbms_sql.parse(curCust, 'update orderhdr set ' ||
    tbl_columnname || ' = :x where orderid = :y and shipid = :z',
    dbms_sql.native);
  if rtrim(in_func) = 'D' then
    dbms_sql.bind_variable(curCust, ':x', tbl_nullcomment);
  else
    dbms_sql.bind_variable(curCust, ':x', in_comment);
  end if;
  dbms_sql.bind_variable(curCust, ':y', out_orderid);
  dbms_sql.bind_variable(curCust, ':z', out_shipid);
  cntRows := dbms_sql.execute(curCust);
  dbms_sql.close_cursor(curCust);
exception when NO_DATA_FOUND then
  dbms_sql.close_cursor(curCust);
end;

if cntRows <> 1 then
  out_errorno := -2;
  out_msg := 'Update failed';
end if;
out_msg := 'OKAY';

exception when others then
  out_msg := 'ziosc ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_seq_comment;

procedure translate_cust_errorcode
(in_custid IN varchar2
,in_errorcode IN number
,in_errormsg IN varchar2
,out_errorcode IN OUT number
,out_errormsg IN OUT varchar2
) is

curCust integer;
cntRows integer;
cmdSql varchar2(2000);
tbl_errorcode number(4);
tbl_errormsg varchar2(32);

begin

out_errorcode := in_errorcode;
begin
  select descr
    into out_errormsg
    from ordervalidationerrors
   where to_number(code) = in_errorcode;
exception when others then
  out_errormsg := in_errormsg;
end;

cmdSql := 'select to_number(abbrev), descr from error_code_map_' ||
   rtrim(in_custid) || ' where to_number(code) = ' || in_errorcode;
begin
  curCust := dbms_sql.open_cursor;
  dbms_sql.parse(curCust, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curCust,1,tbl_errorcode);
  dbms_sql.define_column(curCust,2,tbl_errormsg,32);
  cntRows := dbms_sql.execute(curCust);
  cntRows := dbms_sql.fetch_rows(curCust);
  if cntRows <= 0 then
    dbms_sql.close_cursor(curCust);
    return;
  end if;
  dbms_sql.column_value(curCust,1,tbl_errorcode);
  dbms_sql.column_value(curCust,2,tbl_errormsg);
  dbms_sql.close_cursor(curCust);
  out_errorcode := tbl_errorcode;
  out_errormsg := tbl_errormsg;
  return;
exception when no_data_found then
  dbms_sql.close_cursor(curCust);
end;

exception when others then
  null;
end translate_cust_errorcode;

procedure end_of_import
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

cursor curCustAux is
  select overwrite_importfileid_yn
    from customer_aux
   where custid = rtrim(in_custid);
csaux curCustAux%rowtype;
procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_autonomous_msg(IMP_USERID, gc.fromfacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
gc.fromfacility := 'ALL';

open curCustAux;
fetch curCustAux into csaux;
  if curCustAux%notfound then
    out_msg := 'Cannot get customer code: ' || in_custid;
    out_errorno := -1;
    order_msg('E');
    close curCustAux;
    return;
  end if;
close curCustAux;
if nvl(csaux.overwrite_importfileid_yn,'N') = 'N' then
open getCust;
fetch getCust into gc;
if getCust%notfound then
  close getCust;
  out_msg := 'Cannot get customer code: ' || in_importfileid;
  out_errorno := -1;
    order_msg('E');
  return;
end if;
close getCust;
else
  gc.custid := rtrim(in_custid);
end if;

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
  out_msg := 'zimeoi ' || sqlerrm;
  out_errorno := sqlcode;
end end_of_import;

procedure update_confirm_date
(in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
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
 where custid = in_custid
   and reference = in_reference
   and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   and confirmed is null;

if sql%rowcount != 1 then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_custid || '-' || in_reference;
else
  out_errorno := 0;
  out_msg := 'OKAY';
end if;

exception when others then
  out_msg := 'zimucd ' || sqlerrm;
  out_errorno := sqlcode;
end update_confirm_date;

PROCEDURE get_exportfileseq
(in_custid IN varchar2
,out_exportfileseq OUT varchar2
) is

curSeq integer;
cntRows integer;
cmdSql varchar2(20000);
dbseq integer;
begin

cntRows := 0;
begin
  select count(1)
    into cntRows
    from user_sequences
   where sequence_name = 'EXPORTFILESEQ_' || rtrim(in_custid);
exception when others then
  cntRows := 0;
end;
if cntRows = 0 then
  cmdSql := 'create sequence exportfileseq_' || rtrim(in_custid) ||
    ' increment by 1 ' ||
    'start with 1 maxvalue 9999999 minvalue 1 nocache cycle ';
  curSeq := dbms_sql.open_cursor;
  dbms_sql.parse(curSeq, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSeq);
  dbms_sql.close_cursor(curSeq);
end if;
cmdSql := 'select exportfileseq_' || rtrim(in_custid) ||
  '.nextval from dual';
curSeq := dbms_sql.open_cursor;
dbms_sql.parse(curSeq, cmdSql, dbms_sql.native);
dbms_sql.define_column(curSeq,1,dbseq);
cntRows := dbms_sql.execute(curSeq);
cntRows := dbms_sql.fetch_rows(curSeq);
if cntRows <= 0 then
  out_exportfileseq := 0;
else
  dbms_sql.column_value(curSeq,1,dbseq);
end if;
dbms_sql.close_cursor(curSeq);

out_exportfileseq := dbseq;
out_exportfileseq := rtrim(out_exportfileseq);
while length(out_exportfileseq) < 7
loop
  out_exportfileseq := '0' || out_exportfileseq;
end loop;

exception when others then
  out_exportfileseq := '0000000';
end get_exportfileseq;

PROCEDURE get_exportfilesuffix
(in_custid IN varchar2
,in_company IN varchar2
,in_warehouse IN varchar2
,out_exportfilesuffix OUT varchar2
) is

curSeq integer;
cntRows integer;
cmdSql varchar2(20000);
begin

cmdSql := 'select abbrev from ship_summary_suffix_' || rtrim(in_custid) ||
  ' where code = ''' || rtrim(in_company) || rtrim(in_warehouse) || '''';
curSeq := dbms_sql.open_cursor;
dbms_sql.parse(curSeq, cmdSql, dbms_sql.native);
dbms_sql.define_column(curSeq,1,out_exportfilesuffix,12);
cntRows := dbms_sql.execute(curSeq);
cntRows := dbms_sql.fetch_rows(curSeq);
if cntRows <= 0 then
  out_exportfilesuffix := '??';
else
  dbms_sql.column_value(curSeq,1,out_exportfilesuffix);
end if;
dbms_sql.close_cursor(curSeq);

exception when others then
  out_exportfilesuffix := '??';
end get_exportfilesuffix;

procedure clone_format
(in_fromname IN varchar2
,in_toname IN varchar2
,in_lineinc IN number
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

newinc integer;
newlineinc integer;
cntRows integer;

cursor curFromFormat is
  select *
    from impexp_definitions
   where upper(name) = upper(in_fromname);
ff curFromFormat%rowtype;

cursor curToFormat is
  select *
    from impexp_definitions
   where upper(name) = upper(in_toname);
tf curToFormat%rowtype;

cursor curCheckInc(in_definc number) is
  select count(1) as count
    from impexp_definitions
   where definc = in_definc;

cursor curFromLines is
  select *
    from impexp_lines
   where definc = ff.definc;

cursor curFromChunks is
  select *
    from impexp_chunks
   where definc = ff.definc;

cursor curFromProcs is
  select *
    from impexp_afterprocessprocparams
   where definc = ff.definc;

cursor curFromLinesByLine is
  select *
    from impexp_lines
   where definc = ff.definc
     and lineinc = in_lineinc;

cursor curFromChunksByLine is
  select *
    from impexp_chunks
   where definc = ff.definc
     and lineinc = in_lineinc;

cursor curFromProcsByLine is
  select *
    from impexp_afterprocessprocparams
   where definc = ff.definc
     and lineinc = in_lineinc;

begin

out_errorno := 0;
out_msg := '';

ff.name := null;
open curFromFormat;
fetch curFromFormat into ff;
close curFromFormat;
if ff.name is null then
  out_errorno := -1;
  out_msg := 'From format not found: ' || in_fromname;
  return;
end if;

if in_lineinc != 0 then
  goto clone_line;
end if;

tf.name := null;
open curToFormat;
fetch curToFormat into tf;
close curToFormat;
if tf.name is not null then
  out_errorno := -2;
  out_msg := 'To format already on file: ' || in_toname;
  return;
end if;

out_msg := 'OKAY';

newinc := 1;
while (1=1)
loop
  open curCheckInc(newinc);
  fetch curCheckInc into cntRows;
  close curCheckInc;
  if cntRows = 0 then
    exit;
  end if;
  newinc := newinc + 1;
  if newinc > 9999999 then
    out_errorno := -3;
    out_msg := 'Cannot generate new format increment';
    return;
  end if;
end loop;

delete from impexp_afterprocessprocparams
 where definc = newinc;
delete from impexp_chunks
 where definc = newinc;
delete from impexp_lines
 where definc = newinc;

insert into impexp_definitions
(definc,name,targetalias,deffilename,dateformat,deftype,
 floatdecimals,amountdecimals,linelength,afterprocessproc,
 beforeprocessproc,afterprocessprocparams,beforeprocessprocparams,
 timeformat,includecrlf,separatefiles,sip_format_yn,
 trim_leading_spaces_yn,order_attachment_import_yn
)
values
(newinc,in_toname,ff.targetalias,ff.deffilename,ff.dateformat,ff.deftype,
 ff.floatdecimals,ff.amountdecimals,ff.linelength,ff.afterprocessproc,
 ff.beforeprocessproc,ff.afterprocessprocparams,ff.beforeprocessprocparams,
 ff.timeformat,ff.includecrlf,ff.separatefiles,ff.sip_format_yn,
 ff.trim_leading_spaces_yn,ff.order_attachment_import_yn
);

for fl in curFromLines
loop
  insert into impexp_lines
  (definc,lineinc,parent,type,identifier,delimiter,linealias,
   procname,delimiteroffset,afterprocessprocname,headertrailerflag,
   orderbycolumns,delimiteroffsettype
  )
  values
  (newinc,fl.lineinc,fl.parent,fl.type,fl.identifier,fl.delimiter,fl.linealias,
   fl.procname,fl.delimiteroffset,fl.afterprocessprocname,fl.headertrailerflag,
   fl.orderbycolumns,fl.delimiteroffsettype
  );
end loop;

for fc in curFromChunks
loop
  insert into impexp_chunks
  (definc,lineinc,chunkinc,chunktype,paramname,offset,length,defvalue,
   description,lktable,lkfield,lkkey,mappings,parentlineparam,
   chunkdecimals,fieldprefix,substring_position,substring_length,
   no_fieldprefix_on_null_value,from_another_chunk_description
  )
  values
  (newinc,fc.lineinc,fc.chunkinc,fc.chunktype,fc.paramname,fc.offset,fc.length,fc.defvalue,
   fc.description,fc.lktable,fc.lkfield,fc.lkkey,fc.mappings,fc.parentlineparam,
   fc.chunkdecimals,fc.fieldprefix,fc.substring_position,fc.substring_length,
   fc.no_fieldprefix_on_null_value,fc.from_another_chunk_description
  );
end loop;

for fa in curFromProcs
loop
  insert into impexp_afterprocessprocparams
  (definc,lineinc,paramname,chunkinc,defvalue
  )
  values
  (newinc,fa.lineinc,fa.paramname,fa.chunkinc,fa.defvalue
  );
end loop;

goto finish_it;

<<clone_line>>

cntRows := 0;
begin
  select count(1)
    into cntRows
    from impexp_lines
   where definc = ff.definc
     and lineinc = in_lineinc;
exception when others then
  cntRows := 0;
end;

if cntRows = 0 then
  out_errorno := -4;
  out_msg := 'From line not found: ' || in_lineinc;
  return;
end if;

newlineinc := 0;
begin
  select max(lineinc)+1
    into newlineinc
    from impexp_lines
   where definc = ff.definc;
exception when others then
  newlineinc := 0;
end;

if newlineinc = 0 then
  out_errorno := -5;
  out_msg := 'Cannot establish new line number: ' || newlineinc;
  return;
end if;

delete from impexp_afterprocessprocparams
 where definc = ff.definc
   and lineinc = newlineinc;
delete from impexp_chunks
 where definc = ff.definc
   and lineinc = newlineinc;
delete from impexp_lines
 where definc = ff.definc
   and lineinc = newlineinc;

for fl in curFromLinesByLine
loop
  insert into impexp_lines
  (definc,lineinc,parent,type,identifier,delimiter,linealias,
   procname,delimiteroffset,afterprocessprocname,headertrailerflag,
   orderbycolumns,delimiteroffsettype
  )
  values
  (ff.definc,newlineinc,fl.parent,fl.type,fl.identifier,fl.delimiter,
   'NEW' || substr(fl.linealias,4,35),
   fl.procname,fl.delimiteroffset,fl.afterprocessprocname,fl.headertrailerflag,
   fl.orderbycolumns,fl.delimiteroffsettype
  );
end loop;

for fc in curFromChunksByLine
loop
  insert into impexp_chunks
  (definc,lineinc,chunkinc,chunktype,paramname,offset,length,defvalue,
   description,lktable,lkfield,lkkey,mappings,parentlineparam,
   chunkdecimals,fieldprefix,substring_position,substring_length,
   no_fieldprefix_on_null_value,from_another_chunk_description
  )
  values
  (newinc,fc.lineinc,fc.chunkinc,fc.chunktype,fc.paramname,fc.offset,fc.length,fc.defvalue,
   fc.description,fc.lktable,fc.lkfield,fc.lkkey,fc.mappings,fc.parentlineparam,
   fc.chunkdecimals,fc.fieldprefix,fc.substring_position,fc.substring_length,
   fc.no_fieldprefix_on_null_value,fc.from_another_chunk_description
  );
end loop;

for fa in curFromProcsByLine
loop
  insert into impexp_afterprocessprocparams
  (definc,lineinc,paramname,chunkinc,defvalue
  )
  values
  (ff.definc,newlineinc,fa.paramname,fa.chunkinc,fa.defvalue
  );
end loop;

<<finish_it>>

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,255);
end clone_format;

procedure import_nothing
(in_dummy_parm IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

begin

out_errorno := 0;
out_msg := 'OKAY';

exception when others then
  out_errorno := 0;
  out_msg := 'OKAY';
end import_nothing;

procedure get_exportfileseq4
(in_custid IN varchar2
,out_exportfileseq4 OUT varchar2
) is

curSeq integer;
cntRows integer;
cmdSql varchar2(20000);
dbseq integer;
begin

cntRows := 0;
begin
  select count(1)
    into cntRows
    from user_sequences
   where sequence_name = 'EXPORTFILESEQ4_' || rtrim(in_custid);
exception when others then
  cntRows := 0;
end;
if cntRows = 0 then
  cmdSql := 'create sequence exportfileseq4_' || rtrim(in_custid) ||
    ' increment by 1 ' ||
    'start with 1 maxvalue 9999 minvalue 1 nocache cycle ';
  curSeq := dbms_sql.open_cursor;
  dbms_sql.parse(curSeq, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSeq);
  dbms_sql.close_cursor(curSeq);
end if;
cmdSql := 'select exportfileseq4_' || rtrim(in_custid) ||
  '.nextval from dual';
curSeq := dbms_sql.open_cursor;
dbms_sql.parse(curSeq, cmdSql, dbms_sql.native);
dbms_sql.define_column(curSeq,1,dbseq);
cntRows := dbms_sql.execute(curSeq);
cntRows := dbms_sql.fetch_rows(curSeq);
if cntRows <= 0 then
  out_exportfileseq4 := 0;
else
  dbms_sql.column_value(curSeq,1,dbseq);
end if;
dbms_sql.close_cursor(curSeq);

out_exportfileseq4 := dbseq;
out_exportfileseq4 := rtrim(out_exportfileseq4);
while length(out_exportfileseq4) < 4
loop
  out_exportfileseq4 := '0' || out_exportfileseq4;
end loop;

exception when others then
  out_exportfileseq4 := '0000';
end get_exportfileseq4;

procedure import_dup_order_header
(in_custid IN varchar2
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
,in_loadno in out number
,in_loadstop in out number
,in_loadshipno in out number
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curCustomer is
  select nvl(resubmitorder,'N') as resubmitorder,
        unique_order_identifier
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;
cntCons integer;
cntRows integer;
strShipto orderhdr.shipto%type;
strShiptoname orderhdr.shiptoname%type;
strShiptocontact orderhdr.shiptocontact%type;
strShiptoaddr1 orderhdr.shiptoaddr1%type;
strShiptoaddr2 orderhdr.shiptoaddr2%type;
strShiptocity orderhdr.shiptocity%type;
strShiptostate orderhdr.shiptostate%type;
strShiptopostalcode orderhdr.shiptopostalcode%type;
strShiptophone orderhdr.shiptophone%type;
strShiptofax orderhdr.shiptofax%type;
strShiptoemail orderhdr.shiptoemail%type;
strShiptocountrycode orderhdr.shiptocountrycode%type;

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
dtearrivaldate DATE;
ld_msg varchar2(255);
strMsg varchar2(255);
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
  zms.log_autonomous_msg(IMP_USERID, nvl(in_fromfacility,in_tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

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

BEGIN
  IF TRUNC(in_arrivaldate) = TO_DATE('12/30/1899','mm/dd/yyyy') THEN
    dtearrivaldate := NULL;
  ELSE
    dtearrivaldate := in_arrivaldate;
  END IF;
EXCEPTION WHEN OTHERS THEN
  dtehdrpassthrudate04 := NULL;
END;

zoe.get_next_orderid(out_orderid,out_msg);   --All orders are imported as a new orderid,
if substr(out_msg,1,4) != 'OKAY' then        --po and refrence may match an existing order
  out_errorno := 4;
  order_msg('E');
  return;
end if;
out_shipid := 1;

strShipto := in_shipto;
strShiptoname := in_shiptoname;
strShiptocontact := in_shiptocontact;
strShiptoaddr1 := in_shiptoaddr1;
strShiptoaddr2 := in_shiptoaddr2;
strShiptocity := in_shiptocity;
strShiptostate := in_shiptostate;
strShiptopostalcode := in_shiptopostalcode;
strShiptophone := in_shiptophone;
strShiptofax := in_shiptofax;
strShiptoemail := in_shiptoemail;
strShiptocountrycode := in_shiptocountrycode;

if nvl(in_validate_shipto,'n') = 'Y' then
   select count(1) into cntCons
      from custconsignee
      where custid = in_custid
        and consignee = in_shipto;
   if cntCons = 0 then
      strShipto := null;
   else
      strShiptoname := null;
      strShiptocontact := null;
      strShiptoaddr1 := null;
      strShiptoaddr2 := null;
      strShiptocity := null;
      strShiptostate := null;
      strShiptopostalcode := null;
      strShiptophone := null;
      strShiptofax := null;
      strShiptoemail := null;
      strShiptocountrycode := null;
   end if;
end if;

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
   specialservice3, specialservice4, source,
   cancel_after, delivery_requested, requested_ship,
   ship_not_before, ship_no_later, cancel_if_not_delivered_by,
   do_not_deliver_after, do_not_deliver_before,
   hdrpassthrudate01, hdrpassthrudate02,
   hdrpassthrudate03, hdrpassthrudate04,
   hdrpassthrudoll01, hdrpassthrudoll02,
   rfautodisplay, arrivaldate
   )
  values
  (out_orderid,out_shipid,nvl(rtrim(in_custid),' '),nvl(rtrim(in_ordertype),' '),
  dteApptdate,dteShipDate,rtrim(in_po),rtrim(in_rma),rtrim(in_fromfacility),
  rtrim(in_tofacility),rtrim(strShipto),rtrim(in_billoflading),
  rtrim(in_priority),rtrim(in_shipper),rtrim(in_consignee),rtrim(in_shiptype),
  rtrim(in_carrier),rtrim(in_reference),rtrim(in_shipterms),rtrim(in_shippername),
  rtrim(in_shippercontact),
  rtrim(in_shipperaddr1),rtrim(in_shipperaddr2),rtrim(in_shippercity),
  rtrim(in_shipperstate),rtrim(in_shipperpostalcode),rtrim(in_shippercountrycode),
  rtrim(in_shipperphone),rtrim(in_shipperfax),rtrim(in_shipperemail),rtrim(strShiptoname),
  rtrim(strShiptocontact),
  rtrim(strShiptoaddr1),rtrim(strShiptoaddr2),rtrim(strShiptocity),
  rtrim(strShiptostate),rtrim(strShiptopostalcode),rtrim(strShiptocountrycode),
  rtrim(strShiptophone),rtrim(strShiptofax),rtrim(strShiptoemail),
  rtrim(in_billtoname),rtrim(in_billtocontact),rtrim(in_billtoaddr1),rtrim(in_billtoaddr2),
  rtrim(in_billtocity),rtrim(in_billtostate),rtrim(in_billtopostalcode),
  rtrim(in_billtocountrycode),rtrim(in_billtophone),rtrim(in_billtofax),
  rtrim(in_billtoemail),IMP_USERID,sysdate,
  '!','0',IMP_USERID,sysdate, --order status of '!' will be updated to 0 if after import process detects no errors
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
  'EDI',
  dtecancel_after, dtedelivery_requested, dterequested_ship,
  dteship_not_before, dteship_no_later, dtecancel_if_not_delivered_by,
  dtedo_not_deliver_after, dtedo_not_deliver_before,
  dtehdrpassthrudate01, dtehdrpassthrudate02,
  dtehdrpassthrudate03, dtehdrpassthrudate04,
  decode(in_hdrpassthrudoll01,0,null,in_hdrpassthrudoll01),
  decode(in_hdrpassthrudoll02,0,null,in_hdrpassthrudoll02),
  in_rfautodisplay, dtearrivaldate
  );
if nvl(in_loadno,0) != 0 and
   nvl(in_ordertype, 'X') = 'O' then
   import_assign_ob_order_to_load(out_orderid, out_shipid, rtrim(in_carrier), null, null, null, null, null,
                                  nvl(in_fromfacility,in_tofacility), IMP_USERID, in_loadno, in_loadstop,
                                  in_loadshipno, ld_msg);
   if ld_msg !=  'OKAY' then
     ld_msg := out_orderid || ' ' || out_shipid || ' ' || ld_msg;
     zms.log_autonomous_msg(IMP_USERID, in_fromfacility, in_custid,
        ld_msg,'E', IMP_USERID, strMsg);
   end if;

end if;
out_msg := 'OKAY';

exception when others then
  out_msg := 'zidoh ' || sqlerrm;
  out_errorno := sqlcode;
end import_dup_order_header;

procedure import_dup_order_line
(in_custid IN varchar2
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
,in_header_carrier varchar2
,in_invclass_states in varchar2
,in_invclass_states_value in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr(in_orderid number) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         ordertype,
         shipto,
         shiptostate
    from orderhdr
   where orderid = in_orderid
     and shipid = 1;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(linenumbersyn,'N') as linenumbersyn,
         nvl(recv_line_check_yn,'N') as recv_line_check_yn
    from customer
   where custid = rtrim(in_custid);
cs curCustomer%rowtype;

cursor curOrderDtl is
  select *
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

cursor curOrderDtlLine(in_item varchar2, in_linenumber number) is
  select *
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = rtrim(in_item)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
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
strUOMBase orderdtl.uom%type;
strIsKit custitem.IsKit%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;
strLineNumbers char(1);
strInventoryclass orderdtl.inventoryclass%type;
dtedtlpassthrudate01 date;
dtedtlpassthrudate02 date;
dtedtlpassthrudate03 date;
dtedtlpassthrudate04 date;
l_comment long;
currentOrderID orderhdr.orderid%type;
chkstate orderhdr.shiptostate%type;
pos integer;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

procedure update_header_carrier(in_orderid number,in_shipid number, in_header_carrier varchar2)
is pragma AUTONOMOUS_TRANSACTION;
begin
   update orderhdr                    -- for certain customers with abc revisions, the new carrier-- will be passed in the order line
      set carrier = in_header_carrier
      where orderid = in_orderid
        and shipid = in_shipid;
   commit;
exception when others then
  rollback;
end update_header_carrier;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
currentOrderID := 0;

select max(orderid) into currentOrderID from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and nvl(po,'(no po)') = nvl(in_po, '(no po)')
     and orderstatus = '!';

if currentOrderID = 0 then
   out_errorno := 1;
   out_msg := 'Order header not found';
   item_msg('E');
   return;
end if;

open curOrderhdr(currentOrderID);
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

od := null;
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

zci.get_customer_item(rtrim(in_custid),rtrim(in_itementered),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := in_itementered;
end if;

olc.count := 0;

if ( (oh.ordertype in ('O','V')) and (cs.linenumbersyn = 'Y') ) or
   ( (oh.ordertype in ('R','Q','P','A','C','I')) and (cs.recv_line_check_yn != 'N') ) then
  strLineNumbers := 'Y';
else
  strLineNumbers := 'N';
end if;

if strLineNumbers = 'Y' then
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
    open curOrderDtlLine(strItem,in_dtlpassthrunum10);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      chk.linenumber := in_dtlpassthrunum10;
    end if;
    close curOrderDtlLine;
  else
    if od.dtlpassthrunum10 = in_dtlpassthrunum10 then
      chk.linenumber := od.dtlpassthrunum10;
    end if;
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

if in_header_carrier is not null then
   update_header_carrier(out_orderid, out_shipid, in_header_carrier);
end if;

strInventoryclass := in_inventoryclass;
if in_invclass_states is not null and
   in_invclass_states_value is not null then
   if oh.shipto is not null then
      begin
         select state into chkState
            from consignee
            where consignee = oh.shipto;
      exception when NO_DATA_FOUND then
         chkState := null;
      end;
   else
      chkState := oh.shiptostate;
   end if;
   if chkState is not null then
      pos := instr(in_invclass_states,chkState,1,1);
      if pos > 0 then
         strInventoryclass := in_invclass_states_value;
      end if;
   end if;
end if;

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
  dtlpassthrunum09, dtlpassthrunum10,
  dtlpassthrudate01, dtlpassthrudate02,
  dtlpassthrudate03, dtlpassthrudate04,
  dtlpassthrudoll01, dtlpassthrudoll02,
  rfautodisplay, comment1
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
   nvl(rtrim(strInventoryclass),ci.inventoryclass),rtrim(in_consigneesku),
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
   dtedtlpassthrudate01, dtedtlpassthrudate02,
   dtedtlpassthrudate03, dtedtlpassthrudate04,
   decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
   decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
   in_rfautodisplay, in_comment
   );

   -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
   -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
   update orderdtl
   set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
   where orderid = out_orderid
     and shipid = out_shipid
     and item = nvl(strItem,' ')
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');

   if strLineNumbers = 'Y' then
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
        dtlpassthrunum09, dtlpassthrunum10, DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
        DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
        lastuser, lastupdate
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
        dtedtlpassthrudate01, dtedtlpassthrudate02,
        dtedtlpassthrudate03, dtedtlpassthrudate04,
        decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
        decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
        IMP_USERID, sysdate
       );
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
      dtlpassthrunum09, dtlpassthrunum10, DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
      DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
      QTYAPPROVED, lastuser, lastupdate
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
      od.dtlpassthrunum09, od.dtlpassthrunum10, od.DTLPASSTHRUDATE01,od.DTLPASSTHRUDATE02,
      od.DTLPASSTHRUDATE03,od.DTLPASSTHRUDATE04,od.DTLPASSTHRUDOLL01,od.DTLPASSTHRUDOLL02,
      null, IMP_USERID, sysdate
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
    dtlpassthrunum09, dtlpassthrunum10, DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
    DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
    lastuser, lastupdate
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
    dtedtlpassthrudate01, dtedtlpassthrudate02,
    dtedtlpassthrudate03, dtedtlpassthrudate04,
    decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
    decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
    IMP_USERID, sysdate
   );
  update orderdtl
     set qtyentered = qtyentered + in_qtyentered,
         qtyorder = qtyorder + qtyBase,
         weightorder = weightorder
           + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
         cubeorder = cubeorder
           + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * in_qtyentered,
         amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)),
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zidol ' || sqlerrm;
  out_errorno := sqlcode;
end import_dup_order_line;

procedure import_dup_order_hdr_notes
(in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
IS

cursor curOrderHdr(in_orderid number) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1
    from orderhdr
   where orderid = in_orderid
     and shipid = 1;
oh curOrderHdr%rowtype;


cr varchar2(2);
currentOrderID orderhdr.orderid%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;


begin

out_errorno := 0;
out_msg := 'OKAY';
out_orderid := 0;
out_shipid := 0;


select max(orderid) into currentOrderID from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and nvl(po,'(no po)') = nvl(in_po, '(no po)')
     and orderstatus = '!';

if currentOrderID = 0 then
   out_errorno := 1;
   out_msg := 'Order header not found';
   order_msg('E');
   return;
end if;

open curOrderHdr(currentOrderID);
fetch curOrderHdr into oh;
if curOrderHdr%FOUND then
   out_orderid := oh.orderid;
   out_shipid := oh.shipid;
end if;
close curOrderHdr;

if out_orderid = 0 then
   out_errorno := 3;
   out_msg := 'Cannot import instructions--order not found';
   order_msg('E');
   return;
end if;

if oh.comment1 is not null then
   cr := chr(13) || chr(10);
else
   cr := null;
end if;
oh.comment1 := oh.comment1 || cr || rtrim(in_qualifier)||'-'||rtrim(in_note);

update orderhdr
   set comment1 = oh.comment1,
       lastuser = IMP_USERID,
       lastupdate = sysdate
 where orderid = out_orderid
   and shipid = out_shipid;


exception when others then
  out_msg := 'zimdohn ' || sqlerrm;
  out_errorno := sqlcode;
end import_dup_order_hdr_notes;

procedure end_of_dup_import
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor getOrders is
  select orderid,
         shipid,
         po,
         reference,
         custid,
         fromfacility,
         tofacility
    from orderhdr
   where importfileid = rtrim(upper(in_importfileid));
--oh getOrders%rowtype;

cursor getDetails(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         dtlpassthrunum10
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;
--od getDetails%rowtype;

cursor getDetailLines(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         dtlpassthrunum10
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid;
--odl getDetailLines%rowtype;

strLinenumbersYN char(1);

oCnt integer;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_autonomous_msg(IMP_USERID, '', rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

procedure test_details(in_orderid number, in_shipid number, in_custid varchar2,
                       in_reference varchar2, in_po varchar2, in_facility varchar2) is
dCnt integer;
begin
   if strLinenumbersYN = 'Y' then
      for odl in getDetailLines(in_orderid, in_shipid) loop
         select count(1) into dCnt
            from orderdtlline
            where (orderid,shipid) in (select orderid, shipid from orderhdr
                                        where reference = in_reference
                                          and custid = in_custid
                                          and nvl(po,'(no po)') = nvl(in_po, '(no po)')
                                          and orderstatus != 'X'
                                          and orderid < in_orderid)
              and item = odl.item
              and nvl(lotnumber, '(none)') = nvl(odl.lotnumber, '(none)')
              and nvl(dtlpassthrunum10,0) = nvl(odl.dtlpassthrunum10,0);
         if dCnt = 0 then
            select count(1) into dCnt /* this is for orders created without orderdtllines */
               from orderdtl
               where (orderid,shipid) in (select orderid, shipid from orderhdr
                                           where reference = in_reference
                                             and custid = in_custid
                                             and nvl(po,'(no po)') = nvl(in_po, '(no po)')
                                             and orderstatus != 'X'
                                             and orderid < in_orderid)
                 and item = odl.item
                 and nvl(lotnumber, '(none)') = nvl(odl.lotnumber, '(none)')
                 and nvl(dtlpassthrunum10,0) = nvl(odl.dtlpassthrunum10,0);
         end if;
         if dCnt > 0 then
            zoe.cancel_order_request(in_orderid, in_shipid, in_facility,'EDI',IMP_USERID, out_msg);
            out_msg := 'Duplicate Item/line ' ||in_custid || ' ' || in_importfileid || ' '
              || in_orderid || ' ' || in_reference || ' ' || odl.item || ' ' || odl.dtlpassthrunum10;
            order_msg('E');
            return;
         end if;
      end loop;
   else
      for od in getDetails(in_orderid, in_shipid) loop
         select count(1) into dCnt
            from orderdtl
            where (orderid,shipid) in (select orderid, shipid from orderhdr
                                        where reference = in_reference
                                          and custid = in_custid
                                          and nvl(po,'(no po)') = nvl(in_po, '(no po)')
                                          and orderstatus != 'X'
                                          and orderid < in_orderid)
              and item = od.item
              and nvl(lotnumber, '(none)') = nvl(od.lotnumber, '(none)')
              and nvl(dtlpassthrunum10,0) = nvl(od.dtlpassthrunum10,0);
         if dCnt > 0 then
            zoe.cancel_order_request(in_orderid, in_shipid, in_facility,'EDI',IMP_USERID, out_msg);
            out_msg := 'Duplicate Item/line ' ||in_custid || ' ' || in_importfileid || ' '
              || in_orderid || ' ' || in_reference || ' ' || od.item || ' ' || od.dtlpassthrunum10;
            order_msg('E');

            return;
         end if;
      end loop;
   end if;
end;

begin

out_errorno := 0;
out_msg := '';

begin
   select nvl(linenumbersyn,'N') into strLinenumbersYN
      from customer
      where custid = in_custid;
exception when others then
   strLinenumbersYN := 'N';
end;

for oh in getOrders loop
   select count(1) into oCnt
      from orderhdr
      where reference = oh.reference
        and custid = oh.custid
        and nvl(po,'(no po)') = nvl(oh.po, '(no po)')
        and orderid < oh.orderid;
   if oCnt > 0 then
      test_details(oh.orderid, oh.shipid, oh.custid, oh.reference, oh.po, oh.fromfacility);
   end if;
end loop;

update orderhdr set orderstatus = '0'
   where importfileid = rtrim(upper(in_importfileid))
     and orderstatus = '!';

out_msg := 'End of import: ' ||in_custid || ' ' || in_importfileid || ' '
  || in_userid;
order_msg('I');

--zgp.pick_request('ENDIMP',nvl(gc.fromfacility,gc.tofacility),IMP_USERID,0,0,0,
--  in_importfileid,gc.custid,0,null,null,'N',out_errorno,out_msg);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeoi ' || sqlerrm;
  out_errorno := sqlcode;
end end_of_dup_import;


procedure import_file_sequence
(in_sequence in varchar2
,in_filename in varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is
iDate date;
begin
   out_errorno := 0;
   out_msg := '';
   select sysdate into iDate from dual;
   insert into importfileseq
      (importdate, importfileid,importsequence)
   values (iDate, in_filename, in_sequence);

exception when others then
  out_msg := 'zimiofh ' || sqlerrm;
  out_errorno := sqlcode;

end import_file_sequence;

PROCEDURE import_assign_ob_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
) is

theApt number;
theAptDate date;

cursor Corderhdr is
  select nvl(OH.orderstatus,'?') as orderstatus,
         nvl(OH.loadno,0) as loadno,
         nvl(OH.stopno,0) as stopno,
         nvl(OH.ordertype,'?') as ordertype,
         nvl(OH.fromfacility,' ') as fromfacility,
         nvl(OH.qtyorder,0) as qtyorder,
         nvl(OH.weightorder,0) as weightorder,
         nvl(OH.cubeorder,0) as cubeorder,
         nvl(OH.amtorder,0) as amtorder,
         nvl(OH.qtyship,0) as qtyship,
         nvl(OH.weightship,0) as weightship,
         nvl(OH.cubeship,0) as cubeship,
         nvl(OH.amtship,0) as amtship,
         OH.carrier,
         nvl(CU.paperbased, 'N') as paperbased,
         OH.wave
    from orderhdr OH, customer CU
   where OH.orderid = in_orderid
     and OH.shipid = in_shipid
     and CU.custid (+) = OH.custid;
oh Corderhdr%rowtype;

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         carrier,
         trailer,
         seal,
         billoflading,
         stageloc,
         doorloc,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility
    from loads
   where loadno = io_loadno;
ld Cloads%rowtype;

cursor curCarrier(in_carrier in varchar2) is
  select nvl(multiship,'N') as multiship
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

newloadstatus varchar2(2);
cordid waves.wave%type;
splitfac_order boolean := false;
l_cnt pls_integer;
stop_flag boolean;
load_exists boolean;
begin

out_msg := '';

stop_flag := TRUE;

if nvl(io_stopno, 0) = 0 then
  io_stopno := 1;
end if;

if nvl(io_shipno, 0) = 0 then
  io_shipno := 1;
end if;

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;
close Corderhdr;
cordid := zcord.cons_orderid(in_orderid, in_shipid);

if oh.paperbased = 'Y' then
  out_msg := 'Order is for an Aggregate Inventory Customer.  This order may not be assigned to a load.';
  return;
end if;

if (oh.ordertype in ('R', 'Q', 'P', 'A', 'C', 'I')) or
   (oh.ordertype = 'T' and oh.fromfacility != in_facility) then
  out_msg := 'Not an outbound order';
  return;
end if;

if oh.orderstatus > '6' then
  out_msg := 'Invalid order status: ' || oh.orderstatus;
  return;
end if;

if oh.loadno != 0 then
  out_msg := 'Order is already assigned to load ' || oh.loadno;
  return;
end if;

if rtrim(in_carrier) is not null then
  zva.validate_carrier(in_carrier,null,'A',out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if oh.carrier is not null then
  ca := null;
  open curCarrier(oh.carrier);
  fetch curCarrier into ca;
  close curCarrier;
  if ca.multiship = 'Y' then
    out_msg := 'Order is associated with a MultiShip Carrier: ' || oh.carrier;
    return;
  end if;
end if;

if rtrim(in_stageloc) is not null then
  zva.validate_location(in_facility,in_stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_doorloc) is not null then
  zva.validate_location(in_facility,in_doorloc,'DOR',null,
    'Door Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

load_exists := true;
open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  load_exists := false;
end if;
close Cloads;

splitfac_order := zloadentry.is_split_facility_order(in_orderid, in_shipid);
if load_exists then
  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;
  if ld.loadstatus > '8' then
    out_msg := 'Invalid load status for assignment: ' || ld.loadstatus;
    return;
  end if;
  if ( (oh.ordertype not in ('T'))  and (ld.loadtype <> 'OUTC') ) or
     ( (oh.ordertype in ('T'))      and (ld.loadtype <> 'OUTT') )
  then
    out_msg := 'Load/Order Type mismatch: ' ||
      ld.loadtype || '/' || oh.ordertype;
    return;
  end if;
  if rtrim(in_carrier) is not null then
    ld.carrier := in_carrier;
  end if;
  if rtrim(in_trailer) is not null then
    ld.trailer := in_trailer;
  end if;
  if rtrim(in_seal) is not null then
    ld.seal := in_seal;
  end if;
  if rtrim(in_billoflading) is not null then
    ld.billoflading := in_billoflading;
  end if;
  if rtrim(in_stageloc) is not null then
    ld.stageloc := in_stageloc;
  end if;
  if rtrim(in_doorloc) is not null then
    ld.doorloc := in_doorloc;
  end if;
  update loads
     set carrier = ld.carrier,
         trailer = ld.trailer,
         seal = ld.seal,
         billoflading = ld.billoflading,
         stageloc = ld.stageloc,
         doorloc = ld.doorloc,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno;
  update loadstopship
     set qtyorder = nvl(qtyorder,0) + oh.qtyorder,
         weightorder = nvl(weightorder,0) + oh.weightorder,
         cubeorder = nvl(cubeorder,0) + oh.cubeorder,
         amtorder = nvl(amtorder,0) + oh.amtorder,
         qtyship = nvl(qtyship,0) + oh.qtyship,
         weightship = nvl(weightship,0) + oh.weightship,
         cubeship = nvl(cubeship,0) + oh.cubeship,
         amtship = nvl(amtship,0) + oh.amtship,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno
     and shipno = io_shipno;
  if sql%rowcount = 0 then
    if stop_flag then
      select count(1) into l_cnt
        from loadstop
        where loadno = io_loadno
          and stopno = io_stopno;
      if l_cnt = 0 then

      insert into loadstop
       (loadno,stopno,entrydate,
        loadstopstatus,
        statususer,statusupdate,
        lastuser,lastupdate)
      values
       (io_loadno,io_stopno,sysdate,
        '2',
        in_userid,sysdate,
        in_userid,sysdate);
      end if;
      insert into loadstopship
       (loadno,stopno,shipno,
        entrydate,
        qtyorder,weightorder,
        cubeorder,amtorder,
        qtyship,weightship,
        cubeship,amtship,
        lastuser,lastupdate)
      values
       (io_loadno,io_stopno,io_shipno,
        sysdate,
        oh.qtyorder,oh.weightorder,
        oh.cubeorder,oh.amtorder,
        oh.qtyship,oh.weightship,
        oh.cubeship,oh.amtship,
        in_userid,sysdate);
    else
        out_msg := 'Load/Stop/Shipment not found: ' ||
        io_loadno || '/' || io_stopno || '/' || io_shipno;
        return;
    end if;
  end if;

  if splitfac_order then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and orderstatus != 'X'
       and nvl(loadno,0) = 0;
    for soh in (select qtyorder, weightorder, cubeorder, amtorder,
                       qtyship, weightship, cubeship, amtship
                  from orderhdr
                 where orderid = in_orderid
                   and shipid != in_shipid
                   and loadno = io_loadno) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + soh.qtyorder,
             weightorder = nvl(weightorder,0) + soh.weightorder,
             cubeorder = nvl(cubeorder,0) + soh.cubeorder,
             amtorder = nvl(amtorder,0) + soh.amtorder,
             qtyship = nvl(qtyship,0) + soh.qtyship,
             weightship = nvl(weightship,0) + soh.weightship,
             cubeship = nvl(cubeship,0) + soh.cubeship,
             amtship = nvl(amtship,0) + soh.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
      if sql%rowcount = 0 then
        out_msg := 'Load/Stop/Shipment not found: ' ||
          io_loadno || '/' || io_stopno || '/' || io_shipno;
        return;
      end if;
    end loop;
  elsif cordid = 0 then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and shipid = in_shipid;
  else
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave
       and orderstatus != 'X';
    for ch in (select qtyorder, weightorder, cubeorder, amtorder,
                      qtyship, weightship, cubeship, amtship
                 from orderhdr
                 where wave = oh.wave
                   and orderstatus != 'X'
                   and (orderid != in_orderid or shipid != in_shipid)) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + ch.qtyorder,
             weightorder = nvl(weightorder,0) + ch.weightorder,
             cubeorder = nvl(cubeorder,0) + ch.cubeorder,
             amtorder = nvl(amtorder,0) + ch.amtorder,
             qtyship = nvl(qtyship,0) + ch.qtyship,
             weightship = nvl(weightship,0) + ch.weightship,
             cubeship = nvl(cubeship,0) + ch.cubeship,
             amtship = nvl(amtship,0) + ch.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
    end loop;
  end if;
else
  if oh.ordertype not in ('T') then
    ld.loadtype := 'OUTC';
  else
    ld.loadtype := 'OUTT';
  end if;
  insert into loads
   (loadno,entrydate,loadstatus,
    trailer,seal,facility,
    doorloc,stageloc,carrier,
    statususer,statusupdate,
    lastuser,lastupdate,
    billoflading, loadtype)
  values
   (io_loadno,sysdate,'2',
    in_trailer,in_seal,oh.fromfacility,
    in_doorloc,in_stageloc,in_carrier,
    in_userid,sysdate,
    in_userid,sysdate,
    in_billoflading, ld.loadtype);
  insert into loadstop
   (loadno,stopno,entrydate,
    loadstopstatus,
    statususer,statusupdate,
    lastuser,lastupdate)
  values
   (io_loadno,io_stopno,sysdate,
    '2',
    in_userid,sysdate,
    in_userid,sysdate);
  insert into loadstopship
   (loadno,stopno,shipno,
    entrydate,
    qtyorder,weightorder,
    cubeorder,amtorder,
    qtyship,weightship,
    cubeship,amtship,
    lastuser,lastupdate)
  values
   (io_loadno,io_stopno,io_shipno,
    sysdate,
    oh.qtyorder,oh.weightorder,
    oh.cubeorder,oh.amtorder,
    oh.qtyship,oh.weightship,
    oh.cubeship,oh.amtship,
    in_userid,sysdate);
  if rtrim(in_carrier) is null then
    ld.carrier := oh.carrier;
  else
    ld.carrier := in_carrier;
  end if;

  if splitfac_order then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           carrier = ld.carrier,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and orderstatus != 'X'
       and nvl(loadno,0) = 0;
    for soh in (select qtyorder, weightorder, cubeorder, amtorder,
                       qtyship, weightship, cubeship, amtship
                  from orderhdr
                 where orderid = in_orderid
                   and shipid != in_shipid
                   and loadno = io_loadno) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + soh.qtyorder,
             weightorder = nvl(weightorder,0) + soh.weightorder,
             cubeorder = nvl(cubeorder,0) + soh.cubeorder,
             amtorder = nvl(amtorder,0) + soh.amtorder,
             qtyship = nvl(qtyship,0) + soh.qtyship,
             weightship = nvl(weightship,0) + soh.weightship,
             cubeship = nvl(cubeship,0) + soh.cubeship,
             amtship = nvl(amtship,0) + soh.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
      if sql%rowcount = 0 then
        out_msg := 'Load/Stop/Shipment not found: ' ||
          io_loadno || '/' || io_stopno || '/' || io_shipno;
        return;
      end if;
    end loop;
  elsif cordid = 0 then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           carrier = ld.carrier,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and shipid = in_shipid;
  else
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           carrier = ld.carrier,
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave
       and orderstatus != 'X';
    for ch in (select qtyorder, weightorder, cubeorder, amtorder,
                      qtyship, weightship, cubeship, amtship
                 from orderhdr
                 where wave = oh.wave
                   and orderstatus != 'X'
                   and (orderid != in_orderid or shipid != in_shipid)) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + ch.qtyorder,
             weightorder = nvl(weightorder,0) + ch.weightorder,
             cubeorder = nvl(cubeorder,0) + ch.cubeorder,
             amtorder = nvl(amtorder,0) + ch.amtorder,
             qtyship = nvl(qtyship,0) + ch.qtyship,
             weightship = nvl(weightship,0) + ch.weightship,
             cubeship = nvl(cubeship,0) + ch.cubeship,
             amtship = nvl(amtship,0) + ch.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
    end loop;
  end if;

end if;

if oh.orderstatus > '3' then
  if oh.orderstatus > '4' then
    newloadstatus := '5';
  else
    newloadstatus := '3';
  end if;
  zloadentry.min_load_status(io_loadno,in_facility,newloadstatus,in_userid);
  zloadentry.min_loadstop_status(oh.loadno,oh.stopno,in_facility,newloadstatus,in_userid);
end if;


-- update appointments
-- if assigning a load with an apt, update the order's apt info
-- else if assigning a load to an order with an apt, update the load's apt info.

select nvl(appointmentid,0),apptdate  into
       theApt, theAptDate
   from loads where loadno = io_loadno;

if theApt > 0 then
   update orderhdr
      set appointmentid = theApt,
                 apptdate = theAptDate
      where orderid = in_orderid
         and shipid = in_shipid;
else
   select nvl(appointmentid,0),apptdate  into
       theApt, theAptDate
   from orderhdr
      where orderid = in_orderid
         and shipid = in_shipid;
      if theApt > 0 then
      update loads
         set appointmentid = theApt,
                   apptdate = theAptDate
      where loadno = io_loadno;

      update orderhdr
         set appointmentid = theApt,
                       apptdate = theAptDate,
             lastuser = in_userid,
                       lastupdate = sysdate
            where loadno = io_loadno;

      update docappointments
         set loadno = io_loadno,
         lastuser = in_userid,
               lastupdate = sysdate
      where appointmentid = theApt;
    end if;
end if;


l_cnt := 0;
if splitfac_order then
  for soh in (select shipid from orderhdr
               where orderid = in_orderid
                 and loadno = io_loadno) loop
    zoh.add_orderhistory(in_orderid, soh.shipid,
         'Order To Load',
         'Order Assigned to Load '||io_loadno||'/'||io_stopno||'/'||io_shipno,
         in_userid, out_msg);
    l_cnt := l_cnt + 1;
  end loop;
else
  zoh.add_orderhistory(in_orderid, in_shipid,
       'Order To Load',
       'Order Assigned to Load '||io_loadno||'/'||io_stopno||'/'||io_shipno,
       in_userid, out_msg);
end if;

if l_cnt > 1 then
   out_msg := 'OKAYMULTI';
elsif cordid = 0 then
  out_msg := 'OKAY';
else
  out_msg := 'OKAYCONS';
end if;

exception when others then
  out_msg := 'ldaoo ' || substr(sqlerrm,1,80);
end import_assign_ob_order_to_load;

procedure import_order_hdr_sac
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po in varchar2
,in_sac01 in varchar2
,in_sac02 in varchar2
,in_sac03 in varchar2
,in_sac04 in varchar2
,in_sac05 in varchar2
,in_sac06 in varchar2
,in_sac07 in varchar2
,in_sac08 in varchar2
,in_sac09 in varchar2
,in_sac10 in varchar2
,in_sac11 in varchar2
,in_sac12 in varchar2
,in_sac13 in varchar2
,in_sac14 in varchar2
,in_sac15 in varchar2
,in_do_not_allow_duplicate_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr(in_reference varchar2) is
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
cursor CurRecHdrSac(in_orderid number, in_shipid number,  in_sac01 varchar2, in_sac02 varchar2, 
                    in_sac03 varchar2, in_sac04 varchar2, in_sac05 varchar2, in_sac06 varchar2, 
                    in_sac07 varchar2, in_sac08 varchar2, in_sac09 varchar2, in_sac10 varchar2,
                    in_sac11 varchar2, in_sac12 varchar2, in_sac13 varchar2, in_sac14 varchar2, 
                    in_sac15 varchar2) is
  select orderid,
         shipid
    from orderhdrsac
   where orderid = in_orderid
     and shipid = in_shipid
     and nvl(sac01,'none') = nvl(rtrim(in_sac01),'none')
     and nvl(sac02,'none') = nvl(rtrim(in_sac02),'none')
     and nvl(sac03,'none') = nvl(rtrim(in_sac03),'none')
     and nvl(sac04,'none') = nvl(rtrim(in_sac04),'none')
     and nvl(sac05,'none') = nvl(rtrim(in_sac05),'none')
     and nvl(sac06,'none') = nvl(rtrim(in_sac06),'none')
     and nvl(sac07,'none') = nvl(rtrim(in_sac07),'none')
     and nvl(sac08,'none') = nvl(rtrim(in_sac08),'none')
     and nvl(sac09,'none') = nvl(rtrim(in_sac09),'none')
     and nvl(sac10,'none') = nvl(rtrim(in_sac10),'none')
     and nvl(sac11,'none') = nvl(rtrim(in_sac11),'none')
     and nvl(sac12,'none') = nvl(rtrim(in_sac12),'none')
     and nvl(sac13,'none') = nvl(rtrim(in_sac13),'none')
     and nvl(sac14,'none') = nvl(rtrim(in_sac14),'none')
     and nvl(sac15,'none') = nvl(rtrim(in_sac15),'none');
hsacRec CurRecHdrSac%rowtype;
sac_orderid number;
sac_shipid number;

procedure hsac_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if nvl(sac_orderid,0) != 0 then
    out_msg := 'Order ' || sac_orderid || '-' || sac_shipid || ' ' || out_msg;
  end if;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
sac_orderid := 0;
sac_shipid := 0;
if nvl(rtrim(in_func),'x') = 'E' then
   in_func := 'A';
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  hsac_msg('E');
  return;
end if;

open curOrderhdr(in_reference);
fetch curOrderhdr into oh;
if curOrderHdr%found then
  sac_orderid := oh.orderid;
  sac_shipid := oh.shipid;
end if;
close curOrderhdr;

if sac_orderid = 0 then
  out_errorno := 1;
  out_msg := 'hsac Order header not found';
  hsac_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'hsac Invalid Order Header Status: '  || oh.orderstatus;
  hsac_msg('E');
  return;
end if;
if nvl(in_do_not_allow_duplicate_yn, 'N') = 'Y' then
   open CurRecHdrSac(oh.orderid, oh.shipid, in_sac01, in_sac02, in_sac03,
                     in_sac04, in_sac05, in_sac06, in_sac07, in_sac08, in_sac09,
                     in_sac10, in_sac11, in_sac12, in_sac13, in_sac14, in_sac15);
   fetch CurRecHdrSac into hsacRec;
   close CurRecHdrSac;
   if rtrim(in_func) in ('A' , 'U') then
     if nvl(hsacRec.orderid,0) != 0 then
         out_msg := 'hsac Add/Update request rejected--order already on file';
         hsac_msg('W');
         return;
     end if;
   end if;
   if rtrim(in_func) = 'U' then
     if nvl(hsacRec.orderid,0) = 0 then
        in_func := 'A';
     end if;
   end if;
end if;

if rtrim(in_func) = 'D' then
   delete from orderhdrsac
      where orderid = sac_orderid
        and shipid = sac_shipid;
elsif rtrim(in_func) = 'A' then
  insert into orderhdrsac
     (orderid, shipid, sac01, sac02, sac03, sac04, sac05, sac06, sac07,
      sac08, sac09, sac10, sac11, sac12, sac13, sac14, sac15, lastuser, lastupdate)
   values
     (oh.orderid, oh.shipid, rtrim(in_sac01), rtrim(in_sac02), rtrim(in_sac03),
      rtrim(in_sac04), rtrim(in_sac05), rtrim(in_sac06), rtrim(in_sac07), rtrim(in_sac08),
      rtrim(in_sac09), rtrim(in_sac10), rtrim(in_sac11), rtrim(in_sac12), rtrim(in_sac13),
      rtrim(in_sac14), rtrim(in_sac15), IMP_USERID, sysdate);
elsif rtrim(in_func) = 'U' then
   update orderhdrsac set
      sac01 = nvl(rtrim(sac01),sac01),
      sac02 = nvl(rtrim(sac02),sac02),
      sac03 = nvl(rtrim(sac03),sac03),
      sac04 = nvl(rtrim(sac04),sac04),
      sac05 = nvl(rtrim(sac05),sac05),
      sac06 = nvl(rtrim(sac06),sac06),
      sac07 = nvl(rtrim(sac07),sac07),
      sac08 = nvl(rtrim(sac08),sac08),
      sac09 = nvl(rtrim(sac09),sac09),
      sac10 = nvl(rtrim(sac10),sac10),
      sac11 = nvl(rtrim(sac11),sac11),
      sac12 = nvl(rtrim(sac12),sac12),
      sac13 = nvl(rtrim(sac13),sac13),
      sac14 = nvl(rtrim(sac14),sac14),
      sac15 = nvl(rtrim(sac15),sac15)
      where orderid = oh.orderid
        and shipid = oh.shipid;
elsif rtrim(in_func) = 'R' then
   update orderhdrsac set
      sac01 = rtrim(sac01),
      sac02 = rtrim(sac02),
      sac03 = rtrim(sac03),
      sac04 = rtrim(sac04),
      sac05 = rtrim(sac05),
      sac06 = rtrim(sac06),
      sac07 = rtrim(sac07),
      sac08 = rtrim(sac08),
      sac09 = rtrim(sac09),
      sac10 = rtrim(sac10),
      sac11 = rtrim(sac11),
      sac12 = rtrim(sac12),
      sac13 = rtrim(sac13),
      sac14 = rtrim(sac14),
      sac15 = rtrim(sac15)
      where orderid = oh.orderid
        and shipid = oh.shipid;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziohs ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_hdr_sac;

procedure import_order_dtl_sac
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po in varchar2
,in_item in varchar2
,in_lotnumber in varchar2
,in_sac01 in varchar2
,in_sac02 in varchar2
,in_sac03 in varchar2
,in_sac04 in varchar2
,in_sac05 in varchar2
,in_sac06 in varchar2
,in_sac07 in varchar2
,in_sac08 in varchar2
,in_sac09 in varchar2
,in_sac10 in varchar2
,in_sac11 in varchar2
,in_sac12 in varchar2
,in_sac13 in varchar2
,in_sac14 in varchar2
,in_sac15 in varchar2
,in_do_not_allow_duplicate_yn in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr(in_reference varchar2) is
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
sac_orderid number;
sac_shipid number;
strItem custitem.item%type;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;

cursor curOrderDtl is
  select *
    from orderdtl
   where orderid = sac_orderid
     and shipid = sac_shipid
     and itementered = rtrim(in_item)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
od curOrderDtl%rowtype;

cursor CurRecDtlSac(in_orderid number, in_shipid number,  in_item varchar2, in_lotnumber varchar2,
                    in_sac01 varchar2, in_sac02 varchar2, in_sac03 varchar2, in_sac04 varchar2, 
                    in_sac05 varchar2, in_sac06 varchar2, in_sac07 varchar2, in_sac08 varchar2, 
                    in_sac09 varchar2, in_sac10 varchar2, in_sac11 varchar2, in_sac12 varchar2, 
                    in_sac13 varchar2, in_sac14 varchar2, in_sac15 varchar2) is
  select orderid,
         shipid
    from orderdtlsac
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
     and nvl(sac01,'none') = nvl(rtrim(in_sac01),'none')
     and nvl(sac02,'none') = nvl(rtrim(in_sac02),'none')
     and nvl(sac03,'none') = nvl(rtrim(in_sac03),'none')
     and nvl(sac04,'none') = nvl(rtrim(in_sac04),'none')
     and nvl(sac05,'none') = nvl(rtrim(in_sac05),'none')
     and nvl(sac06,'none') = nvl(rtrim(in_sac06),'none')
     and nvl(sac07,'none') = nvl(rtrim(in_sac07),'none')
     and nvl(sac08,'none') = nvl(rtrim(in_sac08),'none')
     and nvl(sac09,'none') = nvl(rtrim(in_sac09),'none')
     and nvl(sac10,'none') = nvl(rtrim(in_sac10),'none')
     and nvl(sac11,'none') = nvl(rtrim(in_sac11),'none')
     and nvl(sac12,'none') = nvl(rtrim(in_sac12),'none')
     and nvl(sac13,'none') = nvl(rtrim(in_sac13),'none')
     and nvl(sac14,'none') = nvl(rtrim(in_sac14),'none')
     and nvl(sac15,'none') = nvl(rtrim(in_sac15),'none');
dsacRec CurRecDtlSac%rowtype;

procedure dsac_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if nvl(sac_orderid,0) != 0 then
    out_msg := 'Order ' || sac_orderid || '-' || sac_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_item) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
sac_orderid := 0;
sac_shipid := 0;
if nvl(rtrim(in_func),'x') = 'E' then
   in_func := 'A';
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  dsac_msg('E');
  return;
end if;

open curOrderhdr(in_reference);
fetch curOrderhdr into oh;
if curOrderHdr%found then
  sac_orderid := oh.orderid;
  sac_shipid := oh.shipid;
end if;
close curOrderhdr;

if sac_orderid = 0 then
  out_errorno := 1;
  out_msg := 'DSAC Order header not found';
  dsac_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'DSAC Invalid Order Header Status: '  || oh.orderstatus;
  dsac_msg('E');
  return;
end if;


od := null;
open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
   out_errorno := 3;
   out_msg := 'DSAC Order Detail not found: '  || oh.orderstatus;
   dsac_msg('E');
   return;
end if;
close curOrderDtl;

zci.get_customer_item(rtrim(in_custid),rtrim(in_item),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := in_item;
end if;
if nvl(in_do_not_allow_duplicate_yn, 'N') = 'Y' then
   open CurRecDtlSac(oh.orderid, oh.shipid, in_item, in_lotnumber,
                     in_sac01, in_sac02, in_sac03, in_sac04, in_sac05, 
                     in_sac06, in_sac07, in_sac08, in_sac09, in_sac10,
                     in_sac11, in_sac12, in_sac13, in_sac14, in_sac15);
   fetch CurRecDtlSac into dsacRec;
   close CurRecDtlSac;
   if rtrim(in_func) in( 'A', 'U') then
     if nvl(dsacRec.orderid,0) != 0 then
        out_msg := 'dsac Add/Update request rejected--order already on file';
        dsac_msg('W');
        return;
     end if;
   end if;
   if rtrim(in_func) = 'U' then
     if nvl(dsacRec.orderid,0) = 0 then
        in_func := 'A';
     end if;
   end if;
end if;

if rtrim(in_func) = 'D' then
   delete from orderdtlsac
      where orderid = sac_orderid
        and shipid = sac_shipid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
elsif rtrim(in_func) = 'A' then
  insert into orderdtlsac
     (orderid, shipid, item, lotnumber, sac01, sac02, sac03, sac04, sac05, sac06, sac07,
      sac08, sac09, sac10, sac11, sac12, sac13, sac14, sac15, lastuser, lastupdate)
   values
     (oh.orderid, oh.shipid, strItem, in_lotnumber, rtrim(in_sac01), rtrim(in_sac02), rtrim(in_sac03),
      rtrim(in_sac04), rtrim(in_sac05), rtrim(in_sac06), rtrim(in_sac07), rtrim(in_sac08),
      rtrim(in_sac09), rtrim(in_sac10), rtrim(in_sac11), rtrim(in_sac12), rtrim(in_sac13),
      rtrim(in_sac14), rtrim(in_sac15), IMP_USERID, sysdate);
elsif rtrim(in_func) = 'U' then
   update orderdtlsac set
      sac01 = nvl(rtrim(sac01),sac01),
      sac02 = nvl(rtrim(sac02),sac02),
      sac03 = nvl(rtrim(sac03),sac03),
      sac04 = nvl(rtrim(sac04),sac04),
      sac05 = nvl(rtrim(sac05),sac05),
      sac06 = nvl(rtrim(sac06),sac06),
      sac07 = nvl(rtrim(sac07),sac07),
      sac08 = nvl(rtrim(sac08),sac08),
      sac09 = nvl(rtrim(sac09),sac09),
      sac10 = nvl(rtrim(sac10),sac10),
      sac11 = nvl(rtrim(sac11),sac11),
      sac12 = nvl(rtrim(sac12),sac12),
      sac13 = nvl(rtrim(sac13),sac13),
      sac14 = nvl(rtrim(sac14),sac14),
      sac15 = nvl(rtrim(sac15),sac15)
      where orderid = oh.orderid
        and shipid = oh.shipid
        and item = strItem
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
elsif rtrim(in_func) = 'R' then
   update orderdtlsac set
      sac01 = rtrim(sac01),
      sac02 = rtrim(sac02),
      sac03 = rtrim(sac03),
      sac04 = rtrim(sac04),
      sac05 = rtrim(sac05),
      sac06 = rtrim(sac06),
      sac07 = rtrim(sac07),
      sac08 = rtrim(sac08),
      sac09 = rtrim(sac09),
      sac10 = rtrim(sac10),
      sac11 = rtrim(sac11),
      sac12 = rtrim(sac12),
      sac13 = rtrim(sac13),
      sac14 = rtrim(sac14),
      sac15 = rtrim(sac15)
      where orderid = oh.orderid
        and shipid = oh.shipid
        and item = strItem
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziods ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_dtl_sac;

procedure import_dup_order_line_sn
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_sn IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is
cursor curOrderHdr(in_orderid number) is
  select orderid,
         shipid,
         orderstatus,
         nvl(fromfacility,tofacility) facility,
         ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = 1;
oh curOrderHdr%rowtype;


cnt_rows integer;
out_orderid integer;
out_shipid integer;
currentOrderID orderhdr.orderid%type;
procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_item) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
  zms.log_msg(IMP_USERID, null, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;


begin

out_errorno := 0;
out_msg := 'OKAY';
out_orderid := 0;
out_shipid := 0;
currentOrderID := 0;

select max(orderid) into currentOrderID from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and nvl(po,'(no po)') = nvl(in_po, '(no po)')
     and orderstatus = '!';

if currentOrderID = 0 then
   out_errorno := 1;
   out_msg := 'Order header not found';
   item_msg('E');
   return;
end if;


open curOrderhdr(currentOrderID);
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;


if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  item_msg('E');
  return;
end if;

if out_orderid = 0 then
  out_errorno := 1;
  out_msg := 'Order header not found';
  item_msg('E');
  return;
end if;

if oh.orderstatus > '1' then
  out_errorno := 2;
  out_msg := 'Invalid Order Header Status: '  || oh.orderstatus;
  item_msg('E');
  return;
end if;


select count(1) into cnt_rows
  from orderdtlsn
  where orderid = out_orderid
    and shipid = out_shipid
    and item = in_item
    and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
    and sn = in_sn;

if in_func = 'D' then
   if cnt_rows = 0 then
      out_errorno := 3;
      out_msg := 'SN to be deleted not found';
      item_msg('E');
      return;
   else
      delete from orderdtlsn
        where orderid = out_orderid
          and shipid = out_shipid
          and item = in_item
          and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
          and sn = in_sn;
   end if;
   return;
end if;

if in_func = 'R' then
   return; -- nothing to do here
end if;

insert into orderdtlsn (custid, orderid, shipid, item, lotnumber, sn, lastuser, lastupdate)
   values (in_custid, out_orderid, out_shipid, in_item, in_lotnumber, in_sn,'IMPORDER',sysdate);


exception when others then
   out_msg := 'idols ' || substr(sqlerrm,1,80);
end import_dup_order_line_sn;

procedure import_bbb_carrier_assignment
(in_custid varchar2
,in_country_codes varchar2 -- (format: "XXX to YYY")
,in_from_state varchar2
,in_to_state varchar2
,in_ltl_carrier varchar2
,in_tl_carrier varchar2
,in_effdate_str varchar2  -- format 'mm/dd/yyyy'
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

l_count pls_integer;
l_ca_rowid rowid;

CA bbb_carrier_assignment%rowtype;

begin

out_errorno := 0;
out_msg := 'OKAY';

CA := null;
CA.custid := in_custid;
CA.from_countrycode := substr(in_country_codes,1,3);
CA.from_state := substr(in_from_state,1,2);
CA.to_countrycode := substr(in_country_codes,8,3);
CA.to_state := substr(in_to_state,1,2);
if in_from_state = 'NY2' then
  CA.from_zipcode_match := '100-104,110-119';
else
  CA.from_zipcode_match := '(DEFAULT)';
end if;
if in_to_state = 'NY2' then
  CA.to_zipcode_match := '100-104,110-119';
else
  CA.to_zipcode_match := '(DEFAULT)';
end if;

begin
  select ltl_carrier, tl_carrier, effdate, rowid
    into CA.ltl_carrier, CA.tl_carrier, CA.effdate, l_ca_rowid
    from bbb_carrier_assignment a
   where custid = CA.custid
     and from_countrycode = CA.from_countrycode
     and from_state = CA.from_state
     and to_countrycode = CA.to_countrycode
     and to_state = CA.to_state
     and from_zipcode_match = CA.from_zipcode_match
     and to_zipcode_match = CA.to_zipcode_match
     and effdate =
         (select max(effdate)
            from bbb_carrier_assignment b
           where custid = in_custid
             and from_countrycode = CA.from_countrycode
             and from_state = CA.from_state
             and to_countrycode = CA.to_countrycode
             and to_state = CA.to_state
             and b.from_zipcode_match = from_zipcode_match
             and b.to_zipcode_match = to_zipcode_match);
exception when no_data_found then
  null;
end;

if CA.ltl_carrier = in_ltl_carrier and
   CA.tl_carrier = in_tl_carrier then
  update bbb_carrier_assignment
     set lastupdate = sysdate,
         lastuser = 'IMPEXP'
   where rowid = l_ca_rowid;
  return;
end if;

if rtrim(in_effdate_str) is null then
  CA.effdate := trunc(sysdate);
else
  CA.effdate := to_date(in_effdate_str, 'mm/dd/yyyy');
end if;

CA.ltl_carrier := in_ltl_carrier;
CA.tl_carrier := in_tl_carrier;

insert into bbb_carrier_assignment
(custid,from_countrycode,from_state,to_countrycode,to_state,
 from_zipcode_match,to_zipcode_match,effdate,ltl_carrier,tl_carrier,
 lastuser,lastupdate)
values
(CA.custid,CA.from_countrycode,CA.from_state,CA.to_countrycode,CA.to_state,
 CA.from_zipcode_match,CA.to_zipcode_match,CA.effdate,CA.ltl_carrier,CA.tl_carrier,
 'IMPEXP',sysdate);

exception when others then
  out_msg := 'ibca ' || sqlerrm;
  out_errorno := sqlcode;
end import_bbb_carrier_assignment;

procedure log_order_import_ack
(in_importfile in varchar2
,in_custid in varchar2
,in_po in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_status in varchar2
,in_comment in varchar2
,in_action in varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
cntRows integer;
begin
   select count(1) into cntRows
      from import_order_acknowledgment
      where upper(importfileid) = upper(in_importfile)
        and custid = in_custid
        and nvl(po,'(none)') = nvl(in_po,'(none)')
        and reference = in_reference;
         
   if cntRows > 0 then
      update import_order_acknowledgment
        set orderid = nvl(in_orderid, orderid),
            shipid = nvl(in_shipid, shipid),
            status = decode(status,'E', status, in_status),
            ackcomment = ackcomment || '; ' || in_comment,
            lastupdate = sysdate,
            action = in_action
        where upper(importfileid) = upper(in_importfile)
          and custid = in_custid
          and nvl(po,'(none)') = nvl(in_po,'(none)')
          and reference = in_reference;
   else
      insert into import_order_acknowledgment
         (importfileid, custid, po, reference, orderid, shipid,
          status, ackcomment, lastupdate, action)
      values
         (in_importfile, in_custid, in_po, in_reference, in_orderid, in_shipid,
          in_status, in_comment, sysdate, in_action);
   end if;
   commit;

exception when others then
  rollback;
end log_order_import_ack;


procedure import_order_header_Kraft
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
,in_order_acknowledgment in varchar2
,in_canceled_new_order in varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         nvl(fromfacility,tofacility) facility,
         ordertype,
         nvl(loadno, 0) as loadno,
         editransaction
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(resubmitorder,'N') as resubmitorder,
        unique_order_identifier,
        nvl(dup_reference_ynw,'N') as dup_reference_ynw,
        nvl(bbb_routing_yn, 'N') as bbb_routing_yn,
        bbb_control_value_passthru_col,
        bbb_control_value,
        include_ack_cancel_orders_yn
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;

strReference orderhdr.reference%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference)
     ||' PO. '||rtrim(in_po)|| ': ' || out_msg;
  
  if nvl(out_orderid, 0) != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  
  zms.log_autonomous_msg(IMP_USERID, nvl(in_fromfacility,in_tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

open curOrderhdr(strReference);
fetch curOrderhdr into oh;
if curOrderHdr%found then
  if nvl(rtrim(in_ignore_received_orders_yn),'N') = 'Y' and
     oh.ordertype in ('R','Q','P','A','C','I') and
     oh.orderstatus in ('R','X') then
    null;
  else
    out_orderid := oh.orderid;
    out_shipid := oh.shipid;
  end if;
end if;
close curOrderhdr;

if rtrim(in_editransaction) = '943' and oh.editransaction = '943' then
   in_func := 'R';
elsif rtrim(in_editransaction) = '943' and oh.editransaction = '856' then
   out_msg := '943 request rejected. 856 already on file. '||
       oh.orderid||'-'||oh.shipid||' '||in_reference||' '||oh.editransaction;
   order_msg('E');
   return;
end if;

zimp.import_order_header
(in_func,in_custid,in_ordertype,in_apptdate,in_shipdate,in_po 
,in_rma,in_fromfacility,in_tofacility,in_shipto,in_billoflading 
,in_priority,in_shipper,in_consignee,in_shiptype,in_carrier 
,in_reference,in_shipterms,in_shippername,in_shippercontact 
,in_shipperaddr1,in_shipperaddr2,in_shippercity,in_shipperstate 
,in_shipperpostalcode,in_shippercountrycode,in_shipperphone 
,in_shipperfax,in_shipperemail,in_shiptoname,in_shiptocontact 
,in_shiptoaddr1,in_shiptoaddr2,in_shiptocity,in_shiptostate 
,in_shiptopostalcode,in_shiptocountrycode,in_shiptophone 
,in_shiptofax,in_shiptoemail,in_billtoname,in_billtocontact 
,in_billtoaddr1,in_billtoaddr2,in_billtocity,in_billtostate 
,in_billtopostalcode,in_billtocountrycode,in_billtophone 
,in_billtofax,in_billtoemail,in_deliveryservice
,in_saturdaydelivery,in_cod,in_amtcod,in_specialservice1 
,in_specialservice2,in_specialservice3,in_specialservice4 
,in_importfileid,in_hdrpassthruchar01,in_hdrpassthruchar02 
,in_hdrpassthruchar03,in_hdrpassthruchar04,in_hdrpassthruchar05 
,in_hdrpassthruchar06,in_hdrpassthruchar07,in_hdrpassthruchar08 
,in_hdrpassthruchar09,in_hdrpassthruchar10,in_hdrpassthruchar11 
,in_hdrpassthruchar12,in_hdrpassthruchar13,in_hdrpassthruchar14 
,in_hdrpassthruchar15,in_hdrpassthruchar16,in_hdrpassthruchar17 
,in_hdrpassthruchar18,in_hdrpassthruchar19,in_hdrpassthruchar20 
,in_hdrpassthruchar21,in_hdrpassthruchar22,in_hdrpassthruchar23 
,in_hdrpassthruchar24,in_hdrpassthruchar25,in_hdrpassthruchar26 
,in_hdrpassthruchar27,in_hdrpassthruchar28,in_hdrpassthruchar29 
,in_hdrpassthruchar30,in_hdrpassthruchar31,in_hdrpassthruchar32 
,in_hdrpassthruchar33,in_hdrpassthruchar34,in_hdrpassthruchar35 
,in_hdrpassthruchar36,in_hdrpassthruchar37,in_hdrpassthruchar38 
,in_hdrpassthruchar39,in_hdrpassthruchar40,in_hdrpassthruchar41 
,in_hdrpassthruchar42,in_hdrpassthruchar43,in_hdrpassthruchar44 
,in_hdrpassthruchar45,in_hdrpassthruchar46,in_hdrpassthruchar47 
,in_hdrpassthruchar48,in_hdrpassthruchar49,in_hdrpassthruchar50 
,in_hdrpassthruchar51,in_hdrpassthruchar52,in_hdrpassthruchar53 
,in_hdrpassthruchar54,in_hdrpassthruchar55,in_hdrpassthruchar56 
,in_hdrpassthruchar57,in_hdrpassthruchar58,in_hdrpassthruchar59 
,in_hdrpassthruchar60,in_hdrpassthrunum01,in_hdrpassthrunum02
,in_hdrpassthrunum03,in_hdrpassthrunum04,in_hdrpassthrunum05
,in_hdrpassthrunum06,in_hdrpassthrunum07,in_hdrpassthrunum08
,in_hdrpassthrunum09,in_hdrpassthrunum10,in_cancel_after
,in_delivery_requested,in_requested_ship,in_ship_not_before
,in_ship_no_later,in_cancel_if_not_delivered_by,in_do_not_deliver_after
,in_do_not_deliver_before,in_hdrpassthrudate01,in_hdrpassthrudate02
,in_hdrpassthrudate03,in_hdrpassthrudate04,in_hdrpassthrudoll01
,in_hdrpassthrudoll02,in_rfautodisplay,in_ignore_received_orders_yn 
,in_arrivaldate,in_validate_shipto,in_abc_revision,in_prono 
,in_editransaction,in_edi_logging_yn,in_futurevc01,in_futurevc02 
,in_futurevc03,in_futurevc04,in_futurevc05,in_futurevc06
,in_futurenum01,in_futurenum02,in_futurenum03,in_order_acknowledgment 
,in_canceled_new_order,out_orderid,out_shipid,out_errorno,out_msg
);

exception when others then
  out_msg := 'ziohk ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_header_Kraft;

procedure import_order_line_Kraft
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
,in_comment long
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
,in_order_acknowledgment varchar2
,in_importfileid IN varchar2
,in_notnullpassthrus_yn IN varchar2
,in_delete_by_linenumber_yn in varchar2
,in_weight_acceptance_yn in varchar2
,in_dtl_passthru_item_xref in varchar2
,in_itm_passthru_item_xref in varchar2
,in_canceled_new_order in varchar2
,in_up_to_base_yn in varchar2
,in_style_color_size_columns IN varchar2
,in_editransaction IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curOrderHdr(in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         ordertype,
         shipto,
         shiptostate,
         editransaction
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

strReference orderhdr.reference%type;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
strStatus char(1);
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(in_lotnumber),'(none)')
    || ' ' || out_msg;
    
  zms.log_autonomous_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

if in_abc_revision is not null then
   strReference := rtrim(in_reference) || rtrim(in_abc_revision);
else
   strReference := rtrim(in_reference);
end if;

open curOrderhdr(strReference);
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

if rtrim(in_editransaction) = '943' and oh.editransaction = '943' then
   in_func := 'R';
elsif rtrim(in_editransaction) != oh.editransaction then
   out_errorno := 6;
   out_msg := 'Detail edi transaction not the same as order header: '||
       oh.orderid||'-'||oh.shipid||' '||in_reference||'  '||
       'Header. '||oh.editransaction||' Detail. '||rtrim(in_editransaction);
   item_msg('E');
   return;
end if;

   out_msg := oh.orderid||'-'||oh.shipid||' '||in_reference||'  '||
       'Header EDI. '||oh.editransaction||' Detail EDI. '||rtrim(in_editransaction);
   item_msg('I');
   
zimp.import_order_line
(in_func,in_custid,in_reference,in_po,in_itementered,in_lotnumber
,in_uomentered,in_qtyentered,in_backorder,in_allowsub
,in_qtytype,in_invstatusind,in_invstatus,in_invclassind,in_inventoryclass 
,in_consigneesku,in_dtlpassthruchar01,in_dtlpassthruchar02
,in_dtlpassthruchar03,in_dtlpassthruchar04,in_dtlpassthruchar05
,in_dtlpassthruchar06,in_dtlpassthruchar07,in_dtlpassthruchar08 
,in_dtlpassthruchar09,in_dtlpassthruchar10,in_dtlpassthruchar11 
,in_dtlpassthruchar12,in_dtlpassthruchar13,in_dtlpassthruchar14 
,in_dtlpassthruchar15,in_dtlpassthruchar16,in_dtlpassthruchar17 
,in_dtlpassthruchar18,in_dtlpassthruchar19,in_dtlpassthruchar20 
,in_dtlpassthruchar21,in_dtlpassthruchar22,in_dtlpassthruchar23 
,in_dtlpassthruchar24,in_dtlpassthruchar25,in_dtlpassthruchar26 
,in_dtlpassthruchar27,in_dtlpassthruchar28,in_dtlpassthruchar29 
,in_dtlpassthruchar30,in_dtlpassthruchar31,in_dtlpassthruchar32 
,in_dtlpassthruchar33,in_dtlpassthruchar34,in_dtlpassthruchar35 
,in_dtlpassthruchar36,in_dtlpassthruchar37,in_dtlpassthruchar38 
,in_dtlpassthruchar39,in_dtlpassthruchar40,in_dtlpassthrunum01 
,in_dtlpassthrunum02,in_dtlpassthrunum03,in_dtlpassthrunum04 
,in_dtlpassthrunum05,in_dtlpassthrunum06,in_dtlpassthrunum07 
,in_dtlpassthrunum08,in_dtlpassthrunum09,in_dtlpassthrunum10 
,in_dtlpassthrunum11,in_dtlpassthrunum12,in_dtlpassthrunum13 
,in_dtlpassthrunum14,in_dtlpassthrunum15,in_dtlpassthrunum16 
,in_dtlpassthrunum17,in_dtlpassthrunum18,in_dtlpassthrunum19 
,in_dtlpassthrunum20,in_dtlpassthrudate01,in_dtlpassthrudate02
,in_dtlpassthrudate03,in_dtlpassthrudate04,in_dtlpassthrudoll01 
,in_dtlpassthrudoll02,in_rfautodisplay,in_comment
,in_weight_entered_lbs,in_weight_entered_kgs,in_variance_pct_shortage 
,in_variance_pct_overage,in_variance_use_default_yn,in_abc_revision 
,in_header_carrier,in_lineorder,in_cancel_productgroup,in_invclass_states 
,in_invclass_states_value,in_upper_item_yn,in_order_acknowledgment 
,in_importfileid,in_notnullpassthrus_yn,in_delete_by_linenumber_yn 
,in_weight_acceptance_yn,in_dtl_passthru_item_xref,in_itm_passthru_item_xref 
,in_canceled_new_order,in_up_to_base_yn,in_style_color_size_columns 
,out_orderid,out_shipid,out_errorno,out_msg   
);

exception when others then
  out_msg := 'ziohl ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_line_Kraft;

procedure import_order_hdr_notes_Kraft
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,in_abc_revision IN varchar2
,in_ordertype IN varchar2
,in_comment_type IN varchar2
,in_editransaction IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is
cursor curCustomer is
  select nvl(dup_reference_ynw,'N') as dup_reference_ynw
    from customer
   where custid = rtrim(in_custid);
cs curCustomer%rowtype;

cursor C_ORDERHDR_TYPE (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1,
         hdrpassthruchar56,
         editransaction
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and ordertype = rtrim(in_ordertype)
   order by orderstatus;

cursor C_ORDERHDR_HOLD (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1,
         hdrpassthruchar56,
         editransaction
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and ordertype = rtrim(in_ordertype)
   order by orderid desc, shipid desc;

cursor C_ORDERHDR (in_reference varchar2) is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1,
         hdrpassthruchar56,
         editransaction
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh C_ORDERHDR%rowtype;

cursor C_ORDERHDRBOL (in_orderid number, in_shipid number) is
  select orderid,
         shipid,
         bolcomment
    from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
ohb C_ORDERHDRBOL%rowtype;

cr varchar2(2);
strReference orderhdr.reference%type;
last_orderid    orderhdr.orderid%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;


begin
    out_errorno := 0;
    out_msg := 'OKAY';
    out_orderid := 0;
    out_shipid := 0;

    if in_abc_revision is not null then
       strReference := in_reference || in_abc_revision;
    else
       strReference := in_reference;
    end if;


    if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
       out_errorno := 1;
       out_msg := 'Invalid Function Code';
       order_msg('E');
       return;
    end if;

    open curCustomer;
    fetch curCustomer into cs;
    if curCustomer%notfound then
      cs.dup_reference_ynw := 'N';
    end if;
    close curCustomer;

    if cs.dup_reference_ynw = 'O' then
       if in_ordertype is null then
          out_errorno := 1;
          out_msg := 'IOHN Order Type Required for Dup Ord Order Type';
          order_msg('E');
          return;
       end if;
       open C_ORDERHDR_TYPE(strReference);
       fetch C_ORDERHDR_TYPE into oh;
       if C_ORDERHDR_TYPE%FOUND then
          out_orderid := oh.orderid;
          out_shipid := oh.shipid;
       end if;
       close C_ORDERHDR_TYPE;
    else
       if cs.dup_reference_ynw = 'H' then
          open C_ORDERHDR_HOLD(strReference);
          fetch C_ORDERHDR_HOLD into oh;
          if C_ORDERHDR_HOLD%FOUND then
             out_orderid := oh.orderid;
             out_shipid := oh.shipid;
          end if;
          close C_ORDERHDR_HOLD;
       else
          open C_ORDERHDR(strReference);
          fetch C_ORDERHDR into oh;
          if C_ORDERHDR%FOUND then
             out_orderid := oh.orderid;
             out_shipid := oh.shipid;
          end if;
          close C_ORDERHDR;
       end if;
    end if;
    
    if out_orderid = 0 then
       out_errorno := 3;
       out_msg := 'Cannot import instructions--order not found';
       order_msg('E');
       return;
    end if;
    
    ---------------------------------------------------------------
    -- Kraft logic
    ---------------------------------------------------------------
    if rtrim(in_editransaction) = '943' and oh.editransaction = '943' then
       in_func := 'R';
    elsif rtrim(in_editransaction) != oh.editransaction then
       out_errorno := 6;
       out_msg := 'Notes edi not the same as Header edi: '||
           oh.orderid||'-'||oh.shipid||' '||in_reference||'  '||
           'Header. '||oh.editransaction||' Notes. '||rtrim(in_editransaction);
       order_msg('E');
       return;
    end if;
    ---------------------------------------------------------------

    if out_orderid != 0 then
      if oh.orderstatus > '1' then
         out_errorno := 2;
         out_msg := 'Invalid Order Header Status (notes):' || oh.orderstatus ;
         order_msg('E');
         last_orderid := out_orderid;
         return;
      end if;
    end if;

    if rtrim(nvl(in_comment_type,'NONE')) = 'NONE' then
       if rtrim(in_func) in ('A','U','R') then
          if rtrim(in_func) in ('U','R') and nvl(last_orderid,0) != out_orderid then
             oh.comment1 := null;
             last_orderid := out_orderid;
          end if;
          if oh.comment1 is not null then
             cr := chr(13) || chr(10);
          else
             cr := null;
          end if;
          oh.comment1 := oh.comment1 || cr
                         || rtrim(in_qualifier)||'-'||rtrim(in_note);
          update orderhdr
             set comment1 = oh.comment1,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       elsif rtrim(in_func) = 'D' then
          update orderhdr
             set comment1 = null,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       end if;
    elsif rtrim(in_comment_type) in ('ORI','WHI') then
       if rtrim(in_func) in ('A','U','R') then
          if rtrim(in_func) in ('U','R') and nvl(last_orderid,0) != out_orderid then
             oh.comment1 := null;
             last_orderid := out_orderid;
          end if;
          if oh.comment1 is not null then
             cr := chr(13) || chr(10);
          else
             cr := null;
          end if;

          oh.comment1 := oh.comment1 || cr
                         || rtrim(in_note);
          update orderhdr
             set comment1 = oh.comment1,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       elsif rtrim(in_func) = 'D' then
          update orderhdr
             set comment1 = null,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       end if;
    elsif rtrim(in_comment_type) in ('DEL','BOL') then
       open C_ORDERHDRBOL(oh.orderid, oh.shipid);
       fetch C_ORDERHDRBOL into ohb;
       close C_ORDERHDRBOL;

       if rtrim(in_func) in ('A','U','R') then
          if ohb.orderid is not null then
             if rtrim(in_func) in ('U','R') and nvl(last_orderid,0) != out_orderid then
                ohb.bolcomment := null;
                last_orderid := out_orderid;
             end if;
             if ohb.bolcomment is not null then
                cr := chr(13) || chr(10);
             else
                cr := null;
             end if;

             ohb.bolcomment := ohb.bolcomment || cr
                            || rtrim(in_note);
             update orderhdrbolcomments
                set bolcomment = ohb.bolcomment,
                    lastuser = IMP_USERID,
                    lastupdate = sysdate
              where orderid = oh.orderid
                and shipid = oh.shipid;
          else
             insert into orderhdrbolcomments
             (orderid, shipid, bolcomment, lastuser, lastupdate)
             values
             (oh.orderid, oh.shipid, in_note, IMP_USERID, sysdate);
          end if;
       elsif rtrim(in_func) = 'D' then
          delete
            from orderhdrbolcomments
           where orderid = oh.orderid
             and shipid = oh.shipid;
       end if;
    elsif rtrim(in_comment_type) in ('OTH') then
       if rtrim(in_func) in ('A','U','R') then
          update orderhdr
             set hdrpassthruchar56 = in_note,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       elsif rtrim(in_func) = 'D' then
          update orderhdr
             set hdrpassthruchar56 = null,
                 lastuser = IMP_USERID,
                 lastupdate = sysdate
           where orderid = out_orderid
             and shipid = out_shipid;
       end if;
    end if;

    last_orderid := out_orderid;

exception when others then
  out_msg := 'zimohn ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_hdr_notes_Kraft;

end zimportprocs;
/
show error package body zimportprocs;
exit;

