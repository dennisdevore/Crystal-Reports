create or replace package body alps.zimportprocpecas as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPPECAS';

last_orderid    orderhdr.orderid%type;

FUNCTION scac_to_carrier
(in_scac    varchar2)
RETURN varchar2
IS
CURSOR C_CARR
IS
SELECT carrier
  FROM alps.carrier
 WHERE scac = in_scac;

    l_carr  varchar2(4);
BEGIN
    l_carr := NULL;

    OPEN C_CARR;
    FETCH C_CARR INTO l_carr;
    CLOSE C_CARR;

    return l_carr;

END scac_to_carrier;



procedure pecas_import_order_header
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
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         nvl(fromfacility,tofacility) facility,
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and nvl(hdrpassthruchar01,'None') =
            rtrim(nvl(in_hdrpassthruchar01,'None'))
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(resubmitorder,'N') as resubmitorder
    from customer
   where custid = rtrim(in_custid);
cs curCustomer%rowtype;

cntRows integer;
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

l_carr  varchar2(4);
l_shiptype varchar2(1);
l_shipterms varchar2(3);
l_del varchar2(3);

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
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
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

if nvl(in_hdrpassthruchar10,'XX') = 'PECAS' then
    l_carr := scac_to_carrier(upper(in_carrier));
    if upper(in_carrier) = 'UPSS' then
        l_shiptype := 'S';
        l_del := 'GRD';
    elsif upper(in_carrier) = 'FEDX' then
        l_shiptype := 'S';
        l_del := 'PRI';
    else
        l_shiptype := 'L';
    end if;

    if in_shipterms = '0' then
        l_shipterms := 'PPD';
    elsif in_shipterms = '1' then
        l_shipterms := 'COL';
    elsif in_shipterms = '2' then
        l_shipterms := '3RD';
    end if;
else
    l_carr := in_carrier;
    l_del := in_deliveryservice;
    l_shipterms := in_shipterms;
    l_shiptype := in_shiptype;
end if;

if nvl(rtrim(in_func),'x') not in ('A','U','D','R') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code';
  order_msg('E');
  return;
end if;

open curOrderhdr;
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
    out_msg := 'Update requested--order not on file--add performed';
    order_msg('W');
    in_func := 'A';
  else
    if (oh.orderstatus > '1' and oh.ordertype = 'O')
     or (oh.orderstatus in ('R','X') and oh.ordertype = 'P') then
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
  rtrim(in_tofacility),rtrim(in_shipto),rtrim(in_billoflading),
  rtrim(in_priority),rtrim(in_shipper),rtrim(in_consignee),rtrim(l_shiptype),
  rtrim(l_carr),rtrim(in_reference),rtrim(l_shipterms),rtrim(in_shippername),
  rtrim(in_shippercontact),
  rtrim(in_shipperaddr1),rtrim(in_shipperaddr2),rtrim(in_shippercity),
  rtrim(in_shipperstate),rtrim(in_shipperpostalcode),rtrim(in_shippercountrycode),
  rtrim(in_shipperphone),rtrim(in_shipperfax),rtrim(in_shipperemail),rtrim(in_shiptoname),
  rtrim(in_shiptocontact),
  rtrim(in_shiptoaddr1),rtrim(in_shiptoaddr2),rtrim(in_shiptocity),
  rtrim(in_shiptostate),rtrim(in_shiptopostalcode),rtrim(in_shiptocountrycode),
  rtrim(in_shiptophone),rtrim(in_shiptofax),rtrim(in_shiptoemail),
  rtrim(in_billtoname),rtrim(in_billtocontact),rtrim(in_billtoaddr1),rtrim(in_billtoaddr2),
  rtrim(in_billtocity),rtrim(in_billtostate),rtrim(in_billtopostalcode),
  rtrim(in_billtocountrycode),rtrim(in_billtophone),rtrim(in_billtofax),
  rtrim(in_billtoemail),IMP_USERID,sysdate,
  '0','0',IMP_USERID,sysdate,
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
  rtrim(l_del),
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
  in_rfautodisplay, dtedelivery_requested
  );
elsif rtrim(in_func) = 'U' then
  update orderhdr
     set orderstatus = decode(oh.ordertype,'P',oh.orderstatus,'0'),
         commitstatus = '0',
         apptdate = nvl(dteapptdate,apptdate),
         shipdate = nvl(dteShipDate,shipdate),
         shipto = nvl(rtrim(in_shipto),shipto),
         billoflading = nvl(rtrim(in_billoflading),billoflading),
         priority = nvl(rtrim(in_priority),priority),
         shipper = nvl(rtrim(in_shipper),shipper),
         consignee = nvl(rtrim(in_consignee),consignee),
         shiptype = nvl(rtrim(in_shiptype),shiptype),
         carrier = nvl(rtrim(l_carr),carrier),
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
         importfileid = nvl(upper(rtrim(in_importfileid)),importfileid),
         cancel_after = nvl(dtecancel_after,cancel_after),
         delivery_requested = nvl(dtedelivery_requested,delivery_requested),
         arrivaldate = nvl(dtedelivery_requested,arrivaldate),
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
         rfautodisplay = nvl(rtrim(in_rfautodisplay),rfautodisplay)
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
  order_msg('E');
end pecas_import_order_header;

procedure pecas_import_order_line
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
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
,in_hdrpassthruchar01 IN varchar2
,in_linenumbersyn IN varchar2
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
     and nvl(hdrpassthruchar01,'None') =
            rtrim(nvl(in_hdrpassthruchar01,'None'))
   order by orderstatus;
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
  select item,
         useramt1,
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
strLineNumbers char(1);
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

if (oh.orderstatus > '1' and oh.ordertype = 'O')
 or (oh.orderstatus in ('R','X') and oh.ordertype = 'P')
then
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
  if nvl(od.qtyrcvd,0) > 0 then
    out_errorno := 4;
    out_msg := 'Order-line already begun receipt';
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

if ( (oh.ordertype in ('O','V')) and (cs.linenumbersyn = 'Y') ) or
   ( (oh.ordertype in ('O','V')) and (nvl(in_linenumbersyn,'N') = 'Y') ) or
   ( (oh.ordertype in ('R','Q','C')) and (cs.recv_line_check_yn != 'N') ) then
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

ci := null;
open curCustItem(strItem);
fetch curCustItem into ci;
if curCustItem%notfound then
  ci.useramt1 := 0;
end if;
close curCustItem;
if ci.item is null then
    out_errorno := 5;
    out_msg := 'Order-line item not defined:'||strItem;
    item_msg('E');
    return;
end if;
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
    dtlpassthrunum09, dtlpassthrunum10,
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
     dtedtlpassthrudate01, dtedtlpassthrudate02,
     dtedtlpassthrudate03, dtedtlpassthrudate04,
     decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
     decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
     in_rfautodisplay
     );
	 
     -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
     -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
     update orderdtl
     set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = nvl(strItem,' ')
       and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
	 
     if cs.recv_line_check_yn != 'N' then
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
elsif rtrim(in_func) = 'U' then
  if (olc.count != 0) and
     (chk.linenumber is not null) then
    update orderdtlline
       set qty = qtyBase,
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
           amtorder = amtorder + (qtyBase - ol.qty) * zci.item_amt(custid,orderid,shipid,item,lotnumber),
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
           amtorder = qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber),
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
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziol ' || sqlerrm;
  out_errorno := sqlcode;
  item_msg('E');
end pecas_import_order_line;

procedure pecas_import_order_header_inst
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_instructions IN long
,in_hdrpassthruchar01 IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         ordertype,
         orderstatus,
         fromfacility,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and nvl(hdrpassthruchar01,'None') =
            rtrim(nvl(in_hdrpassthruchar01,'None'))
   order by orderstatus;
oh curOrderHdr%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
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

if out_orderid != 0 then
  if (oh.orderstatus > '1' and oh.ordertype = 'O')
   or (oh.orderstatus in ('R','X') and oh.ordertype = 'P') then
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
  update orderhdr
     set comment1 = rtrim(in_instructions),
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
end pecas_import_order_header_inst;


----------------------------------------------------------------------
-- Pecas_import_order_hdr_notes
----------------------------------------------------------------------
procedure pecas_import_order_hdr_notes
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
IS

cursor C_ORDERHDR is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         tofacility,
         comment1
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
   order by orderstatus;
oh C_ORDERHDR%rowtype;

cr varchar2(2);

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
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


    if nvl(rtrim(in_func),'x') not in ('A','U','D') then
       out_errorno := 1;
       out_msg := 'Invalid Function Code';
       order_msg('E');
       return;
    end if;

    open C_ORDERHDR;
    fetch C_ORDERHDR into oh;
    if C_ORDERHDR%FOUND then
       out_orderid := oh.orderid;
       out_shipid := oh.shipid;
    end if;
    close C_ORDERHDR;

    if out_orderid = 0 then
       out_errorno := 3;
       out_msg := 'Cannot import instructions--order not found';
       order_msg('E');
       return;
    end if;


    if out_orderid != 0 then
      if oh.orderstatus > '0' then
         out_errorno := 2;
         out_msg := 'Invalid Order Header Status (notes):' || oh.orderstatus ;
         order_msg('E');
         last_orderid := out_orderid;
         return;
      end if;
    end if;


    if rtrim(in_func) in ('A','U') then
       if rtrim(in_func) = 'U' and nvl(last_orderid,0) != out_orderid then
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

    last_orderid := out_orderid;

exception when others then
  out_msg := 'zimohn ' || sqlerrm;
  out_errorno := sqlcode;
end pecas_import_order_hdr_notes;



procedure pecas_import_mail_list
(in_func IN OUT varchar2
,in_facility IN varchar2
,in_custid IN varchar2
,in_pecas_ref IN varchar2
,in_sales_order_no IN varchar2
,in_job_name IN varchar2
,in_job_no IN varchar2
,in_string_no IN varchar2
,in_lot_no  IN varchar2
,in_item IN varchar2
,in_entry_name IN varchar2
,in_entry_zip IN varchar2
,in_comments IN varchar2
,in_skidno IN number
,in_total_skid IN number
,in_sack_range IN varchar2
,in_skid_vol IN number
,in_skid_weight IN number
,in_skid_quantity IN number
,in_total_sack IN number
,in_load_no IN number
,in_cnt_type IN varchar2
,in_ship_date IN date
,in_delivery_date IN date
,in_importfileid IN varchar2
,in_carrier IN varchar2
,in_entry_level IN varchar2
,in_entry_city IN varchar2
,in_entry_state IN varchar2
,in_entry_zip2 IN varchar2
,in_entry_address IN varchar2
,in_truck IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         nvl(fromfacility,tofacility) facility,
         ordertype,
         comment1
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_sales_order_no)
     and nvl(hdrpassthruchar01,'None') =
            rtrim(nvl(in_pecas_ref,'None'))
     and nvl(hdrpassthruchar04,'None') =
            rtrim(nvl(in_string_no,'None'))
     and shiptoname = rtrim(in_entry_name)
     and shiptopostalcode = rtrim(in_entry_zip)
     and ordertype = 'O'
   order by orderstatus;
oh curOrderHdr%rowtype;

dteShipDate date;
dtedelivery_requested date;

cursor curOrderDtl is
  select *
    from orderdtl
   where orderid = out_orderid
     and shipid = out_shipid
     and itementered = rtrim(in_item)
     and nvl(lotnumber,'(none)') = '(none)';
od curOrderDtl%rowtype;

cursor curCustItem(in_item varchar2) is
  select item,
         useramt1,
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

l_lpid alps.plate.lpid%type;
errmsg varchar2(255);

l_carr  varchar2(4);
l_shiptype varchar2(1);

sqlcode  varchar2(3000);

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
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_sales_order_no) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, in_facility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;



BEGIN

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

l_carr := scac_to_carrier(upper(in_carrier));
if upper(in_carrier) in ('USPS','MFRG','MDLS') then
    l_shiptype := 'M';
else
    l_shiptype := 'L';
end if;

if nvl(rtrim(in_func),'x') not in ('A') then
  out_errorno := 1;
  out_msg := 'Invalid Function Code'||' Truck='||in_truck||'<<'||length(in_truck)||' Job'||in_job_no;
  order_msg('E');
  return;
end if;

oh := null;
open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
    out_orderid := oh.orderid;
    out_shipid := oh.shipid;
    in_func := 'U';
end if;
close curOrderhdr;

if oh.orderid is not null then
    if rtrim(in_func) in ('A','U')
    and oh.orderstatus = 'X' then
        out_errorno := 5;
        out_msg := 'Order has been cancelled.';
        order_msg('E');
        return;
    end if;
    if rtrim(in_func) in ('A','U')
    and oh.orderstatus > '4' then
        out_errorno := 6;
        out_msg := 'Order has begun picking.';
        order_msg('E');
        return;
    end if;
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
  if trunc(in_ship_date) = to_date('12/30/1899','mm/dd/yyyy') then
    dteShipDate := null;
  else
    dteShipDate := in_ship_date;
  end if;
exception when others then
  dteShipDate := null;
end;

begin
  if trunc(in_delivery_date) = to_date('12/30/1899','mm/dd/yyyy') then
    dtedelivery_requested := null;
  else
    dtedelivery_requested := in_delivery_date;
  end if;
exception when others then
  dtedelivery_requested := null;
end;




if out_orderid = 0 then
  zoe.get_next_orderid(out_orderid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 4;
    order_msg('E');
    return;
  end if;
  out_shipid := 1;
end if;




if rtrim(in_func) in ('A') then
  insert into orderhdr
  (orderid,shipid,custid,ordertype,shipdate,priority,
   fromfacility,
   shiptype,carrier,reference,shipterms,
   shiptoname,
   shiptoaddr1,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   lastuser,lastupdate,
   orderstatus,commitstatus,statususer,entrydate,
   hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03, hdrpassthruchar04,
   hdrpassthruchar05, hdrpassthruchar06, hdrpassthruchar07, hdrpassthruchar08,
   hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11, hdrpassthruchar12,
   hdrpassthruchar13, hdrpassthruchar14, hdrpassthruchar15, hdrpassthruchar16,
   hdrpassthruchar17, hdrpassthruchar18, hdrpassthruchar19, hdrpassthruchar20,
    source,
    delivery_requested,
    arrivaldate,
    importfileid
   )
  values
  (out_orderid,out_shipid,nvl(rtrim(in_custid),' '),'O',
  dteShipDate,'N',rtrim(in_facility),
  l_shiptype, -- ShipType
  l_carr, -- carrier from scac code
   rtrim(in_sales_order_no),
  'PPD',
  rtrim(in_entry_name),
  rtrim(in_entry_address),
  rtrim(in_entry_city),
  rtrim(in_entry_state),
  rtrim(in_entry_zip),
  IMP_USERID,sysdate,
  '0','0',IMP_USERID,sysdate,
  -- HPTC
  rtrim(in_pecas_ref),rtrim(in_job_name),
  rtrim(in_job_no),rtrim(in_string_no),
  rtrim(in_lot_no),null,
  null,null,
  null,'PECAS',
  null,null,
  null,rtrim(in_truck),
  null,null,
  null,null,
  null,null,
  'EDI',
  dtedelivery_requested,
  dtedelivery_requested,
  upper(rtrim(in_importfileid))
  );
end if;

if rtrim(in_comments) is not null and oh.comment1 is null then
  update orderhdr
     set comment1 = rtrim(in_comments),
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
end if;


od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;

ci := null;
open curCustItem(rtrim(in_item));
fetch curCustItem into ci;
close curCustItem;

if ci.item is null then
    out_errorno := 4;
    out_msg := 'Item not found:'||in_custid||'/'||in_item;
    order_msg('E');
    return;

end if;


if od.item is null then

    insert into orderdtl
    (orderid,shipid,item,lotnumber,uom,linestatus,qtyentered,itementered,uomentered,
    qtyorder,weightorder,cubeorder,amtorder,
    lastuser,lastupdate,
    backorder,allowsub,
    qtytype,invstatusind,invstatus,invclassind,
    inventoryclass,statususer
    )
    values
    (out_orderid,out_shipid, rtrim(in_item),null,'PCS','A',
     in_skid_quantity,rtrim(in_item), 'PCS',
     in_skid_quantity,
     in_skid_weight,
     in_skid_vol,
     in_skid_quantity*ci.useramt1,IMP_USERID,sysdate,
     ci.backorder,ci.allowsub,
     ci.qtytype,ci.invstatusind,
     ci.invstatus,ci.invclassind,
     ci.inventoryclass,
     IMP_USERID
     );
else
    update orderdtl
       set qtyentered = qtyentered + in_skid_quantity,
           qtyorder = qtyorder + in_skid_quantity,
           weightorder = weightorder + in_skid_weight,
           cubeorder = cubeorder + in_skid_vol,
           amtorder = amtorder + in_skid_quantity * zci.item_amt(custid,orderid,shipid,item,lotnumber),
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where orderid = out_orderid
       and shipid = out_shipid
       and itementered = rtrim(in_item);

end if;


-- Add Load_flag Information
zrf.get_next_lpid(l_lpid, errmsg);

/*
insert into load_flag_hdr(type, jobno,custid,lpid,status,
            skidno, total_skid, created, sack_range,
            skid_vol, skid_weight, total_sack, load_no,
            cnt_type)
    values( 'M', in_job_no, in_custid, l_lpid, 'NEW',
            in_skidno, in_total_skid, sysdate,in_sack_range,
            in_skid_vol, in_skid_weight, in_total_sack, in_load_no,
            in_cnt_type);

insert into load_flag_dtl (lpid, orderid, shipid, item, pieces,
            quantity)
    values (l_lpid, out_orderid, out_shipid, in_item, in_skid_quantity,
            1);
*/

-- This is done indirectly so PECAS user is not needed for processing
sqlcode :=
'insert into load_flag_hdr(type, facility, jobno,custid,
            lpid,status,
            skidno, total_skid, created, sack_range,
            skid_vol, skid_weight, total_sack, load_no,
            cnt_type)
    values( ''M'', :in_facility, :in_sales_order_no, :in_custid,
            :l_lpid, ''NEW'',
            :in_skidno, :in_total_skid, sysdate,:in_sack_range,
            :in_skid_vol, :in_skid_weight, :in_total_sack, :in_load_no,
            :in_cnt_type)';


        execute immediate sqlcode using
            in_facility, in_sales_order_no, in_custid, l_lpid,
            in_skidno, in_total_skid, in_sack_range,
            in_skid_vol, in_skid_weight, in_total_sack, in_load_no,
            in_cnt_type ;

sqlcode :=
'insert into load_flag_dtl (lpid, orderid, shipid, item, pieces,
            quantity)
    values (:l_lpid, :out_orderid, :out_shipid, :in_item, :in_skid_quantity,
            1)';

        execute immediate sqlcode using
                l_lpid, out_orderid, out_shipid, in_item, in_skid_quantity;


update orderhdr
   set orderstatus = '4',
       statusupdate = sysdate,
       statususer = IMP_USERID
 where orderid = out_orderid
   and shipid = out_shipid;



EXCEPTION WHEN OTHERS THEN
  out_msg := 'PIML: ' || sqlerrm;
  out_errorno := sqlcode;

END pecas_import_mail_list;



----------------------------------------------------------------------
--
-- order_skids
--
----------------------------------------------------------------------
FUNCTION order_skids
(
    in_orderid      number,
    in_shipid       number
)
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.orderid = in_orderid
      and S.shipid = in_shipid
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and shiptype != 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END order_skids;

----------------------------------------------------------------------
--
-- order_cartons
--
----------------------------------------------------------------------
FUNCTION order_cartons
(
    in_orderid      number,
    in_shipid       number
)
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.orderid = in_orderid
      and S.shipid = in_shipid
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and shiptype = 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END order_cartons;


----------------------------------------------------------------------
--
-- order_weight
--
----------------------------------------------------------------------
FUNCTION order_weight
(
    in_orderid      number,
    in_shipid       number
)
RETURN number
IS
wt number;

BEGIN

    select sum(nvl(S.weight,0))
      into wt
     from alps.shippingplate S
    where S.orderid = in_orderid
      and S.shipid = in_shipid
      and S.parentlpid is null;
      -- and type in ('C');


    return nvl(wt,0);
EXCEPTION WHEN OTHERS THEN
    return 0;
END order_weight;

----------------------------------------------------------------------
--
-- lss_skids
--
----------------------------------------------------------------------
FUNCTION lss_skids
(
    in_loadno       number,
    in_stopno       number,
    in_shipno       number
)
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.loadno = in_loadno
      and S.stopno = in_stopno
      and S.shipno = in_shipno
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and shiptype != 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END lss_skids;

----------------------------------------------------------------------
--
-- lss_cartons
--
----------------------------------------------------------------------
FUNCTION lss_cartons
(
    in_loadno       number,
    in_stopno       number,
    in_shipno       number
)
RETURN number
IS
cnt integer;

BEGIN

    cnt := 0;
    select count(1)
      into cnt
     from alps.shippingplate S, alps.orderhdr O
    where S.loadno = in_loadno
      and S.stopno = in_stopno
      and S.shipno = in_shipno
      and O.orderid = S.orderid
      and O.shipid = S.shipid
      and shiptype = 'S';



    return cnt;
EXCEPTION WHEN OTHERS THEN
    return 0;
END lss_cartons;


----------------------------------------------------------------------
--
-- lss_weight
--
----------------------------------------------------------------------
FUNCTION lss_weight
(
    in_loadno       number,
    in_stopno       number,
    in_shipno       number
)
RETURN number
IS
wt number;

BEGIN

    select sum(nvl(S.weight,0))
      into wt
     from alps.shippingplate S
    where S.loadno = in_loadno
      and S.stopno = in_stopno
      and S.shipno = in_shipno
      and type in ('F','P');

    return nvl(wt,0);
EXCEPTION WHEN OTHERS THEN
    return 0;
END lss_weight;


----------------------------------------------------------------------
--
-- pecas_import_order_from_SS
--
----------------------------------------------------------------------
procedure pecas_import_order_from_SS
(in_func IN OUT varchar2
,in_check IN varchar2
,in_cust_ref IN varchar2
,in_sales_order_no IN varchar2
,in_order_line_no IN varchar2
,in_item_code IN varchar2
,in_seq_no IN varchar2
,in_quantity IN varchar2
,in_ship_date  IN varchar2
,in_delivery_date IN varchar2
,in_ship_terms IN varchar2
,in_shiptoname IN varchar2
,in_shiptocontact IN varchar2
,in_shiptoaddr1 IN varchar2
,in_shiptoaddr2 IN varchar2
,in_shiptocity IN varchar2
,in_shiptostate IN varchar2
,in_shiptopostalcode IN varchar2
,in_carrier IN varchar2
,in_product_code IN varchar2
,in_label1 IN varchar2
,in_label2 IN varchar2
,in_spec_instr1 IN varchar2
,in_spec_instr2 IN varchar2
,in_hdrpassthruchar12 IN varchar2
,in_hdrpassthruchar15 IN varchar2
,in_hdrpassthruchar16 IN varchar2
,in_hdrpassthruchar17 IN varchar2
,in_hdrpassthruchar18 IN varchar2
,in_hdrpassthruchar19 IN varchar2
,in_hdrpassthruchar20 IN varchar2
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
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
IS

cnt number;

l_shipdate date;
l_delvdate date;

l_qty   number;
l_seq   number;

l_sales_order number;
l_order_line number;

l_terms varchar2(3);

l_postalcode orderhdr.shiptopostalcode%type;

CURSOR C_PRODORD(in_jobno varchar2)
IS
SELECT *
  FROM orderhdr
 WHERE reference = in_jobno
   AND ordertype = 'P';

PORD orderhdr%rowtype;

CURSOR C_ORD(in_custid varchar2,
             in_ref varchar2,
             in_pecas_ref varchar2)
IS
SELECT *
  FROM orderhdr
 WHERE custid = in_custid
   AND reference = in_ref
   AND nvl(hdrpassthruchar01,'None') =
            rtrim(nvl(in_pecas_ref,'None'));

ORD orderhdr%rowtype;

l_pecas_ref varchar2(50);

l_func varchar2(1);
l_plant varchar2(4);


procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  if in_check = 'Check Only' then
    return;
  end if;

  out_msg := 'Sales Order. ' || rtrim(in_sales_order_no)
    ||' Sequence:'||in_seq_no || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, PORD.tofacility, rtrim(PORD.custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

BEGIN
    out_errorno := 0;
    out_msg := '';
    out_orderid := 0;
    out_shipid := 0;

-- Setup Pecas Ref
    l_pecas_ref :=  in_sales_order_no
                ||  in_order_line_no
                ||  in_item_code
                ||  in_seq_no;

-- Verify function
    if nvl(upper(in_func),'XX') not in ('ADD','UPDATE','CANCEL') then
        out_errorno := 4;
        out_msg := 'Amendment must be add, update, or cancel';
        order_msg('E');
        return;
    end if;

-- Verify cust_ref
    if in_cust_ref is null then
        out_errorno := 4;
        out_msg := 'Customer reference (PO) must be provided';
        order_msg('E');
        return;
    end if;


-- Verify sales_order_no
    begin
        l_sales_order := to_number(in_sales_order_no);
    exception when others then
        out_errorno := 4;
        out_msg := 'Sales order must be a number';
        order_msg('E');
        return;
    end;

    if length(in_sales_order_no) != 6 then
        out_errorno := 4;
        out_msg := 'Sales order must be six digits';
        order_msg('E');
        return;
    end if;

-- Check for the corresponding production order
    cnt := 0;
    select count(1)
      into cnt
      from orderhdr
     where reference = in_sales_order_no || '/001'
       and ordertype = 'P';

    if cnt > 1 then
        out_errorno := 4;
        out_msg := 'Multiple production orders found for '
                ||in_sales_order_no||'/001';
        order_msg('E');
        return;
    end if;

    PORD := null;

    OPEN C_PRODORD(in_sales_order_no||'/001');
    FETCH C_PRODORD into PORD;
    CLOSE C_PRODORD;

    if PORD.orderid is null then
        out_errorno := 4;
        out_msg := 'No production order found for '
                ||in_sales_order_no||'/001';
        order_msg('E');
        return;
    end if;

-- Verify order_line_no
    begin
        l_order_line := to_number(nvl(in_order_line_no,'x'));
    exception when others then
        out_errorno := 4;
        out_msg := 'Order line number must be a number';
        order_msg('E');
        return;
    end;


-- Verify item_code
    if substr(in_item_code,1,6) != in_sales_order_no then
        out_errorno := 4;
        out_msg := 'Item code must begin with the Sales Order Number';
        order_msg('E');
        return;
    end if;

    if substr(in_item_code,7) not like '/L___' then
        out_errorno := 4;
        out_msg := 'Item code format must be 999999/L999';
        order_msg('E');
        return;
    end if;

    declare l_num integer;
    begin
        l_num := to_number(substr(in_item_code,9));
    exception when others then
        out_errorno := 4;
        out_msg := 'Item code format must be 999999/L999';
        order_msg('E');
        return;
    end;

    cnt := 0;
    select count(1)
      into cnt
      from custitem
     where custid = PORD.custid
       and item = in_item_code;

    if cnt = 0 then
        out_errorno := 4;
        out_msg := 'Item does not exist.';
        order_msg('E');
        return;
    end if;

    cnt := 0;
    select count(1)
      into cnt
      from orderdtl
     where orderid = PORD.orderid
       and shipid = PORD.shipid
       and item = in_item_code
       and lotnumber is null;

    if cnt != 1 then
        out_errorno := 4;
        out_msg := 'Item not part of production order.';
        order_msg('E');
        return;
    end if;

-- Verify seq_no
    if in_seq_no is null then
        out_errorno := 3;
        out_msg := 'Sequence must be provided';
        order_msg('E');
        return;
    end if;

    begin
        l_seq := to_number(in_seq_no);
    exception when others then
        out_errorno := 4;
        out_msg := 'Sequence must be a number';
        order_msg('E');
        return;
    end;



-- Verify quantity
    if in_quantity is null then
        out_errorno := 3;
        out_msg := 'Quantity must be provided';
        order_msg('E');
        return;
    end if;

    begin
        l_qty := to_number(in_quantity);
    exception when others then
        out_errorno := 4;
        out_msg := 'Quantity must be a number';
        order_msg('E');
        return;
    end;

-- Verify ship_date
    if in_ship_date is null then
            l_shipdate := null;
    else
      begin
        l_shipdate := to_date(in_ship_date, 'MM/DD/YYYY');
      exception when others then
        out_errorno := 1;
        out_msg := 'Invalid format for ship date.';
        order_msg('E');
        return;
      end;
    end if;

-- Verify delivery_date
    if in_delivery_date is null then
            l_delvdate := null;
    else
      begin
        l_delvdate := to_date(in_delivery_date, 'MM/DD/YYYY');
      exception when others then
        out_errorno := 2;
        out_msg := 'Invalid format for delivery date.';
        order_msg('E');
        return;
      end;
    end if;

-- Need some date
    if l_delvdate is null and l_shipdate is null then
        out_errorno := 2;
        out_msg := 'Must provide ship date or delivery date.';
        order_msg('E');
        return;
    end if;

-- Verify ship_terms
    if in_ship_terms is null then
        out_errorno := 3;
        out_msg := 'Ship terms must be provided';
        order_msg('E');
        return;
    end if;

    if upper(in_ship_terms) = 'PREPAID' then
        l_terms := '0'; -- PPD
    elsif upper(in_ship_terms) = 'COLLECT' then
        l_terms := '1'; -- COL
    elsif upper(in_ship_terms) = 'CUSTOMER' then
        l_terms := '2'; -- 3RD
    else
        out_errorno := 4;
        out_msg := 'Ship terms must be Prepaid, Collect or Customer';
        order_msg('E');
        return;
    end if;



-- verify shiptoname
    if in_shiptoname is null then
        out_errorno := 3;
        out_msg := 'Ship to name must be provided';
        order_msg('E');
        return;
    end if;

-- Verify shiptocontact
-- Verify shiptoaddr1
    if in_shiptoaddr1 is null then
        out_errorno := 3;
        out_msg := 'Ship to address must be provided';
        order_msg('E');
        return;
    end if;
-- Verify shiptoaddr2
-- Verify shiptocity
    if in_shiptocity is null then
        out_errorno := 3;
        out_msg := 'Ship to city must be provided';
        order_msg('E');
        return;
    end if;
-- Verify shiptostate
    if in_shiptostate is null then
        out_errorno := 3;
        out_msg := 'Ship to state must be provided';
        order_msg('E');
        return;
    end if;

    cnt := 0;
    select count(1)
      into cnt
     from stateorprovince
    where code = upper(in_shiptostate);
    if cnt = 0 then
        out_errorno := 3;
        out_msg := 'Ship to state is not valid';
        order_msg('E');
        return;
    end if;

-- Verify shiptopostalcode
    if in_shiptopostalcode is null then
        out_errorno := 3;
        out_msg := 'Ship to postal code must be provided';
        order_msg('E');
        return;
    end if;

    l_postalcode := in_shiptopostalcode;

    if length(l_postalcode) in (3,6) then
        l_postalcode := '00' || l_postalcode;
    elsif length(l_postalcode) in (4,7) then
        l_postalcode := '0' || l_postalcode;
    end if;

-- Verify carrier
    if in_carrier is not null then

        cnt := 0;
        select count(1)
          into cnt
         from carrier
        where scac = upper(in_carrier);
        if cnt = 0 then
            out_errorno := 3;
            out_msg := 'Carrier is not valid';
        order_msg('E');
            return;
        end if;

    end if;

-- Verify product_code
-- Verify label1
-- Verify label2
-- Verify spec_instr1
-- Verify spec_instr2

-- Check Shipment existance
    ORD := null;
    OPEN C_ORD(PORD.custid, in_sales_order_no, l_pecas_ref);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null and in_func in ('update','cancel') then
        out_errorno := 3;
        out_msg := 'Shipment Order does not exist';
        order_msg('E');
        return;
    end if;

    if ORD.orderid is not null and in_func in ('add') then
        out_errorno := 3;
        out_msg := 'Shipment Order already exists';
        order_msg('E');
        return;
    end if;

-- In theory if we got this far everything is OK so call routines to add
-- The order information
    if in_check = 'Check Only' then
        return;
    end if;

-- Add/Update/Cancel the shipment order

    -- pecas.zpecas.update_customer(ES.customer);
   -- Add order or update it

    if nvl(upper(in_func),'XX') = 'ADD' then
        l_func := 'A';
    elsif nvl(upper(in_func),'XX') = 'UPDATE' then
        l_func := 'R';
    elsif nvl(upper(in_func),'XX') = 'CANCEL' then
        l_func := 'D';
    else
        l_func := 'R';
    end if;

    if PORD.tofacility = '001' then
        l_plant := '1001';
    elsif PORD.tofacility = '002' then
        l_plant := '1002';
    else
        l_plant := '1001';
    end if;


    zimppecas.pecas_import_order_header(
        l_func,PORD.custid,'O',null, l_shipdate, in_cust_ref, null,
        PORD.tofacility, null, null, null, 'N',
        null,null,'L', upper(in_carrier),in_sales_order_no,
        l_terms,
        null,null,null,null,null,null,null,null,null,null,null,
        in_shiptoname,in_shiptocontact,in_shiptoaddr1,in_shiptoaddr2,
        in_shiptocity, upper(in_shiptostate), l_postalcode,
        'USA',null,null,null,
        null,null,null,null,null,null,null,null,null,null,null,
        null,null,null,null,null,null,null,null,null,
 -- PTC01
        l_pecas_ref,null,null,null,null,
            in_label1,in_label2,in_spec_instr1,in_spec_instr2,
            'PECAS',
        in_product_code,in_hdrpassthruchar12,l_plant,null,
            in_hdrpassthruchar15,in_hdrpassthruchar16,
            in_hdrpassthruchar17,in_hdrpassthruchar18,
            in_hdrpassthruchar19,in_hdrpassthruchar20,

        null,null,
            in_hdrpassthrunum03,in_hdrpassthrunum04,in_hdrpassthrunum05,
            in_hdrpassthrunum06,in_hdrpassthrunum07,in_hdrpassthrunum08,
            in_hdrpassthrunum09,in_hdrpassthrunum10,

        null,l_delvdate,null,null,null,null,null,null,
        in_hdrpassthrudate01,in_hdrpassthrudate02,
        in_hdrpassthrudate03,in_hdrpassthrudate04,
        in_hdrpassthrudoll01,in_hdrpassthrudoll02,
        null,null,
        out_orderid, out_shipid, out_errorno, out_msg
    );

    -- If fails send response
    if out_errorno <> 0 then
        return;
    end if;

    if l_func = 'D' then
        return;
    end if;

    l_func := 'R';

    zimppecas.pecas_import_order_line(
            l_func,PORD.custid,in_sales_order_no,in_item_code,null,'PCS',
            l_qty,null,null,null,
            null,null,null,null,in_product_code,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,l_pecas_ref,'N',
            out_orderid, out_shipid, out_errorno, out_msg
    );



END;



----------------------------------------------------------------------
--
-- prod_import_order_hdr
--
----------------------------------------------------------------------
procedure prod_import_order_hdr
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
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
BEGIN

    pecas_import_order_header
    (in_func
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
    ,out_orderid
    ,out_shipid
    ,out_errorno
    ,out_msg
    );

END;

----------------------------------------------------------------------
--
-- prod_import_order_line
--
----------------------------------------------------------------------
procedure prod_import_order_line
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
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
,in_hdrpassthruchar01 IN varchar2
,in_linenumbersyn IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
BEGIN

    pecas_import_order_line
    (in_func
    ,in_custid
    ,in_reference
    ,in_itementered
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
    ,in_dtlpassthrudate01
    ,in_dtlpassthrudate02
    ,in_dtlpassthrudate03
    ,in_dtlpassthrudate04
    ,in_dtlpassthrudoll01
    ,in_dtlpassthrudoll02
    ,in_rfautodisplay
    ,in_hdrpassthruchar01
    ,in_linenumbersyn
    ,out_orderid
    ,out_shipid
    ,out_errorno
    ,out_msg
    );

END;


----------------------------------------------------------------------
--
-- prod_import_order_notes
--
----------------------------------------------------------------------
procedure prod_import_order_hdr_notes
(in_func IN OUT varchar2
,in_custid IN varchar2
,in_reference IN varchar2
,in_hdrpassthruchar01 IN varchar2
,in_qualifier IN varchar2
,in_note  IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
IS
BEGIN

    pecas_import_order_hdr_notes
    (in_func
    ,in_custid
    ,in_reference
    ,in_hdrpassthruchar01
    ,in_qualifier
    ,in_note
    ,out_orderid
    ,out_shipid
    ,out_errorno
    ,out_msg
    );

END;

----------------------------------------------------------------------
--
-- prod_process_orders
--
----------------------------------------------------------------------
procedure prod_process_orders
(
in_importfileid IN      varchar2,
in_exportmap    IN      varchar2,
in_userid       IN      varchar2,
out_errorno     IN OUT  number,
out_msg         IN OUT  varchar2
)
IS


BEGIN

    out_errorno := 0;
    out_msg := '';

-- Verify customer

-- Remove orders from hold
    for crec in (select orderid, shipid
                   from orderhdr
                  where importfileid = rtrim(upper(in_importfileid)))
    loop

        zimp.release_and_commit_order(crec.orderid, crec.shipid,
                out_errorno, out_msg);

    end loop;

-- Send request for export of file to digital press

    if rtrim(in_exportmap) is not null then
        ziem.impexp_request('E',null,null,
          in_exportmap,upper(in_importfileid),'NOW',
          0,0,0,in_userid,null,null,'importfileid',null,null,
          null,null,out_errorno,out_msg);
    end if;

EXCEPTION WHEN OTHERS THEN
  out_msg := 'ppdo ' || sqlerrm;
  out_errorno := sqlcode;
END prod_process_orders;



end zimportprocpecas;
/
exit;

