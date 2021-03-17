create or replace package body alps.zimportproc3 as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure import_asn_item
(in_custid IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_tofacility IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
,in_importfileid IN varchar2
,in_trackingno IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_serialnumber IN varchar2
,in_useritem1 IN varchar2
,in_useritem2 IN varchar2
,in_useritem3 IN varchar2
,in_inventoryclass IN varchar2
,in_uom IN varchar2
,in_quantity IN number
,in_custreference varchar2
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
,in_dtlcomment IN varchar2
,in_expdate IN date
,in_weight IN number
,in_outbound_consignee IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrType is
  select orderid,
         shipid,
         orderstatus,
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and ordertype = rtrim(nvl(in_ordertype,'R'))
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select status, nvl(paperbased,'N') as paperbased,
         nvl(recv_line_check_yn,'N') as recv_line_check_yn,
        unique_order_identifier,
         nvl(dup_reference_ynw,'N') as dup_reference_ynw
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;

cursor curFacility is
  select facilitystatus
    from facility
   where facility = in_tofacility;
fa curFacility%rowtype;

cursor curOrderPriority is
  select abbrev
    from orderpriority
   where code = in_priority;
op curOrderPriority%rowtype;

cursor curShipper is
  select shipperstatus
    from shipper
   where shipper = in_shipper;
sh curShipper%rowtype;

cursor curCarrier is
  select Carrierstatus
    from Carrier
   where Carrier = in_Carrier;
ca curCarrier%rowtype;

cursor curCustItem(in_item varchar2) is
  select useramt1,
         backorder,
         allowsub,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtytype,
         baseuom,
         lotrequired,
         serialrequired,
         user1required,
         user2required,
         user3required
    from custitemview
   where custid = rtrim(in_custid)
     and item = rtrim(in_item);
ci curCustItem%rowtype;

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

cursor c_cons(p_consignee varchar2) is
   select shiptype, shipterms
      from consignee
      where consignee = p_consignee;
cons c_cons%rowtype := null;

cntRows integer;
chk orderdtlline%rowtype;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;
dteexpdate date;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
strLineNumbers char(1);

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
  zms.log_msg(IMP_USERID, in_tofacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if rtrim(in_custid) is null then
  out_errorno := 11;
  out_msg := 'Customer ID is required';
  order_msg('E');
  return;
end if;

cs := null;
open curCustomer;
fetch curCustomer into cs;
close curCustomer;
if cs.status is null then
  out_errorno := 12;
  out_msg := 'Invalid Customer ID:' || in_custid;
  order_msg('E');
  return;
end if;

if cs.dup_reference_ynw = 'O' then
   open curOrderhdrType;
   fetch curOrderhdrType into oh;
   if curOrderHdrType%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrType;
else
   open curOrderhdr;
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if rtrim(in_ordertype) is not null then
  if in_ordertype not in ('R','Q','C') then
    out_errorno := 1;
    out_msg := 'Invalid Order Type: ' || in_ordertype;
    order_msg('E');
    return;
  end if;
  if in_ordertype = 'C' then
    if cs.paperbased = 'Y' then
      out_errorno := 13;
      out_msg := 'Crossdock order not allowed for Aggregate Inventory customer';
      order_msg('E');
      return;
    end if;
    if rtrim(in_outbound_consignee) is null then
      out_errorno := 14;
      out_msg := 'Outbound consignee required for Crossdock order';
      order_msg('E');
      return;
    end if;
    select count(1)
      into cntRows
      from custconsignee
     where custid = rtrim(in_custid)
       and consignee = rtrim(in_outbound_consignee);
    if cntRows = 0 then
      out_errorno := 15;
      out_msg := 'Outbound consignee '||in_outbound_consignee||' not associated with customer '
          ||in_custid;
      order_msg('E');
      return;
    end if;
  end if;
end if;

if rtrim(in_tofacility) is not null then
  fa := null;
  open curFacility;
  fetch curFacility into fa;
  close curFacility;
  if fa.facilitystatus is null then
    out_errorno := 2;
    out_msg := 'Invalid To Facility: ' || in_tofacility;
    order_msg('E');
    return;
  end if;
end if;

if rtrim(in_priority) is not null then
  op := null;
  open curOrderPriority;
  fetch curOrderPriority into op;
  close curOrderPriority;
  if op.abbrev is null then
    out_errorno := 3;
    out_msg := 'Invalid Order Priority: ' || in_priority;
    order_msg('E');
    return;
  end if;
end if;

if rtrim(in_shipper) is not null then
  sh := null;
  open curShipper;
  fetch curShipper into sh;
  close curShipper;
  if sh.shipperstatus is null then
    out_errorno := 4;
    out_msg := 'Invalid Shipper: ' || in_shipper;
    order_msg('E');
    return;
  end if;
end if;

if rtrim(in_Carrier) is not null then
  ca := null;
  open curCarrier;
  fetch curCarrier into ca;
  close curCarrier;
  if ca.carrierstatus is null then
    out_errorno := 4;
    out_msg := 'Invalid Carrier: ' || in_Carrier;
    order_msg('E');
    return;
  end if;
end if;

if out_orderid <> 0 then
  if oh.ordertype not in ('R','Q','C') then
    out_errorno := 3;
    out_msg := 'Not an Inbound Order: ' || oh.ordertype;
    order_msg('E');
    return;
  end if;
  if oh.orderstatus > '1' then
    out_errorno := 4;
    out_msg := 'Invalid Order Status: ' || oh.orderstatus;
    order_msg('E');
    return;
  end if;
  update orderhdr
     set ordertype = nvl(rtrim(in_ordertype),ordertype),
         apptdate = nvl(in_apptdate,apptdate),
         po = nvl(rtrim(in_po),po),
         rma = nvl(rtrim(in_rma),rma),
         tofacility = nvl(rtrim(in_tofacility),tofacility),
         billoflading = nvl(rtrim(in_billoflading),billoflading),
         priority = nvl(rtrim(in_priority),priority),
         shipper = nvl(rtrim(in_shipper),shipper),
         carrier = nvl(rtrim(in_carrier),carrier),
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
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
else
  zoe.get_next_orderid(out_orderid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 4;
    order_msg('E');
    return;
  end if;
  out_shipid := 1;
  insert into orderhdr
  (orderid,shipid,custid,ordertype,apptdate,po,rma,
   tofacility,billoflading,priority,shipper,
   carrier,reference,
   orderstatus,commitstatus,statususer,entrydate,
   hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03, hdrpassthruchar04,
   hdrpassthruchar05, hdrpassthruchar06, hdrpassthruchar07, hdrpassthruchar08,
   hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11, hdrpassthruchar12,
   hdrpassthruchar13, hdrpassthruchar14, hdrpassthruchar15, hdrpassthruchar16,
   hdrpassthruchar17, hdrpassthruchar18, hdrpassthruchar19, hdrpassthruchar20,
   hdrpassthrunum01, hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04,
   hdrpassthrunum05, hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08,
   hdrpassthrunum09, hdrpassthrunum10, importfileid, source, lastuser, lastupdate
   )
  values
  (out_orderid,out_shipid,nvl(rtrim(in_custid),' '),nvl(rtrim(in_ordertype),' '),
  in_apptdate,rtrim(in_po),rtrim(in_rma),
  rtrim(in_tofacility),rtrim(in_billoflading),
  rtrim(in_priority),rtrim(in_shipper),
  rtrim(in_carrier),rtrim(in_reference),
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
  upper(rtrim(in_importfileid)), 'EDI',
  IMP_USERID, sysdate
  );
end if;

cntRows := 0;
select count(1)
  into cntRows
  from asncartondtl
 where orderid = out_orderid
   and shipid = out_shipid
   and custreference = in_custreference;
if cntRows <> 0 then
  out_errorno := -100;
  out_msg := 'Customer Reference already on file: ' || in_custreference;
  order_msg('E');
  return;
end if;

zci.get_customer_item(rtrim(in_custid),rtrim(in_itementered),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := rtrim(in_itementered);
end if;

if strLotRequired in ('Y','O','S','A') then
  if rtrim(in_lotnumber) is null then
    out_errorno := -101;
    out_msg := 'A lot number is required';
    order_msg('E');
    return;
  end if;
end if;

open curCustItem(strItem);
fetch curCustItem into ci;
if curCustItem%notfound then
  ci.useramt1 := 0;
end if;
close curCustItem;

if ci.lotrequired = 'N' and
   ci.serialrequired = 'N' and
   ci.user1required = 'N' and
   ci.user2required = 'N' and
   ci.user3required = 'N' then
  cntRows := 0;
  select count(1)
    into cntRows
    from asncartondtl
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and lotnumber is null;
  if cntRows <> 0 then
    out_errorno := -102;
    out_msg := 'Duplicate non-serialized line: ' || in_custreference;
    order_msg('E');
    return;
  end if;
end if;

zoe.get_base_uom_equivalent(rtrim(in_custid),rtrim(in_itementered),
  nvl(rtrim(in_uom),ci.baseuom),
  in_quantity,strItem,strUOMBase,qtyBase,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := rtrim(in_itementered);
  strUOMBase :=  nvl(rtrim(in_uom),ci.baseuom);
  qtyBase := in_quantity;
end if;

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;

if od.item is null then
  insert into orderdtl
  (orderid,shipid,item,lotnumber,uom,linestatus,qtyentered,itementered,uomentered,
  qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,statususer,
  dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
  dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
  dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
  dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
  dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
  dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
  dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
  dtlpassthrunum09, dtlpassthrunum10, comment1
  )
  values
  (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),strUOMBase,'A',
   in_quantity,rtrim(in_itementered),nvl(rtrim(in_uom),ci.baseuom),
   qtyBase,
   zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
   zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
   qtyBase*ci.useramt1,IMP_USERID,sysdate,IMP_USERID,
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
   rtrim(in_dtlcomment)
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
  update orderdtl
     set qtyentered = qtyentered + in_quantity,
         qtyorder = qtyorder + qtyBase,
         weightorder = weightorder
           + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
         cubeorder = cubeorder
           + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
         amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)), --prn 25133
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
end if;

if nvl(in_ordertype,'?') = 'C' then
   begin
      select orderid, shipid
         into l_orderid, l_shipid
         from orderhdr
         where xdockorderid = out_orderid
           and xdockshipid = out_shipid
           and ordertype = 'O'
           and shipto = in_outbound_consignee;
   exception
      when NO_DATA_FOUND then
         zoe.get_next_orderid(l_orderid, out_msg);
         if substr(out_msg, 1, 4) != 'OKAY' then
            out_errorno := 16;
            order_msg('E');
            return;
         end if;
         l_shipid := 1;
         zcl.clone_orderhdr(out_orderid, out_shipid, l_orderid, l_shipid, null, IMP_USERID, out_msg);
         if substr(out_msg, 1, 4) != 'OKAY' then
            out_errorno := 17;
            order_msg('E');
            return;
         end if;
         open c_cons(in_outbound_consignee);
         fetch c_cons into cons;
         close c_cons;
         update orderhdr
            set ordertype = 'O',
                fromfacility = rtrim(in_tofacility),
                tofacility = null,
                qtyorder = 0,
                cubeorder = 0,
                weightorder = 0,
                amtorder = 0,
                xdockorderid = out_orderid,
                xdockshipid = out_shipid,
                shipto = in_outbound_consignee,
                shiptype = cons.shiptype,
                shipterms = cons.shipterms
            where orderid = l_orderid
              and shipid = l_shipid;
   end;
   update orderdtl
      set qtyentered = qtyentered + in_quantity,
          qtyorder = qtyorder + qtyBase,
          weightorder = weightorder
            + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          cubeorder = cubeorder
            + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)), --prn 25133
          lastuser = IMP_USERID,
          lastupdate = sysdate
      where orderid = l_orderid
        and shipid = l_shipid
        and item = strItem
        and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
   if sql%rowcount = 0 then
      insert into orderdtl
         (orderid, shipid, item, custid,
          fromfacility, uom, linestatus, qtyentered,
          itementered, uomentered, qtyorder,
          weightorder,
          cubeorder,
          amtorder,
          statususer, statusupdate, lastuser, lastupdate,
          lotnumber,
          dtlpassthruchar01, dtlpassthruchar02,
          dtlpassthruchar03, dtlpassthruchar04,
          dtlpassthruchar05, dtlpassthruchar06,
          dtlpassthruchar07, dtlpassthruchar08,
          dtlpassthruchar09, dtlpassthruchar10,
          dtlpassthruchar11, dtlpassthruchar12,
          dtlpassthruchar13, dtlpassthruchar14,
          dtlpassthruchar15, dtlpassthruchar16,
          dtlpassthruchar17, dtlpassthruchar18,
          dtlpassthruchar19, dtlpassthruchar20,
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
          comment1,
          backorder, allowsub, qtytype)
      select
          l_orderid, l_shipid, strItem, in_custid,
          rtrim(in_tofacility), strUOMBase, 'A', in_quantity,
          rtrim(in_itementered), nvl(rtrim(in_uom),ci.baseuom), qtyBase,
          zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          qtyBase*ci.useramt1,
          IMP_USERID, sysdate, IMP_USERID, sysdate,
          rtrim(in_lotnumber),
          rtrim(in_dtlpassthruchar01), rtrim(in_dtlpassthruchar02),
          rtrim(in_dtlpassthruchar03), rtrim(in_dtlpassthruchar04),
          rtrim(in_dtlpassthruchar05), rtrim(in_dtlpassthruchar06),
          rtrim(in_dtlpassthruchar07), rtrim(in_dtlpassthruchar08),
          rtrim(in_dtlpassthruchar09), rtrim(in_dtlpassthruchar10),
          rtrim(in_dtlpassthruchar11), rtrim(in_dtlpassthruchar12),
          rtrim(in_dtlpassthruchar13), rtrim(in_dtlpassthruchar14),
          rtrim(in_dtlpassthruchar15), rtrim(in_dtlpassthruchar16),
          rtrim(in_dtlpassthruchar17), rtrim(in_dtlpassthruchar18),
          rtrim(in_dtlpassthruchar19), rtrim(in_dtlpassthruchar20),
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
          rtrim(in_dtlcomment),
          backorder, allowsub, qtytype
         from custitemview
         where custid = rtrim(in_custid)
           and item = strItem;
		   
	   -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
	   -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
	   update orderdtl
	   set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
	   where orderid = l_orderid
		 and shipid = l_shipid
		 and item = strItem
		 and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
   end if;
end if;

begin
  if trunc(in_expdate) = to_date('12/30/1899','mm/dd/yyyy') then
    dteexpdate := null;
  else
    dteexpdate := in_expdate;
  end if;
exception when others then
  dteexpdate := null;
end;

insert into asncartondtl
(orderid,shipid,item,lotnumber,serialnumber,
 useritem1,useritem2,useritem3,inventoryclass,
 uom,qty,trackingno,custreference,
 importfileid,created,lastuser,lastupdate,expdate,
 weight)
values
(out_orderid,out_shipid,strItem,rtrim(in_lotnumber),
 rtrim(in_serialnumber),rtrim(in_useritem1),rtrim(in_useritem2),
 rtrim(in_useritem3),nvl(rtrim(in_inventoryclass),'RG'),ci.baseuom,qtyBase,
 rtrim(in_trackingno),rtrim(in_custreference),
 upper(rtrim(in_importfileid)),sysdate,IMP_USERID,sysdate,dteexpdate,
 in_weight);


exception when others then
  out_errorno := sqlcode;
  out_msg := 'zimai' || substr(sqlerrm,1,250);
end import_asn_item;


procedure import_asn_item_hdr
(in_custid IN varchar2
,in_allow_prod_arrived IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_tofacility IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
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
,editransaction IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrType is
  select orderid,
         shipid,
         orderstatus,
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and ordertype = rtrim(nvl(in_ordertype,'R'))
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select status, nvl(paperbased,'N') as paperbased,
          unique_order_identifier,
          nvl(dup_reference_ynw,'N') as dup_reference_ynw
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cs curCustomer%rowtype;

cursor curFacility is
  select facilitystatus
    from facility
   where facility = in_tofacility;
fa curFacility%rowtype;

cursor curOrderPriority is
  select abbrev
    from orderpriority
   where code = in_priority;
op curOrderPriority%rowtype;

cursor curShipper is
  select shipperstatus
    from shipper
   where shipper = in_shipper;
sh curShipper%rowtype;

cursor curCarrier is
  select Carrierstatus
    from Carrier
   where Carrier = in_Carrier;
ca curCarrier%rowtype;

cursor curCustItem(in_item varchar2) is
  select useramt1,
         backorder,
         allowsub,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtytype,
         baseuom,
         lotrequired,
         serialrequired,
         user1required,
         user2required,
         user3required
    from custitemview
   where custid = rtrim(in_custid)
     and item = rtrim(in_item);
ci curCustItem%rowtype;


cntRows integer;
chk orderdtlline%rowtype;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;


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
  zms.log_msg(IMP_USERID, in_tofacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if rtrim(in_custid) is null then
  out_errorno := 11;
  out_msg := 'Customer ID is required';
  order_msg('E');
  return;
end if;

cs := null;
open curCustomer;
fetch curCustomer into cs;
close curCustomer;
if cs.status is null then
  out_errorno := 12;
  out_msg := 'Invalid Customer ID:' || in_custid;
  order_msg('E');
  return;
end if;


if cs.dup_reference_ynw = 'O' then
   open curOrderhdrType;
   fetch curOrderhdrType into oh;
   if curOrderHdrType%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdrType;
else
   open curOrderhdr;
   fetch curOrderhdr into oh;
   if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if rtrim(in_ordertype) is not null then
  if in_ordertype not in ('R','Q','C','P') then
    out_errorno := 1;
    out_msg := 'Invalid Order Type: ' || in_ordertype;
    order_msg('E');
    return;
  end if;
  if (in_ordertype = 'C') and (cs.paperbased = 'Y') then
    out_errorno := 13;
    out_msg := 'Crossdock order not allowed for Aggregate Inventory customer';
    order_msg('E');
    return;
  end if;
 if (in_ordertype = 'P') and (out_orderid <> 0) and (oh.ordertype <> 'P') then
    if (cs.dup_reference_ynw = 'N') then
      out_errorno := 4;
      out_msg := 'Non production order already exists';
      order_msg('E');
      return;
    else
      out_orderid := 0;
      out_shipid := 0;
      oh := null;
    end if;
  end if; 
end if;

if rtrim(in_tofacility) is not null then
  fa := null;
  open curFacility;
  fetch curFacility into fa;
  close curFacility;
  if fa.facilitystatus is null then
    out_errorno := 2;
    out_msg := 'Invalid To Facility: ' || in_tofacility;
    order_msg('E');
    return;
  end if;
end if;

if rtrim(in_priority) is not null then
  op := null;
  open curOrderPriority;
  fetch curOrderPriority into op;
  close curOrderPriority;
  if op.abbrev is null then
    out_errorno := 3;
    out_msg := 'Invalid Order Priority: ' || in_priority;
    order_msg('E');
    return;
  end if;
end if;

if rtrim(in_shipper) is not null then
  sh := null;
  open curShipper;
  fetch curShipper into sh;
  close curShipper;
  if sh.shipperstatus is null then
    out_errorno := 4;
    out_msg := 'Invalid Shipper: ' || in_shipper;
    order_msg('E');
    return;
  end if;
end if;

if rtrim(in_Carrier) is not null then
  ca := null;
  open curCarrier;
  fetch curCarrier into ca;
  close curCarrier;
  if ca.carrierstatus is null then
    out_errorno := 4;
    out_msg := 'Invalid Carrier: ' || in_Carrier;
    order_msg('E');
    return;
  end if;
end if;

if (nvl(in_allow_prod_arrived,'N') = 'Y') and (in_ordertype is null or in_ordertype <> 'P') then
  out_errorno := 16;
  out_msg := 'Cannot use prod arrived flag with non-prod order';
  order_msg('E');
  return;
end if;

if (out_orderid <> 0) and (in_ordertype = 'P') and (nvl(in_allow_prod_arrived,'N') = 'Y') and (oh.orderstatus = 'R') then
  out_orderid := 0;
  out_shipid := 0;
  oh := null;
end if;

if out_orderid <> 0 then
  if oh.ordertype not in ('R','Q','C','P') then
    out_errorno := 3;
    out_msg := 'Not an Inbound Order: ' || oh.ordertype;
    order_msg('E');
    return;
  end if;
  if (oh.orderstatus > '1') and (not ((in_ordertype = 'P') and (nvl(in_allow_prod_arrived,'N') = 'Y'))) then
    out_errorno := 4;
    out_msg := 'Invalid Order Status: ' || oh.orderstatus;
    order_msg('E');
    return;
  end if;
  update orderhdr
     set ordertype = nvl(rtrim(in_ordertype),ordertype),
         apptdate = nvl(in_apptdate,apptdate),
         po = nvl(rtrim(in_po),po),
         rma = nvl(rtrim(in_rma),rma),
         tofacility = nvl(rtrim(in_tofacility),tofacility),
         billoflading = nvl(rtrim(in_billoflading),billoflading),
         priority = nvl(rtrim(in_priority),priority),
         shipper = nvl(rtrim(in_shipper),shipper),
         carrier = nvl(rtrim(in_carrier),carrier),
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
         shippername = nvl(rtrim(in_shippername), shippername),
         shippercontact = nvl(rtrim(in_shippercontact), shippercontact),
         shipperaddr1 = nvl(rtrim(in_shipperaddr1), shipperaddr1),
         shipperaddr2 = nvl(rtrim(in_shipperaddr2), shipperaddr2),
         shippercity = nvl(rtrim(in_shippercity), shippercity),
         shipperstate = nvl(rtrim(in_shipperstate), shipperstate),
         shipperpostalcode = nvl(rtrim(in_shipperpostalcode), shipperpostalcode),
         shippercountrycode = nvl(rtrim(in_shippercountrycode), shippercountrycode),
         shipperphone = nvl(rtrim(in_shipperphone), shipperphone),
         shipperfax = nvl(rtrim(in_shipperfax), shipperfax),
         shipperemail = nvl(rtrim(in_shipperemail), shipperemail),
         importfileid = nvl(upper(rtrim(in_importfileid)),importfileid),
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid;
else
  zoe.get_next_orderid(out_orderid,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 4;
    order_msg('E');
    return;
  end if;
  out_shipid := 1;
  insert into orderhdr
  (orderid,shipid,custid,ordertype,apptdate,po,rma,
   tofacility,billoflading,priority,shipper,
   carrier,reference,
   orderstatus,commitstatus,statususer,entrydate,
   hdrpassthruchar01, hdrpassthruchar02, hdrpassthruchar03, hdrpassthruchar04,
   hdrpassthruchar05, hdrpassthruchar06, hdrpassthruchar07, hdrpassthruchar08,
   hdrpassthruchar09, hdrpassthruchar10, hdrpassthruchar11, hdrpassthruchar12,
   hdrpassthruchar13, hdrpassthruchar14, hdrpassthruchar15, hdrpassthruchar16,
   hdrpassthruchar17, hdrpassthruchar18, hdrpassthruchar19, hdrpassthruchar20,
   hdrpassthrunum01, hdrpassthrunum02, hdrpassthrunum03, hdrpassthrunum04,
   hdrpassthrunum05, hdrpassthrunum06, hdrpassthrunum07, hdrpassthrunum08,
   hdrpassthrunum09, hdrpassthrunum10, shippername, shippercontact,
   shipperaddr1,shipperaddr2,shippercity,shipperstate,
   shipperpostalcode,shippercountrycode,shipperphone,shipperfax,
   shipperemail,importfileid, source, lastuser, lastupdate, editransaction
   )
  values
  (out_orderid,out_shipid,nvl(rtrim(in_custid),' '),nvl(rtrim(in_ordertype),' '),
  in_apptdate,rtrim(in_po),rtrim(in_rma),
  rtrim(in_tofacility),rtrim(in_billoflading),
  rtrim(in_priority),rtrim(in_shipper),
  rtrim(in_carrier),rtrim(in_reference),
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
  rtrim(in_shippername), rtrim(in_shippercontact),
  rtrim(in_shipperaddr1), rtrim(in_shipperaddr2),
  rtrim(in_shippercity), rtrim(in_shipperstate),
  rtrim(in_shipperpostalcode), rtrim(in_shippercountrycode),
  rtrim(in_shipperphone), rtrim(in_shipperfax),
  rtrim(in_shipperemail),
  upper(rtrim(in_importfileid)), 'EDI', IMP_USERID, sysdate, rtrim(editransaction)
  );
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := 'zimai' || substr(sqlerrm,1,250);
end import_asn_item_hdr;


procedure import_asn_item_dtl
(in_custid IN varchar2
,in_allow_prod_arrived IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_importfileid IN varchar2
,in_trackingno IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_serialnumber IN varchar2
,in_useritem1 IN varchar2
,in_useritem2 IN varchar2
,in_useritem3 IN varchar2
,in_inventoryclass IN varchar2
,in_uom IN varchar2
,in_quantity IN number
,in_custreference varchar2
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
,in_dtlcomment IN varchar2
,in_expdate IN date
,in_weight IN number
,in_outbound_consignee IN varchar2
,in_ordertype IN varchar2
,in_assign_lineno IN varchar2
,in_weight_is_kg in varchar2
,in_manufacturedate IN date
,in_invstatus IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         ordertype,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
cursor curOrderHdrType is
  select orderid,
         shipid,
         orderstatus,
         ordertype,
         tofacility
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
     and ordertype = rtrim(nvl(in_ordertype,'R'))
   order by orderstatus;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select status, nvl(paperbased,'N') as paperbased,
         nvl(recv_line_check_yn,'N') as recv_line_check_yn,
         nvl(dup_reference_ynw,'N') as dup_reference_ynw,
         nvl(ca.asnlineno,'N') as asnlineno
    from customer c, customer_aux ca
   where c.custid = rtrim(in_custid)
     and c.custid = ca.custid(+);
cs curCustomer%rowtype;

cursor curCustItem(in_item varchar2) is
  select useramt1,
         backorder,
         allowsub,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtytype,
         baseuom,
         lotrequired,
         serialrequired,
         user1required,
         user2required,
         user3required
    from custitemview
   where custid = rtrim(in_custid)
     and item = rtrim(in_item);
ci curCustItem%rowtype;

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
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
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

cursor c_cons(p_consignee varchar2) is
   select shiptype, shipterms
      from consignee
      where consignee = p_consignee;
cons c_cons%rowtype := null;

cntRows integer;
chk orderdtlline%rowtype;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;
dteexpdate date;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
strLineNumbers char(1);
UOMError boolean;
errno integer;
errmsg varchar2(255);
insLineNo number;
dtemanufacturedate date;
nWeight number(17,8);
procedure order_msg(in_msgtype varchar2) is
   pragma autonomous_transaction;
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  zms.log_msg(IMP_USERID, oh.tofacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  commit;
exception when others then
   rollback;
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

oh := null;
open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if oh.orderid is null then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_custid || ' ' || in_reference;
  order_msg('E');
  return;
end if;

if rtrim(in_custid) is null then
  out_errorno := 11;
  out_msg := 'Customer ID is required';
  order_msg('E');
  return;
end if;

cs := null;
open curCustomer;
fetch curCustomer into cs;
close curCustomer;
if cs.status is null then
  out_errorno := 12;
  out_msg := 'Invalid Customer ID:' || in_custid;
  order_msg('E');
  return;
end if;

if cs.dup_reference_ynw = 'O' then
   if in_ordertype not in ('R','Q') then
  out_errorno := 1;
  out_msg := 'AID Invalid Order Type for Ref by Type: ' || in_ordertype;
  order_msg('E');
  return;
end if;
   oh := null;
open curOrderhdrType;
fetch curOrderhdrType into oh;
   if curOrderHdrType%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
close curOrderhdrType;

else
   oh := null;
   open curOrderhdr;
   fetch curOrderhdr into oh;
if curOrderHdr%found then
     out_orderid := oh.orderid;
     out_shipid := oh.shipid;
   end if;
   close curOrderhdr;
end if;

if oh.orderid is null then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_custid || ' ' || in_reference;
  order_msg('E');
  return;
end if;

if oh.ordertype not in ('R','Q','C','P') then
  out_errorno := 1;
  out_msg := 'Invalid Order Type: ' || oh.ordertype;
  order_msg('E');
  return;
end if;

if oh.ordertype = 'C' then
  if cs.paperbased = 'Y' then
    out_errorno := 13;
    out_msg := 'Crossdock order not allowed for Aggregate Inventory customer';
    order_msg('E');
    return;
  end if;
  if rtrim(in_outbound_consignee) is null then
    out_errorno := 14;
    out_msg := 'Outbound consignee required for Crossdock order';
    order_msg('E');
    return;
  end if;
  select count(1)
    into cntRows
    from custconsignee
   where custid = rtrim(in_custid)
     and consignee = rtrim(in_outbound_consignee);
  if cntRows = 0 then
    out_errorno := 15;
    out_msg := 'Outbound consignee '||in_outbound_consignee||' not associated with customer '
        ||in_custid;
    order_msg('E');
    return;
  end if;
end if;

if (nvl(in_allow_prod_arrived,'N') = 'Y') and (in_ordertype is null or in_ordertype <> 'P') then
  out_errorno := 16;
  out_msg := 'Cannot use prod arrived flag with non-prod order';
  order_msg('E');
  return;
end if;

if (oh.orderstatus > '1') and (not ((in_ordertype = 'P') and (nvl(in_allow_prod_arrived,'N') = 'Y'))) then
  out_errorno := 4;
  out_msg := 'Invalid Order Status: ' || oh.orderstatus;
  order_msg('E');
  return;
end if;

cntRows := 0;
select count(1)
  into cntRows
  from asncartondtl
 where orderid = out_orderid
   and shipid = out_shipid
   and custreference = in_custreference;
if cntRows <> 0 then
  out_errorno := -100;
  out_msg := 'Customer Reference already on file: ' || in_custreference;
  order_msg('E');
  return;
end if;

cntRows := 0;
if (oh.ordertype = 'P') then
  if (rtrim(in_trackingno) is null) then
    out_errorno := -100;
    out_msg := 'Production order dtls need tracking no';
    order_msg('E');
    return;
  end if;
  
  select count(1)
    into cntRows
    from asncartondtl a, orderhdr b
   where a.trackingno = in_trackingno
    and a.orderid = b.orderid and a.shipid = b.shipid
    and b.ordertype = 'P';
  if cntRows <> 0 then
    out_errorno := -100;
    out_msg := 'Tracking number already on file: ' || in_trackingno;
    order_msg('E');
    return;
  end if;
end if;

select decode(in_dtlpassthrunum10,0,null,in_dtlpassthrunum10) into insLineNo from dual;
if nvl(in_assign_lineno,'N') = 'Y' then
   select count(1) into cntRows
      from orderdtlline
      where orderid = oh.orderid
        and shipid = oh.shipid;
   if cntRows  = 0 then
      insLineNo := 1;
   else
      select max(linenumber) into insLineNo
         from orderdtlline
      where orderid = oh.orderid
        and shipid = oh.shipid;
      insLineNo := insLineNo + 1;
end if;
end if;

zci.get_customer_item(rtrim(in_custid),rtrim(in_itementered),strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := rtrim(in_itementered);
end if;

if strLotRequired in ('Y','O','S','A') then
  if rtrim(in_lotnumber) is null then
    out_errorno := -101;
    out_msg := 'A lot number is required';
    order_msg('E');
    return;
  end if;
end if;

open curCustItem(strItem);
fetch curCustItem into ci;
if curCustItem%notfound then
  ci.useramt1 := 0;
end if;
close curCustItem;

if ci.lotrequired = 'N' and
   ci.serialrequired = 'N' and
   ci.user1required = 'N' and
   ci.user2required = 'N' and
   ci.user3required = 'N' then
  cntRows := 0;
  select count(1)
    into cntRows
    from asncartondtl
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and lotnumber is null;
  if cntRows <> 0 then
    out_errorno := -102;
    out_msg := 'Duplicate non-serialized line: ' || in_custreference;
    order_msg('E');
    return;
  end if;
end if;

zoe.get_base_uom_equivalent(rtrim(in_custid),rtrim(in_itementered),
  nvl(rtrim(in_uom),ci.baseuom),
  in_quantity,strItem,strUOMBase,qtyBase,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  strItem := rtrim(in_itementered);
  strUOMBase :=  nvl(rtrim(in_uom),ci.baseuom);
  qtyBase := in_quantity;
end if;

if cs.recv_line_check_yn != 'N' then
  strLineNumbers := 'Y';
else
  strLineNumbers := 'N';
end if;

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

if strLineNumbers = 'Y' then
  if nvl(insLineNo,0) <= 0 then
    out_errorno := 5;
    out_msg := 'Invalid Line Number: ' || insLineNo;
    order_msg('E');
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
    open curOrderDtlLine(strItem,insLineNo);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      chk.linenumber := insLineNo;
    end if;
    close curOrderDtlLine;
  else
    if od.dtlpassthrunum10 = insLineNo then
      chk.linenumber := od.dtlpassthrunum10;
    end if;
  end if;
end if;

nWeight := in_weight;
if nvl(in_weight_is_kg,'N') = 'Y' then
   nWeight := nWeight * 2.20462262;
end if;

if chk.item is null then
  insert into orderdtl
  (orderid,shipid,item,lotnumber,uom,linestatus,qtyentered,itementered,uomentered,
  qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,statususer,
  dtlpassthruchar01, dtlpassthruchar02, dtlpassthruchar03, dtlpassthruchar04,
  dtlpassthruchar05, dtlpassthruchar06, dtlpassthruchar07, dtlpassthruchar08,
  dtlpassthruchar09, dtlpassthruchar10, dtlpassthruchar11, dtlpassthruchar12,
  dtlpassthruchar13, dtlpassthruchar14, dtlpassthruchar15, dtlpassthruchar16,
  dtlpassthruchar17, dtlpassthruchar18, dtlpassthruchar19, dtlpassthruchar20,
  dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
  dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
  dtlpassthrunum09, dtlpassthrunum10, comment1
  )
  values
  (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),strUOMBase,'A',
   in_quantity,rtrim(in_itementered),nvl(rtrim(in_uom),ci.baseuom),
   qtyBase,
   zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
   zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
   qtyBase*ci.useramt1,IMP_USERID,sysdate,IMP_USERID,
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
   decode(insLineNo,0,null,insLineNo),
   rtrim(in_dtlcomment)
   );
   
   -- prn 25133 - update amtorder
   update orderdtl
   set amtorder = qtyorder * zci.item_amt(custid, orderid, shipid, item, lotnumber)
   where orderid = out_orderid
	and shipid = out_shipid
	and item = nvl(strItem,' ')
	and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
	
  if cs.recv_line_check_yn != 'N' then
     select decode(nvl(od.dtlpassthrunum10,0),nvl(insLineNo,0),
                       od.dtlpassthrunum10,nvl(insLineNo,0)) into insLineNo
        from dual;

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
       dtlpassthrunum09, dtlpassthrunum10,
       lastuser, lastupdate
      )
      values
      (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
       insLineNo,qtyBase,
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
       decode(nvl(od.dtlpassthrunum10,0),nvl(insLineno,0),
         od.dtlpassthrunum10,nvl(insLineNo,0)),
       IMP_USERID, sysdate
      );
  end if;

else
   if strLineNumbers = 'Y' then
     if olc.count = 0 then --add line record for item info that is already on file
       insLineNo := od.dtlpassthrunum10;
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
         dtlpassthrunum09, dtlpassthrunum10,
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
         od.dtlpassthrunum09, od.dtlpassthrunum10,
         null, IMP_USERID, sysdate
        );
     end if;
     if (olc.count != 0) and
        (chk.linenumber is not null) then
       insLineNo := chk.linenumber;

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
              dtlpassthrunum10 = nvl(decode(insLineno,0,null,insLineNo),dtlpassthrunum10),
              lastuser = IMP_USERID,
              lastupdate = sysdate
        where orderid = out_orderid
          and shipid = out_shipid
          and item = strItem
          and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
          and linenumber = chk.linenumber;
else
       select decode(nvl(od.dtlpassthrunum10,0),nvl(insLineNo,0),
                               od.dtlpassthrunum10,nvl(insLineNo,0)) into insLineNo
          from dual;
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
         dtlpassthrunum09, dtlpassthrunum10,
         lastuser, lastupdate
        )
        values
        (out_orderid,out_shipid,nvl(strItem,' '),rtrim(in_lotnumber),
         insLineNo,qtyBase,
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
         decode(nvl(od.dtlpassthrunum10,0),nvl(insLineNo,0),
           od.dtlpassthrunum10,nvl(insLineNo,0)),
         IMP_USERID, sysdate
        );
     end if;
   end if;

  update orderdtl
     set qtyentered = qtyentered + in_quantity,
         qtyorder = qtyorder + qtyBase,
         weightorder = weightorder
           + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
         cubeorder = cubeorder
           + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
         amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)),  --prn 25133
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
end if;

begin
  if trunc(in_expdate) = to_date('12/30/1899','mm/dd/yyyy') then
    dteexpdate := null;
  else
    dteexpdate := in_expdate;
  end if;
exception when others then
  dteexpdate := null;
end;

begin
  if trunc(in_manufacturedate) = to_date('12/30/1899','mm/dd/yyyy')  then
    dtemanufacturedate := null;
  --else
     --select to_date(rtrim(in_manufacturedate), 'DDDY')
       --into dtemanufacturedate
       --from dual;
  else
     dtemanufacturedate := in_manufacturedate;
  end if;
exception when others then
  dtemanufacturedate := null;
end;

if cs.asnlineno != 'Y' or
   in_trackingno is null then
   insLineNo := null;
end if;
insert into asncartondtl
(orderid,shipid,item,lotnumber,serialnumber,
 useritem1,useritem2,useritem3,inventoryclass,
 uom,qty,trackingno,custreference,
 importfileid,created,lastuser,lastupdate,expdate,
 weight, lineno,manufacturedate,invstatus)
values
(out_orderid,out_shipid,strItem,rtrim(in_lotnumber),
 rtrim(in_serialnumber),rtrim(in_useritem1),rtrim(in_useritem2),
 rtrim(in_useritem3),nvl(rtrim(in_inventoryclass),'RG'),ci.baseuom,qtyBase,
 rtrim(in_trackingno),rtrim(in_custreference),
 upper(rtrim(in_importfileid)),sysdate,IMP_USERID,sysdate,dteexpdate,
 nWeight, insLineNo,dtemanufacturedate,rtrim(in_invstatus));

if oh.ordertype = 'C' then
   begin
      select orderid, shipid
         into l_orderid, l_shipid
         from orderhdr
         where xdockorderid = out_orderid
           and xdockshipid = out_shipid
           and ordertype = 'O'
           and shipto = in_outbound_consignee;
   exception
      when NO_DATA_FOUND then
         zoe.get_next_orderid(l_orderid, out_msg);
         if substr(out_msg, 1, 4) != 'OKAY' then
            out_errorno := 16;
            order_msg('E');
            return;
         end if;
         l_shipid := 1;
         zcl.clone_orderhdr(out_orderid, out_shipid, l_orderid, l_shipid, null, IMP_USERID, out_msg);
         if substr(out_msg, 1, 4) != 'OKAY' then
            out_errorno := 17;
            order_msg('E');
            return;
         end if;
         open c_cons(in_outbound_consignee);
         fetch c_cons into cons;
         close c_cons;
         update orderhdr
            set ordertype = 'O',
                fromfacility = oh.tofacility,
                tofacility = null,
                qtyorder = 0,
                cubeorder = 0,
                weightorder = 0,
                amtorder = 0,
                xdockorderid = out_orderid,
                xdockshipid = out_shipid,
                shipto = in_outbound_consignee,
                shiptype = cons.shiptype,
                shipterms = cons.shipterms
            where orderid = l_orderid
              and shipid = l_shipid;
   end;
   update orderdtl
      set qtyentered = qtyentered + in_quantity,
          qtyorder = qtyorder + qtyBase,
          weightorder = weightorder
            + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          cubeorder = cubeorder
            + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)),  --prn 25133
          lastuser = IMP_USERID,
          lastupdate = sysdate
      where orderid = l_orderid
        and shipid = l_shipid
        and item = strItem
        and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
   if sql%rowcount = 0 then
      insert into orderdtl
         (orderid, shipid, item, custid,
          fromfacility, uom, linestatus, qtyentered,
          itementered, uomentered, qtyorder,
          weightorder,
          cubeorder,
          amtorder,
          statususer, statusupdate, lastuser, lastupdate,
          lotnumber,
          dtlpassthruchar01, dtlpassthruchar02,
          dtlpassthruchar03, dtlpassthruchar04,
          dtlpassthruchar05, dtlpassthruchar06,
          dtlpassthruchar07, dtlpassthruchar08,
          dtlpassthruchar09, dtlpassthruchar10,
          dtlpassthruchar11, dtlpassthruchar12,
          dtlpassthruchar13, dtlpassthruchar14,
          dtlpassthruchar15, dtlpassthruchar16,
          dtlpassthruchar17, dtlpassthruchar18,
          dtlpassthruchar19, dtlpassthruchar20,
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
          comment1,
          backorder, allowsub, qtytype)
      select
          l_orderid, l_shipid, strItem, in_custid,
          oh.tofacility, strUOMBase, 'A', in_quantity,
          rtrim(in_itementered), nvl(rtrim(in_uom),ci.baseuom), qtyBase,
          zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uom),ci.baseuom)) * in_quantity,
          qtyBase*ci.useramt1,
          IMP_USERID, sysdate, IMP_USERID, sysdate,
          rtrim(in_lotnumber),
          rtrim(in_dtlpassthruchar01), rtrim(in_dtlpassthruchar02),
          rtrim(in_dtlpassthruchar03), rtrim(in_dtlpassthruchar04),
          rtrim(in_dtlpassthruchar05), rtrim(in_dtlpassthruchar06),
          rtrim(in_dtlpassthruchar07), rtrim(in_dtlpassthruchar08),
          rtrim(in_dtlpassthruchar09), rtrim(in_dtlpassthruchar10),
          rtrim(in_dtlpassthruchar11), rtrim(in_dtlpassthruchar12),
          rtrim(in_dtlpassthruchar13), rtrim(in_dtlpassthruchar14),
          rtrim(in_dtlpassthruchar15), rtrim(in_dtlpassthruchar16),
          rtrim(in_dtlpassthruchar17), rtrim(in_dtlpassthruchar18),
          rtrim(in_dtlpassthruchar19), rtrim(in_dtlpassthruchar20),
          decode(in_dtlpassthrunum01,0,null,in_dtlpassthrunum01),
          decode(in_dtlpassthrunum02,0,null,in_dtlpassthrunum02),
          decode(in_dtlpassthrunum03,0,null,in_dtlpassthrunum03),
          decode(in_dtlpassthrunum04,0,null,in_dtlpassthrunum04),
          decode(in_dtlpassthrunum05,0,null,in_dtlpassthrunum05),
          decode(in_dtlpassthrunum06,0,null,in_dtlpassthrunum06),
          decode(in_dtlpassthrunum07,0,null,in_dtlpassthrunum07),
          decode(in_dtlpassthrunum08,0,null,in_dtlpassthrunum08),
          decode(in_dtlpassthrunum09,0,null,in_dtlpassthrunum09),
          decode(insLineno,0,null,insLineno),
          rtrim(in_dtlcomment),
          backorder, allowsub, qtytype
         from custitemview
         where custid = rtrim(in_custid)
           and item = strItem;
		   
	   -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
	   -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
	   update orderdtl
	   set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
	   where orderid = l_orderid
		 and shipid = l_shipid
		 and item = strItem
		 and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
   end if;
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := 'zimai' || substr(sqlerrm,1,250);
end import_asn_item_dtl;




procedure begin_irisrecv
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


  CURSOR C_CUSTID(in_custid char) IS
   SELECT custid
     FROM customer
    WHERE decode(in_custid,'ALL', irisexport,custid,'Y','N') = 'Y';


  CURSOR C_INVD(in_custid char, in_begin char, in_end char)  IS
    SELECT D.activity, D.billedqty, D.billedamt, D.item, D.lotnumber,
           D.orderid, D.shipid,
           H.invtype, A.irisclass,
           A.irisname, NVL(A.irischarge,'N') irischarge, A.iristype, H.custid,
           D.billstatus
      FROM activity A, invoicedtl D, invoicehdr H
     WHERE H.custid = in_custid
       AND H.postdate >= to_date(in_begin, 'YYYYMMDDHH24MISS')
       AND H.postdate < to_date(in_end, 'YYYYMMDDHH24MISS')
       AND H.invstatus = '3'
       AND H.invtype = 'R'
       AND D.invoice = H.invoice
       AND (D.billedqty != 0
         OR D.billedamt != 0)
       AND A.code = D.activity
       AND A.irisname is not null
       AND A.irisname not in ('RCO','RCR','RCP');

  CURSOR C_INVDR(in_custid char, in_begin char, in_end char)  IS
    SELECT D.activity, D.billedqty, D.billedamt, D.item, D.lotnumber,
           D.orderid, D.shipid,
           H.invtype, A.irisclass,
           A.irisname, NVL(A.irischarge,'N') irischarge, A.iristype, H.custid,
           D.billstatus
      FROM activity A, invoicedtl D, invoicehdr H
     WHERE H.custid = in_custid
       AND H.postdate >= to_date(in_begin, 'YYYYMMDDHH24MISS')
       AND H.postdate < to_date(in_end, 'YYYYMMDDHH24MISS')
       AND H.invstatus = '3'
       AND H.invtype = 'R'
       AND D.invoice = H.invoice
       AND (D.billedqty != 0
        OR D.billedamt != 0)
       AND A.code = D.activity
       AND A.irisname is not null
       AND A.irisname in ('RCO','RCR','RCP');

  CURSOR C_ORD(in_sess char) IS
   SELECT distinct orderid, shipid
     FROM irisrecvex
    WHERE sessionid = in_sess;

  CURSOR C_ITEM(in_sess char, in_orderid number, in_shipid number) IS
   SELECT distinct item
     FROM irisrecvex
    WHERE sessionid = in_sess
      AND orderid = in_orderid
      AND shipid = in_shipid;


linenum integer;
l_sortord integer;

errmsg varchar2(100);

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
   where view_name = 'IRISRECV_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

if in_custid != 'ALL' then
  select count(1)
    into cntRows
    from customer
   where custid = rtrim(in_custid);

  if cntRows = 0 then
    out_errorno := -1;
    out_msg := 'Invalid Customer Code';
    return;
  end if;
end if;

for ccus in C_CUSTID(in_custid) loop

    tblCompany := null;
    cmdSqlCompany := 'select abbrev from class_to_company_' ||
      rtrim(ccus.custid) || ' where code = ''RG'' ';
    begin
      curCompany := dbms_sql.open_cursor;
      dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
      dbms_sql.define_column(curCompany,1,tblCompany,12);
      cntRows := dbms_sql.execute(curCompany);
      cntRows := dbms_sql.fetch_rows(curCompany);
      if cntRows > 0 then
        dbms_sql.column_value(curCompany,1,tblCompany);
      else
          out_msg := 'class_to_company__'
                  ||rtrim(ccus.custid) ||': RG Entry not defined';
          out_errorno := -100;

      end if;
      dbms_sql.close_cursor(curCompany);
    exception when others then
          dbms_sql.close_cursor(curCompany);
          out_msg := 'class_to_company_'
                  ||rtrim(ccus.custid) ||': '|| substr(sqlerrm,1,80);
          out_errorno := sqlcode;
    end;

    if tblCompany is null then
          rollback;
          zms.log_msg('IRISRecv', '', ccus.custid,
                   out_msg,
                   'E', 'ImpExp', errmsg);
          commit;
          return;
    end if;

    tblWarehouse := null;
    cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
      rtrim(ccus.custid) || ' where code = ''RG'' ';
    begin
      curCompany := dbms_sql.open_cursor;
      dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
      dbms_sql.define_column(curCompany,1,tblWarehouse,12);
      cntRows := dbms_sql.execute(curCompany);
      cntRows := dbms_sql.fetch_rows(curCompany);
      if cntRows > 0 then
        dbms_sql.column_value(curCompany,1,tblWarehouse);
      else
          out_msg := 'class_to_warehouse_'
                  ||rtrim(ccus.custid) ||': RG Entry not defined';
          out_errorno := -100;

      end if;
      dbms_sql.close_cursor(curCompany);
    exception when others then
          dbms_sql.close_cursor(curCompany);
          out_msg := 'class_to_warehouse_'
                  ||rtrim(ccus.custid) ||': '|| substr(sqlerrm,1,80);
          out_errorno := sqlcode;
    end;

    if tblWarehouse is null then
          rollback;
          zms.log_msg('IRISRecv', '', ccus.custid,
                   out_msg,
                   'E', 'ImpExp', errmsg);
          commit;
          return;
    end if;

    -- Begin load of charges that apply for Receiver charges
    for crec in C_INVD(ccus.custid, in_begdatestr, in_enddatestr) loop
      if crec.billstatus = '3' then
        insert into IrisRecvEx(
           sessionid,
           orderid,
           shipid,
           line,
           sortord,
           item,
           lotnumber,
           serialnumber,
           service,
           class,
           custid,
           company,
           warehouse,
           quantity,
           charge
        )
        values
        (
            strSuffix,
            crec.orderid,
            crec.shipid,
            0,
            99,
            nvl(crec.item,'0000000000000000'),
            crec.lotnumber,
            'N/A',
            crec.irisname,
            crec.irisclass,
            ccus.custid,
            tblcompany,
            tblWarehouse,
            crec.billedqty,
            decode(crec.irischarge,'Y',crec.billedamt, 0)
        );
      end if;
    end loop;



    for crec in C_INVDR(ccus.custid, in_begdatestr, in_enddatestr) loop
      if crec.billstatus = '3' then
        linenum := 0;
        l_sortord := 0;

        if crec.irisname = 'RCO' then
           select count(1)
             into linenum
             from orderdtl
            where orderid = crec.orderid
              and shipid = crec.shipid;
           linenum := 3;
        end if;

        if crec.irisname = 'RCP' then
           l_sortord := 1;
        end if;

        if crec.irisname = 'RCR' then
           l_sortord := 2;
        end if;

        insert into IrisRecvEx(
           sessionid,
           orderid,
           shipid,
           line,
           sortord,
           item,
           lotnumber,
           serialnumber,
           service,
           class,
           custid,
           company,
           warehouse,
           quantity,
           charge
        )
        values
        (
            strSuffix,
            crec.orderid,
            crec.shipid,
            linenum,
            l_sortord,
            nvl(crec.item,'0000000000000000'),
            crec.lotnumber,
            'N/A',
            crec.irisname,
            crec.irisclass,
            ccus.custid,
            tblcompany,
            tblWarehouse,
            crec.billedqty,
            decode(crec.irischarge,'Y',crec.billedamt, 0)
        );
      end if;
    end loop;


    for crec in C_ORD(strSuffix) loop
        linenum := 0;
        for crec2 in C_ITEM(strSuffix, crec.orderid, crec.shipid) loop
            linenum := linenum + 1;
            update irisrecvex
               set line = linenum
             where sessionid = strSuffix
               and orderid = crec.orderid
               and shipid = crec.shipid
               and item = crec2.item;

        end loop;
    end loop;

end loop;

cmdSql := 'create view irisrecv_dtl_' || strSuffix ||
 ' (custid,company,warehouse,orderid,shipid,line,sortord,item,' ||
 ' lotnumber,serialnumber,reference,opendate,closedate,' ||
 ' name,serviceclass,servicename,servicefee,quantity,lineord,'||
 ' shipfromname,shipfromcontact,shipfromaddr1,shipfromaddr2,shipfromcity,' ||
 ' shipfromstate,shipfrompostalcode,shipfromcountrycode)' ||
 'as select I.custid,I.company,I.warehouse,I.orderid,I.shipid,I.line,' ||
 'I.sortord,I.item,I.lotnumber,I.serialnumber,'||
 'OH.reference,L.rcvddate,oh.statusupdate,C.name,I.class,' ||
 'I.service,substr(to_char(I.charge,''099999999999.99''),2),' ||
 'I.quantity,decode(I.service,''RCO'',0,I.line),' ||
 'SH.name,SH.contact,SH.addr1,SH.addr2,SH.city,SH.state,' ||
 'SH.postalcode,SH.countrycode' ||
 ' from shipper SH, loads L, orderhdr OH, customer C, irisrecvex I ' ||
 ' where I.sessionid = '''||strSuffix||''''||
 ' and C.custid  = I.custid  and OH.orderid(+) = I.orderid ' ||
 '   and OH.shipid(+) = I.shipid' ||
 '   and L.loadno(+) = OH.loadno' ||
 '   and SH.shipper(+) = OH.shipper';
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
  out_msg := 'zimbir ' || sqlerrm;
  out_errorno := sqlcode;
end begin_irisrecv;

----------------------------------------------------------------------
-- end_irisrecv
----------------------------------------------------------------------
procedure end_irisrecv
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

delete from irisrecvex where sessionid = strSuffix;

cmdSql := 'drop VIEW irisrecv_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeir ' || sqlerrm;
  out_errorno := sqlcode;
end end_irisrecv;

----------------------------------------------------------------------
-- begin_irisship
----------------------------------------------------------------------
procedure begin_irisship
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

  CURSOR C_CUSTID(in_custid char) IS
   SELECT custid
     FROM customer
    WHERE decode(in_custid,'ALL', irisexport,custid,'Y','N') = 'Y';


  CURSOR C_INVD(in_custid char, in_begin char, in_end char)  IS
    SELECT D.activity, D.billedqty, D.billedamt, D.item, D.lotnumber,
           D.orderid, D.shipid,
           H.invtype, A.irisclass,
           A.irisname, NVL(A.irischarge,'N') irischarge, A.iristype, H.custid,
           D.billstatus
      FROM activity A, invoicedtl D, invoicehdr H
     WHERE H.custid = in_custid
       AND H.postdate >= to_date(in_begin, 'YYYYMMDDHH24MISS')
       AND H.postdate < to_date(in_end, 'YYYYMMDDHH24MISS')
       AND H.invstatus = '3'
       AND H.invtype = 'A'
       AND D.invoice = H.invoice
       AND (D.billedqty != 0
        OR D.billedamt != 0)
       AND A.code = D.activity
       AND A.irisname is not null
       AND A.irisname not in ('ORC','WKN','HLY','ORR','ORP','ORL');

  CURSOR C_INVDR(in_custid char, in_begin char, in_end char)  IS
    SELECT D.activity, D.billedqty, D.billedamt, D.item, D.lotnumber,
           D.orderid, D.shipid,
           H.invtype, A.irisclass,
           A.irisname, NVL(A.irischarge,'N') irischarge, A.iristype, H.custid,
           D.billstatus
      FROM activity A, invoicedtl D, invoicehdr H
     WHERE H.custid = in_custid
       AND H.postdate >= to_date(in_begin, 'YYYYMMDDHH24MISS')
       AND H.postdate < to_date(in_end, 'YYYYMMDDHH24MISS')
       AND H.invstatus = '3'
       AND H.invtype = 'A'
       AND D.invoice = H.invoice
       AND (D.billedqty != 0
        OR D.billedamt != 0)
       AND A.code = D.activity
       AND A.irisname is not null
       AND A.irisname in ('ORC','WKN','HLY','ORR','ORP','ORL');

  CURSOR C_WEIGHT(in_orderid number, in_shipid number) IS
   SELECT round(sum(weight))
     FROM shippingplate
    WHERE orderid = in_orderid
      AND shipid = in_shipid
      AND status = 'SH'
      AND parentlpid is null;

l_weight number(9);

  CURSOR C_TRACK(in_orderid number, in_shipid number) IS
   SELECT distinct trackingno
     FROM shippingplate
    WHERE orderid = in_orderid
      AND shipid = in_shipid
      AND status = 'SH'
      AND parentlpid is null;

  CURSOR C_TRACKITEM(in_orderid number, in_shipid number, in_item char) IS
   SELECT distinct trackingno
     FROM shippingplate
    WHERE orderid = in_orderid
      AND shipid = in_shipid
      AND item = in_item
      AND status = 'SH'
      AND parentlpid is null;

l_pkgcount integer;
l_trackingno shippingplate.trackingno%type;
alt_trackingno shippingplate.trackingno%type;

l_sortord integer;

  CURSOR C_ORD(in_sess char) IS
   SELECT distinct orderid, shipid
     FROM irisshipex
    WHERE sessionid = in_sess;

  CURSOR C_ITEM(in_sess char, in_orderid number, in_shipid number) IS
   SELECT distinct item
     FROM irisshipex
    WHERE sessionid = in_sess
      AND orderid = in_orderid
      AND shipid = in_shipid;

  CURSOR C_ORDERINFO(in_orderid integer, in_shipid integer) IS
   SELECT shiptype, deliveryservice, hdrpassthruchar13, hdrpassthruchar07
     FROM orderhdr
    WHERE orderid = in_orderid
      AND shipid = in_shipid;
oi c_orderinfo%rowtype;

cntDelException integer;
strdeliveryservice orderhdr.deliveryservice%type;
linenum integer;
errmsg varchar2(100);
strDebug char(1);

procedure debugmsg(in_text varchar2) is
begin

if strDebug = 'Y' then
  cntRows := 1;
  while (cntRows * 60) < (Length(in_text)+60)
  loop
    zut.prt(substr(in_text,((cntRows-1)*60)+1,60));
    cntRows := cntRows + 1;
  end loop;
end if;

end;

begin

if out_errorno = -12345 then
  strDebug := 'Y';
else
  strDebug := 'N';
end if;

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'IRISSHIP_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

debugmsg('strSuffix is <' || strSuffix || '>');

if in_custid != 'ALL' then
    select count(1)
      into cntRows
      from customer
     where custid = rtrim(in_custid);

    if cntRows = 0 then
      out_errorno := -1;
      out_msg := 'Invalid Customer Code';
      return;
    end if;
end if;

debugmsg('begin C_CUSTID loop');
for ccus in C_CUSTID(in_custid) loop

    tblCompany := null;
    cmdSqlCompany := 'select abbrev from class_to_company_' ||
      rtrim(ccus.custid) || ' where code = ''RG'' ';
    begin
      curCompany := dbms_sql.open_cursor;
      dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
      dbms_sql.define_column(curCompany,1,tblCompany,12);
      cntRows := dbms_sql.execute(curCompany);
      cntRows := dbms_sql.fetch_rows(curCompany);
      if cntRows > 0 then
        dbms_sql.column_value(curCompany,1,tblCompany);
      else
          out_msg := 'class_to_company_'
                  ||rtrim(ccus.custid) ||': RG Entry not defined';
          out_errorno := -100;

      end if;
      dbms_sql.close_cursor(curCompany);
    exception when others then
          dbms_sql.close_cursor(curCompany);
          out_msg := 'class_to_company_'
                  ||rtrim(ccus.custid) ||': '|| substr(sqlerrm,1,80);
          out_errorno := sqlcode;
    end;

    if tblCompany is null then
          rollback;
          zms.log_msg('IRISShip', '', ccus.custid,
                   out_msg,
                   'E', 'ImpExp', errmsg);
          commit;
          return;
    end if;

    tblWarehouse := null;
    cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
      rtrim(ccus.custid) || ' where code = ''RG'' ';
    begin
      curCompany := dbms_sql.open_cursor;
      dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
      dbms_sql.define_column(curCompany,1,tblWarehouse,12);
      cntRows := dbms_sql.execute(curCompany);
      cntRows := dbms_sql.fetch_rows(curCompany);
      if cntRows > 0 then
        dbms_sql.column_value(curCompany,1,tblWarehouse);
      else
          out_msg := 'class_to_warehouse_'
                  ||rtrim(ccus.custid) ||': RG Entry not defined';
          out_errorno := -100;

      end if;
      dbms_sql.close_cursor(curCompany);
    exception when others then
          dbms_sql.close_cursor(curCompany);
          out_msg := 'class_to_warehouse_'
                  ||rtrim(ccus.custid) ||': '|| substr(sqlerrm,1,80);
          out_errorno := sqlcode;
    end;

    if tblWarehouse is null then
          rollback;
          zms.log_msg('IRISShip', '', ccus.custid,
                   out_msg,
                   'E', 'ImpExp', errmsg);
          commit;
          return;
    end if;

    debugmsg('begin C_INVD loop for cust <' || ccus.custid || '>');
    for crec in C_INVD(ccus.custid, in_begdatestr, in_enddatestr) loop
      if crec.billstatus = '3' then
        debugmsg('c_orderinfo ' || crec.orderid || '-' || crec.shipid);
        l_weight := 0;
        OPEN C_WEIGHT(crec.orderid,crec.shipid);
        FETCH C_WEIGHT into l_weight;
        CLOSE C_WEIGHT;

        l_pkgcount := 0;
        l_trackingno := null;
        oi := null;
        OPEN C_ORDERINFO(crec.orderid, crec.shipid);
        FETCH C_ORDERINFO into oi;
        CLOSE C_ORDERINFO;
        -- zut.prt('Check '||crec.orderid||'-'||crec.shipid||' ST:'||oi.shiptype);
        if oi.shiptype in ('L','T') then
           l_trackingno := to_char(crec.orderid)||'-'||to_char(crec.shipid);
           -- zut.prt(' BOL number = '||l_trackingno);
        end if;

        cntDelException := 0;
        begin
          select count(1)
            into cntDelException
            from IRIS_Del_Service_Exception
           where code = ccus.custid;
        exception when others then
          cntDelException := 0;
        end;
        if cntDelexception = 1 then
          strDeliveryService := NVL(SUBSTR(oi.hdrpassthruchar13,6,3),
            substr(oi.hdrpassthruchar07,1,4));
        else
          strDeliveryService := oi.deliveryservice;
        end if;
        for crec2 in C_TRACK(crec.orderid,crec.shipid) loop
            l_pkgcount := l_pkgcount + 1;
            if l_trackingno is null then
               l_trackingno := crec2.trackingno;
            end if;
        end loop;

        insert into IrisShipEx(
           sessionid,
           orderid,
           shipid,
           line,
           sortord,
           item,
           lotnumber,
           serialnumber,
           service,
           class,
           custid,
           company,
           warehouse,
           quantity,
           charge,
           weight,
           trackingno,
           pkgcount,
           deliveryservice
        )
        values
        (
            strSuffix,
            crec.orderid,
            crec.shipid,
            0,
            99,
            nvl(crec.item,'0000000000000000'),
            crec.lotnumber,
            'N/A',
            crec.irisname,
            crec.irisclass,
            ccus.custid,
            tblcompany,
            tblWarehouse,
            crec.billedqty,
            decode(crec.irischarge,'Y',crec.billedamt, 0),
            l_weight,
            nvl(l_trackingno,'000000000000000000000000000000'),
            l_pkgcount,
            strdeliveryservice
        );
      end if;
    end loop;

    debugmsg('begin C_INVDR loop for cust <' || ccus.custid || '>');
    for crec in C_INVDR(ccus.custid, in_begdatestr, in_enddatestr) loop
      if crec.billstatus = '3' then
        l_pkgcount := 0;
        l_trackingno := null;

        oi := null;
        OPEN C_ORDERINFO(crec.orderid, crec.shipid);
        FETCH C_ORDERINFO into oi;
        CLOSE C_ORDERINFO;

        -- zut.prt('Check2 '||crec.orderid||'-'||crec.shipid||' ST:'||l_shiptype);
        if oi.shiptype in ('L','T') then
           l_trackingno := to_char(crec.orderid)||'-'||to_char(crec.shipid);
           -- zut.prt(' BOL number = '||l_trackingno);
        end if;

        cntDelException := 0;
        begin
          select count(1)
            into cntDelException
            from IRIS_Del_Service_Exception
           where code = ccus.custid;
        exception when others then
          cntDelException := 0;
        end;
        if cntDelexception = 1 then
          strDeliveryService := NVL(SUBSTR(oi.hdrpassthruchar13,6,3),
            substr(oi.hdrpassthruchar07,1,4));
        else
          strDeliveryService := oi.deliveryservice;
        end if;

        if crec.irisname in ('ORC','WKN','HLY') then
           l_sortord := 0;
           for crec2 in C_TRACK(crec.orderid,crec.shipid) loop
                if l_trackingno is null then
                   l_trackingno := crec2.trackingno;
                end if;
           end loop;
        end if;

        if crec.irisname = 'ORL' then
           l_sortord := 1;
        end if;

        if crec.irisname = 'ORP' then
           l_sortord := 2;
        end if;

        if crec.irisname = 'ORR' then
           l_sortord := 3;
        end if;

        l_weight := 0;
        OPEN C_WEIGHT(crec.orderid,crec.shipid);
        FETCH C_WEIGHT into l_weight;
        CLOSE C_WEIGHT;

        if l_trackingno is null then
            for crec2 in C_TRACKITEM(crec.orderid,crec.shipid, crec.item) loop
               l_trackingno := crec2.trackingno;
            end loop;
        end if;

        insert into IrisShipEx(
           sessionid,
           orderid,
           shipid,
           line,
           sortord,
           item,
           lotnumber,
           serialnumber,
           service,
           class,
           custid,
           company,
           warehouse,
           quantity,
           charge,
           weight,
           trackingno,
           pkgcount,
           deliveryservice
        )
        values
        (
            strSuffix,
            crec.orderid,
            crec.shipid,
            0,
            l_sortord,
            nvl(crec.item,'0000000000000000'),
            crec.lotnumber,
            'N/A',
            crec.irisname,
            crec.irisclass,
            ccus.custid,
            tblcompany,
            tblWarehouse,
            crec.billedqty,
            decode(crec.irischarge,'Y',crec.billedamt, 0),
            l_weight,
            nvl(l_trackingno,'000000000000000000000000000000'),
            l_pkgcount,
            strdeliveryservice
        );
      end if;
    end loop;

    for crec in C_ORD(strSuffix) loop
        debugmsg('begin line numbers');
        linenum := 0;
        for crec2 in C_ITEM(strSuffix, crec.orderid, crec.shipid) loop
            linenum := linenum + 1;
            update irisshipex
               set line = linenum
             where sessionid = strSuffix
               and orderid = crec.orderid
               and shipid = crec.shipid
               and item = crec2.item;
        end loop;
    end loop;

end loop; -- C_CUSTID

debugmsg('create ship_dtl view');
cmdSql := 'create view irisship_dtl_' || strSuffix ||
 ' (custid,company,warehouse,orderid,shipid,line,sortord,item,' ||
 ' lotnumber,serialnumber,reference,po,opendate,closedate,' ||
 ' name,serviceclass,servicename,servicefee,quantity,lineord,' ||
 ' weight,pkgcount,tracking,carrier,service,' ||
 ' shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,' ||
 ' shiptocity,shiptostate,shiptopostalcode,shiptocountrycode)' ||
 'as select I.custid,I.company,I.warehouse,I.orderid,I.shipid,I.line,' ||
 'I.sortord,I.item,I.lotnumber,I.serialnumber,'||
 'OH.reference,OH.po,OH.statusupdate,oh.dateshipped,C.name,I.class,' ||
 'I.service,substr(to_char(I.charge,''099999999999.99''),2),' ||
 'I.quantity,decode(I.service,''ORC'',0,I.line),' ||
 'I.weight,I.pkgcount,I.trackingno,' ||
 'OH.carrier,I.deliveryservice,' ||
 'OH.shiptoname,OH.shiptocontact,' ||
 'OH.shiptoaddr1,OH.shiptoaddr2,OH.shiptocity,OH.shiptostate,' ||
 'OH.shiptopostalcode,OH.shiptocountrycode ' ||
 ' from loads L, orderhdr OH, customer C, irisshipex I ' ||
 ' where I.sessionid = '''||strSuffix||''''||
 ' and C.custid  = I.custid  and OH.orderid(+) = I.orderid ' ||
 '   and OH.shipid(+) = I.shipid' ||
 '   and L.loadno(+) = OH.loadno';
curFunc := dbms_sql.open_cursor;
/*
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbis ' || sqlerrm;
  out_errorno := sqlcode;
end begin_irisship;

----------------------------------------------------------------------
-- end_irisship
----------------------------------------------------------------------
procedure end_irisship
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

delete from irisshipex where sessionid = strSuffix;

cmdSql := 'drop VIEW irisship_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeis ' || sqlerrm;
  out_errorno := sqlcode;
end end_irisship;

----------------------------------------------------------------------
-- begin_irisancl
----------------------------------------------------------------------
procedure begin_irisancl
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

  CURSOR C_CUSTID(in_custid char) IS
   SELECT custid
     FROM customer
    WHERE decode(in_custid,'ALL', irisexport,custid,'Y','N') = 'Y';


  CURSOR C_INVD(in_custid char, in_begin char, in_end char) IS
    SELECT D.activity, D.billedqty, D.billedamt,
           D.orderid, D.shipid,
           H.invtype,
           A.irisclass, A.irisname,
           NVL(A.irischarge,'N') irischarge, A.iristype, H.custid,
           D.billstatus,h.postdate
      FROM activity A, invoicedtl D, invoicehdr H
     WHERE H.custid = in_custid
       AND H.postdate >= to_date(in_begin,'YYYYMMDDHH24MISS')
       AND H.postdate < to_date(in_end,'YYYYMMDDHH24MISS')
       AND H.invstatus = '3'
       AND H.invtype in ('M','S')
       AND D.invoice = H.invoice
       AND (D.billedqty != 0
        OR D.billedamt != 0)
       AND A.code = D.activity
       AND A.irisname is not null;

errmsg varchar2(100);

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
   where view_name = 'IRISANCL_DTL_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;


if in_custid != 'ALL' then
    select count(1)
      into cntRows
      from customer
     where custid = rtrim(in_custid);

    if cntRows = 0 then
      out_errorno := -1;
      out_msg := 'Invalid Customer Code';
      return;
    end if;
end if;

for ccus in C_CUSTID(in_custid) loop

    tblCompany := null;
    cmdSqlCompany := 'select abbrev from class_to_company_' ||
      rtrim(ccus.custid) || ' where code = ''RG'' ';
    begin
      curCompany := dbms_sql.open_cursor;
      dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
      dbms_sql.define_column(curCompany,1,tblCompany,12);
      cntRows := dbms_sql.execute(curCompany);
      cntRows := dbms_sql.fetch_rows(curCompany);
      if cntRows > 0 then
        dbms_sql.column_value(curCompany,1,tblCompany);
      else
          out_msg := 'class_to_company_'
                  ||rtrim(ccus.custid) ||': RG Entry not defined';
          out_errorno := -100;
      end if;
      dbms_sql.close_cursor(curCompany);
    exception when others then
          dbms_sql.close_cursor(curCompany);
          out_msg := 'class_to_company_'
                  ||rtrim(ccus.custid) ||': '|| substr(sqlerrm,1,80);
          out_errorno := sqlcode;
    end;

    if tblCompany is null then
          rollback;
          zms.log_msg('IRISAncl', '', ccus.custid,
                   out_msg,
                   'E', 'ImpExp', errmsg);
          commit;
          return;
    end if;


    tblWarehouse := null;
    cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
      rtrim(ccus.custid) || ' where code = ''RG'' ';
    begin
      curCompany := dbms_sql.open_cursor;
      dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
      dbms_sql.define_column(curCompany,1,tblWarehouse,12);
      cntRows := dbms_sql.execute(curCompany);
      cntRows := dbms_sql.fetch_rows(curCompany);
      if cntRows > 0 then
        dbms_sql.column_value(curCompany,1,tblWarehouse);
      else
          out_msg := 'class_to_warehouse_'
                  ||rtrim(ccus.custid) ||': RG Entry not defined';
          out_errorno := -100;

      end if;
      dbms_sql.close_cursor(curCompany);
    exception when others then
          dbms_sql.close_cursor(curCompany);
          out_msg := 'class_to_warehouse_'
                  ||rtrim(ccus.custid) ||': '|| substr(sqlerrm,1,80);
          out_errorno := sqlcode;
    end;

    if tblWarehouse is null then
          rollback;
          zms.log_msg('IRISAncl', '', ccus.custid,
                   out_msg,
                   'E', 'ImpExp', errmsg);
          commit;
          return;
    end if;

    -- Begin load of charges that apply for Ancillary charges
    for crec in C_INVD(ccus.custid, in_begdatestr, in_enddatestr) loop
      if crec.billstatus = '3' then
        insert into IrisAnclEx(
           sessionid,
           orderid,
           shipid,
           service,
           class,
           custid,
           company,
           warehouse,
           quantity,
           charge,
           postdate
        )
        values
        (
            strSuffix,
            crec.orderid,
            crec.shipid,
            crec.irisname,
            crec.irisclass,
            ccus.custid,
            tblcompany,
            tblWarehouse,
            crec.billedqty,
            decode(crec.irischarge,'Y',crec.billedamt, 0),
            crec.postdate
        );
      end if;
    end loop;

end loop;


-- Create view for ancillary extract
cmdSql := 'create view irisancl_dtl_' || strSuffix ||
 ' (custid,company,warehouse,orderid,shipid,reference,opendate,closedate,' ||
 ' name,serviceclass,servicename,servicefee,quantity,' ||
 ' shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,shiptocity,' ||
 ' shiptostate,shiptopostalcode,shiptocountrycode)' ||
 'as select I.custid,I.company,I.warehouse,I.orderid,I.shipid,' ||
 'OH.reference,nvl(OH.statusupdate,I.postdate),nvl(oh.statusupdate,I.postdate),C.name,I.class,' ||
 'I.service,substr(to_char(I.charge,''099999999999.99''),2),I.quantity,'||
 'OH.shiptoname,OH.shiptocontact,OH.shiptoaddr1,OH.shiptoaddr2,' ||
 'OH.shiptocity,OH.shiptostate,OH.shiptopostalcode,OH.shiptocountrycode '||
 ' from orderhdr OH, customer C, irisanclex I ' ||
 ' where I.sessionid = '''||strSuffix||''''||
 ' and C.custid  = I.custid  and OH.orderid(+) = I.orderid ' ||
 '   and OH.shipid(+) = I.shipid';
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
  out_msg := 'zimbia ' || sqlerrm;
  out_errorno := sqlcode;
end begin_irisancl;

----------------------------------------------------------------------
-- end_irisancl
----------------------------------------------------------------------
procedure end_irisancl
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



delete from irisanclex where sessionid = strSuffix;



cmdSql := 'drop VIEW irisancl_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeia ' || sqlerrm;
  out_errorno := sqlcode;
end end_irisancl;


procedure import_ursa_data
(in_zipcode IN varchar2
,in_state IN varchar2
,in_cityprefixes IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cntRows integer;
begin

out_msg := 'OKAY';
out_errorno := 0;

begin
  insert into ursa
  (zipcode,state,cityprefixes,lastuser,lastupdate)
  values
  (in_zipcode,in_state,in_cityprefixes,IMP_USERID,sysdate);
exception
  when dup_val_on_index then
    update ursa
       set cityprefixes = in_cityprefixes,
           lastuser = IMP_USERID,
           lastupdate = sysdate
     where zipcode = in_zipcode
       and state = in_state;
end;

exception when others then
  out_msg := 'ziud ' || substr(sqlerrm,1,2255);
  out_errorno := sqlcode;
end import_ursa_data;

procedure begin_rcptonly
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_include_zero_qty_orders_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is


cursor curOrderHdr is
  select *
    from orderhdr
   where statusupdate >= to_date(in_begdatestr, 'yyyymmddhh24miss')
     and statusupdate <  to_date(in_enddatestr, 'yyyymmddhh24miss')
     and custid = in_custid
     and ordertype||'' in ('R','C')
     and orderstatus||'' = 'R';
oh curOrderHdr%rowtype;

cursor curOrderDtlRcptSum(in_orderid number, in_shipid number) is
  select inventoryclass,
         sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(qtyrcvddmgd,0)) as qtyrcvddmgd
    from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
   group by inventoryclass;

cursor curOrderDtlRcpt(in_orderid number, in_shipid number) is
  select rc.item as item,
         rc.inventoryclass as inventoryclass,
         rc.lotnumber as lotnumber,
         rc.orderitem as orderitem,
         rc.orderlot as orderlot,
         rc.serialnumber as serialnumber,
         rc.useritem1 as useritem1,
         rc.useritem2 as useritem2,
         rc.useritem3 as useritem3,
         asn.trackingno as trackingno,
         asn.custreference as custreference,
         nvl(asn.qty,0) as qtyorder,
         sum(nvl(qtyrcvd,0)) as qtyrcvd,
         sum(nvl(qtyrcvdgood,0)) as qtyrcvdgood,
         sum(nvl(qtyrcvddmgd,0)) as qtyrcvddmgd
    from asncartondtl asn, orderdtlrcptsumview rc
   where rc.orderid = in_orderid
     and rc.shipid = in_shipid
     and rc.orderid = asn.orderid(+)
     and rc.shipid = asn.shipid(+)
     and rc.item = asn.item(+)
     and rc.qtyrcvd <> 0
     and nvl(rc.lotnumber,'x') = nvl(asn.lotnumber(+),'x')
     and nvl(rc.serialnumber,'x') = nvl(asn.serialnumber(+),'x')
     and nvl(rc.useritem1,'x') = nvl(asn.useritem1(+),'x')
     and nvl(rc.useritem2,'x') = nvl(asn.useritem2(+),'x')
     and nvl(rc.useritem3,'x') = nvl(asn.useritem3(+),'x')
   group by rc.item,rc.inventoryclass,rc.lotnumber,
            rc.orderitem,rc.orderlot,rc.serialnumber,
            rc.useritem1,rc.useritem2,rc.useritem3,asn.trackingno,
            asn.custreference,nvl(asn.qty,0);

cursor curOrderDtl(in_orderid number, in_shipid number,
                   in_item varchar2, in_lot varchar2) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lot,'(none)');

OD orderdtl%rowtype;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
strDebugYN char(1);
strWarehouse orderstatus.abbrev%type;
strCompany orderstatus.abbrev%type;
strShipperName shipper.name%type;

procedure debugmsg(in_text varchar2) is

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

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'RCPTONLY_HDR_' || strSuffix;
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

cmdSql := 'create table RCPTONLY_HDR_' || strSuffix ||
' (CUSTID VARCHAR2(10) not null,FACILITY VARCHAR2(3),' ||
' COMPANY VARCHAR2(12),WAREHOUSE VARCHAR2(12),' ||
' ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,RECEIPTDATE DATE,' ||
' VENDOR VARCHAR2(10),VENDORDESC VARCHAR2(40),BILLOFLADING VARCHAR2(40),' ||
' CARRIER VARCHAR2(10),PO VARCHAR2(20),REFERENCE VARCHAR2(20),ORDERTYPE VARCHAR2(1) not null,' ||
' HDRPASSTHRUCHAR01 VARCHAR2(255),HDRPASSTHRUCHAR02 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR03 VARCHAR2(255),HDRPASSTHRUCHAR04 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR05 VARCHAR2(255),HDRPASSTHRUCHAR06 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR07 VARCHAR2(255),HDRPASSTHRUCHAR08 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR09 VARCHAR2(255),HDRPASSTHRUCHAR10 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR11 VARCHAR2(255),HDRPASSTHRUCHAR12 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR13 VARCHAR2(255),HDRPASSTHRUCHAR14 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR15 VARCHAR2(255),HDRPASSTHRUCHAR16 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR17 VARCHAR2(255),HDRPASSTHRUCHAR18 VARCHAR2(255),' ||
' HDRPASSTHRUCHAR19 VARCHAR2(255),HDRPASSTHRUCHAR20 VARCHAR2(255),' ||
' HDRPASSTHRUNUM01 NUMBER(16,4),HDRPASSTHRUNUM02 NUMBER(16,4),HDRPASSTHRUNUM03 NUMBER(16,4),' ||
' HDRPASSTHRUNUM04 NUMBER(16,4),HDRPASSTHRUNUM05 NUMBER(16,4),HDRPASSTHRUNUM06 NUMBER(16,4),' ||
' HDRPASSTHRUNUM07 NUMBER(16,4),HDRPASSTHRUNUM08 NUMBER(16,4),HDRPASSTHRUNUM09 NUMBER(16,4),' ||
' HDRPASSTHRUNUM10 NUMBER(16,4),HDRPASSTHRUDATE01 DATE,HDRPASSTHRUDATE02 DATE,' ||
' HDRPASSTHRUDATE03 DATE,HDRPASSTHRUDATE04 DATE,HDRPASSTHRUDOLL01 NUMBER(10,2),' ||
' HDRPASSTHRUDOLL02 NUMBER(10,2),QTYRCVD NUMBER,QTYRCVDGOOD NUMBER,' ||
' QTYRCVDDMGD NUMBER )';
execute immediate cmdSql;

cmdSql := 'create table RCPTONLY_DTL_' || strSuffix ||
' (CUSTID VARCHAR2(10) not null,FACILITY VARCHAR2(3),' ||
' COMPANY VARCHAR2(12),WAREHOUSE VARCHAR2(12),' ||
' ORDERID NUMBER(9) not null,SHIPID NUMBER(2) not null,REFERENCE VARCHAR2(20),' ||
' RECEIPTDATE DATE,item varchar2(50),LOTNUMBER VARCHAR2(30),SERIALNUMBER VARCHAR2(30),' ||
' USERITEM1 VARCHAR2(20),USERITEM2 VARCHAR2(20),USERITEM3 VARCHAR2(20),' ||
' TRACKINGNO VARCHAR2(22),CUSTREFERENCE VARCHAR2(30),BILLOFLADING VARCHAR2(40),' ||
' PO VARCHAR2(20),QTYORDER NUMBER,HDRPASSTHRUCHAR01 VARCHAR2(255),' ||
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
' HDRPASSTHRUDOLL01 NUMBER(10,2),HDRPASSTHRUDOLL02 NUMBER(10,2),QTYRCVD NUMBER,' ||
' QTYRCVDGOOD NUMBER,QTYRCVDDMGD NUMBER, '||
' DTLPASSTHRUCHAR01 VARCHAR2(255),DTLPASSTHRUCHAR02 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR03 VARCHAR2(255),DTLPASSTHRUCHAR04 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR05 VARCHAR2(255),DTLPASSTHRUCHAR06 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR07 VARCHAR2(255),DTLPASSTHRUCHAR08 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR09 VARCHAR2(255),DTLPASSTHRUCHAR10 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR11 VARCHAR2(255),DTLPASSTHRUCHAR12 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR13 VARCHAR2(255),DTLPASSTHRUCHAR14 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR15 VARCHAR2(255),DTLPASSTHRUCHAR16 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR17 VARCHAR2(255),DTLPASSTHRUCHAR18 VARCHAR2(255),' ||
' DTLPASSTHRUCHAR19 VARCHAR2(255),DTLPASSTHRUCHAR20 VARCHAR2(255),' ||
' DTLPASSTHRUNUM01 NUMBER(16,4),DTLPASSTHRUNUM02 NUMBER(16,4),' ||
' DTLPASSTHRUNUM03 NUMBER(16,4),DTLPASSTHRUNUM04 NUMBER(16,4),' ||
' DTLPASSTHRUNUM05 NUMBER(16,4),DTLPASSTHRUNUM06 NUMBER(16,4),' ||
' DTLPASSTHRUNUM07 NUMBER(16,4),DTLPASSTHRUNUM08 NUMBER(16,4),' ||
' DTLPASSTHRUNUM09 NUMBER(16,4),DTLPASSTHRUNUM10 NUMBER(16,4),' ||
' DTLPASSTHRUDATE01 DATE,DTLPASSTHRUDATE02 DATE,' ||
' DTLPASSTHRUDATE03 DATE,DTLPASSTHRUDATE04 DATE,' ||
' DTLPASSTHRUDOLL01 NUMBER(10,2),DTLPASSTHRUDOLL02 NUMBER(10,2) )';

execute immediate cmdSql;

debugmsg('curOrderHdr loop');
for oh in curOrderHdr
loop
  if (nvl(rtrim(in_include_zero_qty_orders_yn),'N') != 'Y') and
     (nvl(oh.qtyrcvd,0) = 0) then
     goto continue_order_loop;
  end if;
  debugmsg('curOrderDtlRcptSum loop for ' || oh.orderid || '-' || oh.shipid);
  for rc in curOrderDtlRcptSum(oh.orderid,oh.shipid)
  loop

    strCompany := null;
    cmdSql := 'select abbrev from class_to_company_' || in_custid ||
      ' where code = ''' || rc.inventoryclass || '''';
    debugmsg(cmdSql);
    begin
      execute immediate cmdSql into strcompany;
    exception when others then
      debugmsg(sqlerrm);
    end;
    if strcompany is null then
      strcompany := rc.inventoryclass;
    end if;

    strWarehouse := null;
    cmdSql := 'select abbrev from class_to_warehouse_' || in_custid ||
      ' where code = ''' || rc.inventoryclass || '''';
    debugmsg(cmdSql);
    begin
      execute immediate cmdSql into strwarehouse;
    exception when others then
      debugmsg(sqlerrm);
    end;
    if strwarehouse is null then
      strwarehouse := rc.inventoryclass;
    end if;

    strShipperName := null;
    cmdSql := 'select name from shipper where shipper = ''' || oh.shipper || '''';
    debugmsg(cmdSql);
    begin
      execute immediate cmdSql into strshippername;
    exception when others then
      debugmsg(sqlerrm);
    end;

    execute immediate 'insert into RCPTONLY_HDR_' || strSuffix ||
    ' values (:CUSTID,:FACILITY,:COMPANY,:WAREHOUSE,:ORDERID,:SHIPID,:RECEIPTDATE,' ||
    ' :VENDOR,:VENDORDESC,:BILLOFLADING,:CARRIER,:PO,:REFERENCE,:ORDERTYPE,' ||
    ' :HDRPASSTHRUCHAR01,:HDRPASSTHRUCHAR02,:HDRPASSTHRUCHAR03,:HDRPASSTHRUCHAR04,' ||
    ' :HDRPASSTHRUCHAR05,:HDRPASSTHRUCHAR06,:HDRPASSTHRUCHAR07,:HDRPASSTHRUCHAR08,' ||
    ' :HDRPASSTHRUCHAR09,:HDRPASSTHRUCHAR10,:HDRPASSTHRUCHAR11,:HDRPASSTHRUCHAR12,' ||
    ' :HDRPASSTHRUCHAR13,:HDRPASSTHRUCHAR14,:HDRPASSTHRUCHAR15,:HDRPASSTHRUCHAR16,' ||
    ' :HDRPASSTHRUCHAR17,:HDRPASSTHRUCHAR18,:HDRPASSTHRUCHAR19,:HDRPASSTHRUCHAR20,' ||
    ' :HDRPASSTHRUNUM01,:HDRPASSTHRUNUM02,:HDRPASSTHRUNUM03,:HDRPASSTHRUNUM04,' ||
    ' :HDRPASSTHRUNUM05,:HDRPASSTHRUNUM06,:HDRPASSTHRUNUM07,:HDRPASSTHRUNUM08,' ||
    ' :HDRPASSTHRUNUM09,:HDRPASSTHRUNUM10,:HDRPASSTHRUDATE01,:HDRPASSTHRUDATE02,' ||
    ' :HDRPASSTHRUDATE03,:HDRPASSTHRUDATE04,:HDRPASSTHRUDOLL01,:HDRPASSTHRUDOLL02,' ||
    ' :QTYRCVD,:QTYRCVDGOOD,:QTYRCVDDMGD )'
    using oh.CUSTID,oh.TOFACILITY, strcompany,strwarehouse,oh.ORDERID,oh.SHIPID,oh.statusupdate,
    oh.shipper,strshippername,oh.BILLOFLADING,oh.CARRIER,oh.PO,oh.REFERENCE,
    oh.ORDERTYPE,oh.HDRPASSTHRUCHAR01,oh.HDRPASSTHRUCHAR02,oh.HDRPASSTHRUCHAR03,
    oh.HDRPASSTHRUCHAR04,oh.HDRPASSTHRUCHAR05,oh.HDRPASSTHRUCHAR06,oh.HDRPASSTHRUCHAR07,
    oh.HDRPASSTHRUCHAR08,oh.HDRPASSTHRUCHAR09,oh.HDRPASSTHRUCHAR10,oh.HDRPASSTHRUCHAR11,
    oh.HDRPASSTHRUCHAR12,oh.HDRPASSTHRUCHAR13,oh.HDRPASSTHRUCHAR14,oh.HDRPASSTHRUCHAR15,
    oh.HDRPASSTHRUCHAR16,oh.HDRPASSTHRUCHAR17,oh.HDRPASSTHRUCHAR18,oh.HDRPASSTHRUCHAR19,
    oh.HDRPASSTHRUCHAR20,oh.HDRPASSTHRUNUM01,oh.HDRPASSTHRUNUM02,oh.HDRPASSTHRUNUM03,
    oh.HDRPASSTHRUNUM04,oh.HDRPASSTHRUNUM05,oh.HDRPASSTHRUNUM06,oh.HDRPASSTHRUNUM07,
    oh.HDRPASSTHRUNUM08,oh.HDRPASSTHRUNUM09,oh.HDRPASSTHRUNUM10,oh.HDRPASSTHRUDATE01,
    oh.HDRPASSTHRUDATE02,oh.HDRPASSTHRUDATE03,oh.HDRPASSTHRUDATE04,oh.HDRPASSTHRUDOLL01,
    oh.HDRPASSTHRUDOLL02,rc.QTYRCVD,rc.QTYRCVDGOOD,rc.QTYRCVDDMGD;
  end loop;
  for rc in curOrderDtlRcpt(oh.orderid,oh.shipid)
  loop
    strCompany := null;
    cmdSql := 'select abbrev from class_to_company_' || in_custid ||
      ' where code = ''' || rc.inventoryclass || '''';
    debugmsg(cmdSql);
    begin
      execute immediate cmdSql into strcompany;
    exception when others then
      debugmsg(sqlerrm);
    end;
    if rtrim(strcompany) is null then
      strcompany := rc.inventoryclass;
    end if;

    strWarehouse := null;
    cmdSql := 'select abbrev from class_to_warehouse_' || in_custid ||
      ' where code = ''' || rc.inventoryclass || '''';
    debugmsg(cmdSql);
    begin
      execute immediate cmdSql into strwarehouse;
    exception when others then
      debugmsg(sqlerrm);
    end;
    if rtrim(strwarehouse) is null then
      strwarehouse := rc.inventoryclass;
    end if;

    strShipperName := null;
    cmdSql := 'select name from shipper where shipper = ''' || oh.shipper || '''';
    debugmsg(cmdSql);
    begin
      execute immediate cmdSql into strshippername;
    exception when others then
      debugmsg(sqlerrm);
    end;

    OD := null;
    OPEN curOrderDtl(OH.orderid, OH.shipid, rc.orderitem, rc.orderlot);
    FETCH curOrderDtl into OD;
    CLOSE curOrderDtl;


    execute immediate 'insert into RCPTONLY_DTL_' || strSuffix ||
    ' values (:CUSTID,:FACILITY,:COMPANY,:WAREHOUSE,:ORDERID,:SHIPID,:REFERENCE,' ||
    ' :RECEIPTDATE,:ITEM,:LOTNUMBER,:SERIALNUMBER,:USERITEM1,:USERITEM2,' ||
    ' :USERITEM3,:TRACKINGNO,:CUSTREFERENCE,:BILLOFLADING,:PO,:QTYORDER,' ||
    ' :HDRPASSTHRUCHAR01,:HDRPASSTHRUCHAR02,:HDRPASSTHRUCHAR03,:HDRPASSTHRUCHAR04,' ||
    ' :HDRPASSTHRUCHAR05,:HDRPASSTHRUCHAR06,:HDRPASSTHRUCHAR07,:HDRPASSTHRUCHAR08,' ||
    ' :HDRPASSTHRUCHAR09,:HDRPASSTHRUCHAR10,:HDRPASSTHRUCHAR11,:HDRPASSTHRUCHAR12,' ||
    ' :HDRPASSTHRUCHAR13,:HDRPASSTHRUCHAR14,:HDRPASSTHRUCHAR15,:HDRPASSTHRUCHAR16,' ||
    ' :HDRPASSTHRUCHAR17,:HDRPASSTHRUCHAR18,:HDRPASSTHRUCHAR19,:HDRPASSTHRUCHAR20,' ||
    ' :HDRPASSTHRUNUM01,:HDRPASSTHRUNUM02,:HDRPASSTHRUNUM03,:HDRPASSTHRUNUM04,' ||
    ' :HDRPASSTHRUNUM05,:HDRPASSTHRUNUM06,:HDRPASSTHRUNUM07,:HDRPASSTHRUNUM08,' ||
    ' :HDRPASSTHRUNUM09,:HDRPASSTHRUNUM10,:HDRPASSTHRUDATE01,:HDRPASSTHRUDATE02,' ||
    ' :HDRPASSTHRUDATE03,:HDRPASSTHRUDATE04,:HDRPASSTHRUDOLL01,:HDRPASSTHRUDOLL02,' ||
    ' :QTYRCVD,:QTYRCVDGOOD,:QTYRCVDDMGD, ' ||
    ' :DTLPASSTHRUCHAR01,:DTLPASSTHRUCHAR02,:DTLPASSTHRUCHAR03,:DTLPASSTHRUCHAR04,' ||
    ' :DTLPASSTHRUCHAR05,:DTLPASSTHRUCHAR06,:DTLPASSTHRUCHAR07,:DTLPASSTHRUCHAR08,' ||
    ' :DTLPASSTHRUCHAR09,:DTLPASSTHRUCHAR10,:DTLPASSTHRUCHAR11,:DTLPASSTHRUCHAR12,' ||
    ' :DTLPASSTHRUCHAR13,:DTLPASSTHRUCHAR14,:DTLPASSTHRUCHAR15,:DTLPASSTHRUCHAR16,' ||
    ' :DTLPASSTHRUCHAR17,:DTLPASSTHRUCHAR18,:DTLPASSTHRUCHAR19,:DTLPASSTHRUCHAR20,' ||
    ' :DTLPASSTHRUNUM01,:DTLPASSTHRUNUM02,:DTLPASSTHRUNUM03,:DTLPASSTHRUNUM04,' ||
    ' :DTLPASSTHRUNUM05,:DTLPASSTHRUNUM06,:DTLPASSTHRUNUM07,:DTLPASSTHRUNUM08,' ||
    ' :DTLPASSTHRUNUM09,:DTLPASSTHRUNUM10,:DTLPASSTHRUDATE01,:DTLPASSTHRUDATE02,' ||
    ' :DTLPASSTHRUDATE03,:DTLPASSTHRUDATE04,:DTLPASSTHRUDOLL01,:DTLPASSTHRUDOLL02 )'
    using oh.CUSTID,oh.TOFACILITY, strCOMPANY,strWAREHOUSE,oh.ORDERID,oh.SHIPID,oh.REFERENCE,
    oh.statusupdate,rc.ITEM,rc.LOTNUMBER,rc.SERIALNUMBER,rc.USERITEM1,
    rc.USERITEM2,rc.USERITEM3,rc.TRACKINGNO,rc.CUSTREFERENCE,oh.BILLOFLADING,
    oh.PO,rc.QTYORDER,oh.HDRPASSTHRUCHAR01,oh.HDRPASSTHRUCHAR02,oh.HDRPASSTHRUCHAR03,
    oh.HDRPASSTHRUCHAR04,oh.HDRPASSTHRUCHAR05,oh.HDRPASSTHRUCHAR06,oh.HDRPASSTHRUCHAR07,
    oh.HDRPASSTHRUCHAR08,oh.HDRPASSTHRUCHAR09,oh.HDRPASSTHRUCHAR10,oh.HDRPASSTHRUCHAR11,
    oh.HDRPASSTHRUCHAR12,oh.HDRPASSTHRUCHAR13,oh.HDRPASSTHRUCHAR14,oh.HDRPASSTHRUCHAR15,
    oh.HDRPASSTHRUCHAR16,oh.HDRPASSTHRUCHAR17,oh.HDRPASSTHRUCHAR18,oh.HDRPASSTHRUCHAR19,
    oh.HDRPASSTHRUCHAR20,oh.HDRPASSTHRUNUM01,oh.HDRPASSTHRUNUM02,oh.HDRPASSTHRUNUM03,
    oh.HDRPASSTHRUNUM04,oh.HDRPASSTHRUNUM05,oh.HDRPASSTHRUNUM06,oh.HDRPASSTHRUNUM07,
    oh.HDRPASSTHRUNUM08,oh.HDRPASSTHRUNUM09,oh.HDRPASSTHRUNUM10,oh.HDRPASSTHRUDATE01,
    oh.HDRPASSTHRUDATE02,oh.HDRPASSTHRUDATE03,oh.HDRPASSTHRUDATE04,oh.HDRPASSTHRUDOLL01,
    oh.HDRPASSTHRUDOLL02,rc.QTYRCVD,rc.QTYRCVDGOOD,rc.QTYRCVDDMGD,
    OD.DTLPASSTHRUCHAR01,OD.DTLPASSTHRUCHAR02,OD.DTLPASSTHRUCHAR03,
    OD.DTLPASSTHRUCHAR04,OD.DTLPASSTHRUCHAR05,OD.DTLPASSTHRUCHAR06,OD.DTLPASSTHRUCHAR07,
    OD.DTLPASSTHRUCHAR08,OD.DTLPASSTHRUCHAR09,OD.DTLPASSTHRUCHAR10,OD.DTLPASSTHRUCHAR11,
    OD.DTLPASSTHRUCHAR12,OD.DTLPASSTHRUCHAR13,OD.DTLPASSTHRUCHAR14,OD.DTLPASSTHRUCHAR15,
    OD.DTLPASSTHRUCHAR16,OD.DTLPASSTHRUCHAR17,OD.DTLPASSTHRUCHAR18,OD.DTLPASSTHRUCHAR19,
    OD.DTLPASSTHRUCHAR20,OD.DTLPASSTHRUNUM01,OD.DTLPASSTHRUNUM02,OD.DTLPASSTHRUNUM03,
    OD.DTLPASSTHRUNUM04,OD.DTLPASSTHRUNUM05,OD.DTLPASSTHRUNUM06,OD.DTLPASSTHRUNUM07,
    OD.DTLPASSTHRUNUM08,OD.DTLPASSTHRUNUM09,OD.DTLPASSTHRUNUM10,OD.DTLPASSTHRUDATE01,
    OD.DTLPASSTHRUDATE02,OD.DTLPASSTHRUDATE03,OD.DTLPASSTHRUDATE04,OD.DTLPASSTHRUDOLL01,
    OD.DTLPASSTHRUDOLL02;

  end loop;
<< continue_order_loop >>
  null;
end loop;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbro ' || sqlerrm;
  out_errorno := sqlcode;
end begin_rcptonly;

procedure end_rcptonly
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

cmdSql := 'drop table rcptonly_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop table rcptonly_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimero ' || sqlerrm;
  out_errorno := sqlcode;
end end_rcptonly;

procedure begin_rtrnonly
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
   where view_name = 'RTRNONLY_HDR_' || strSuffix;
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

cmdSql := 'create view rtrnonly_hdr_' || strSuffix ||
  ' (custid,company,warehouse,orderid,shipid,receiptdate,' ||
  'vendor,vendordesc,billoflading,carrier,po,ordertype,reference, ' ||
  'origorderid,origshipid,qtyrcvd,' ||
  'qtyrcvdgood,qtyrcvddmgd) ' ||
  ' as select oh.custid,nvl(cc.abbrev,rc.inventoryclass), ' ||
  'nvl(cw.abbrev,rc.inventoryclass),oh.orderid,oh.shipid, ' ||
  'oh.statusupdate,oh.shipper,sh.name,oh.billoflading,oh.carrier, ' ||
  'oh.po,oh.ordertype,oh.reference,oh.origorderid,oh.origshipid, ' ||
  'sum(rc.qtyrcvd),sum(rc.qtyrcvdgood),sum(rc.qtyrcvddmgd) ' ||
  'from class_to_company_' || rtrim(in_custid) || ' cc, ' ||
  'class_to_warehouse_' || rtrim(in_custid) || ' cw, ' ||
  '   shipper sh, orderdtlrcptsumview rc, orderhdr oh ' ||
  'where oh.orderstatus = ''R'' and oh.orderid = rc.orderid ' ||
  'and oh.ordertype = ''Q''' ||
  'and oh.custid = ''' || rtrim(in_custid) || '''' ||
  'and oh.shipid = rc.shipid and oh.shipper = sh.shipper(+) ' ||
  'and oh.custid = ''' || rtrim(in_custid) || '''' ||
  'and oh.qtyrcvd <> 0 ' ||
  'and rc.inventoryclass = cc.code(+) and rc.inventoryclass = cw.code(+) ' ||
  'and oh.statusupdate >= to_date(''' || in_begdatestr ||
  ''', ''yyyymmddhh24miss'')' ||
  ' and oh.statusupdate <  to_date(''' || in_enddatestr ||
  ''', ''yyyymmddhh24miss'') ' ||
  'group by oh.custid,nvl(cc.abbrev,rc.inventoryclass), ' ||
  'nvl(cw.abbrev,rc.inventoryclass), ' ||
  'oh.orderid,oh.shipid,statusupdate, ' ||
  'oh.shipper,sh.name,oh.billoflading,oh.carrier,oh.po, ' ||
  'oh.reference,oh.ordertype,oh.origorderid,oh.origshipid ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view rtrnonly_dtl_' || strSuffix ||
  ' (custid,company,warehouse,orderid,shipid,reference,receiptdate,' ||
  'item,lotnumber,serialnumber,useritem1,useritem2,useritem3, ' ||
  'trackingno,custreference,origreference,origtrackingno,reasoncode, ' ||
  'billoflading, ' ||
  'qytorder,qtyrcvd,qtyrcvdgood,qtyrcvddmgd) ' ||
  ' as select oh.custid,' ||
  'nvl(cc.abbrev,rc.inventoryclass),nvl(cw.abbrev,rc.inventoryclass), ' ||
  'oh.orderid,oh.shipid,oh.reference,oh.receiptdate, ' ||
  'rc.item,rc.lotnumber,rc.serialnumber, ' ||
  'rc.useritem1,rc.useritem2,rc.useritem3, ' ||
  'asn.trackingno,asn.custreference, ' ||
  'zoe.order_reference(oh.origorderid,oh.origshipid), ' ||
  'zoe.outbound_trackingno(oh.origorderid,oh.origshipid,rc.item, ' ||
  'rc.lotnumber,rc.serialnumber,  ' ||
  'rc.useritem1,rc.useritem2,rc.useritem3), ' ||
  'zoe.inbound_condition(oh.orderid,oh.shipid,rc.item, ' ||
  'rc.lotnumber,rc.serialnumber,  ' ||
  'rc.useritem1,rc.useritem2,rc.useritem3),oh.billoflading, ' ||
  'nvl(asn.qty,0), ' ||
  'sum(rc.qtyrcvd), ' ||
  'sum(rc.qtyrcvdgood), ' ||
  'sum(rc.qtyrcvddmgd) ' ||
  ' from class_to_company_' || rtrim(in_custid) ||
  ' cc, class_to_warehouse_' || rtrim(in_custid) || ' cw, ' ||
  ' asncartondtl asn, ' ||
  'orderdtlrcptsumview rc, rtrnonly_hdr_' || strSuffix || ' oh where oh.orderid = rc.orderid ' ||
  'and oh.shipid = rc.shipid ' ||
  'and rc.inventoryclass = cc.code(+) and rc.inventoryclass = cw.code(+) ' ||
  'and rc.orderid = asn.orderid(+) ' ||
  'and rc.shipid = asn.shipid(+) ' ||
  'and rc.item = asn.item(+) ' ||
  'and rc.qtyrcvd <> 0 ' ||
  'and nvl(rc.lotnumber,''x'') = nvl(asn.lotnumber(+),''x'') ' ||
  'and nvl(rc.serialnumber,''x'') = nvl(asn.serialnumber(+),''x'') ' ||
  'and nvl(rc.useritem1,''x'') = nvl(asn.useritem1(+),''x'') ' ||
  'and nvl(rc.useritem2,''x'') = nvl(asn.useritem2(+),''x'') ' ||
  'and nvl(rc.useritem3,''x'') = nvl(asn.useritem3(+),''x'') ' ||
  'group by oh.custid,nvl(cc.abbrev,rc.inventoryclass), ' ||
  'nvl(cw.abbrev,rc.inventoryclass),oh.orderid,oh.shipid,oh.reference,oh.receiptdate, ' ||
  'rc.item,rc.lotnumber,rc.serialnumber,' ||
  'rc.useritem1,rc.useritem2,rc.useritem3, ' ||
  'asn.trackingno,asn.custreference, ' ||
  'zoe.order_reference(oh.origorderid,oh.origshipid), ' ||
  'zoe.outbound_trackingno(oh.origorderid,oh.origshipid,rc.item, ' ||
  'rc.lotnumber,rc.serialnumber, ' ||
  'rc.useritem1,rc.useritem2,rc.useritem3), ' ||
  'zoe.inbound_condition(oh.orderid,oh.shipid,rc.item, ' ||
  'rc.lotnumber,rc.serialnumber, ' ||
  'rc.useritem1,rc.useritem2,rc.useritem3),oh.billoflading, ' ||
  'nvl(asn.qty,0) ';
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
  out_msg := 'zimbro ' || sqlerrm;
  out_errorno := sqlcode;
end begin_rtrnonly;

procedure end_rtrnonly
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

cmdSql := 'drop view rtrnonly_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view rtrnonly_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimero ' || sqlerrm;
  out_errorno := sqlcode;
end end_rtrnonly;

procedure import_asn_item_hdr_Kraft
(in_custid IN varchar2
,in_allow_prod_arrived IN varchar2
,in_ordertype IN varchar2
,in_apptdate IN date
,in_po IN varchar2
,in_rma IN varchar2
,in_tofacility IN varchar2
,in_billoflading IN varchar2
,in_priority IN varchar2
,in_shipper IN varchar2
,in_carrier IN varchar2
,in_reference IN varchar2
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
,in_editransaction IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) 
is

cursor curOrderHdr is
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
oh curOrderHdr%rowtype;
   
strReference orderhdr.reference%type;
errorno integer;
msg varchar2(255) := null;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference)
      ||' PO. '||rtrim(in_po)|| ': ' || out_msg;

  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;

  zms.log_msg(IMP_USERID, in_tofacility, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderHdr%found then
  out_orderid := oh.orderid;
  out_shipid := oh.shipid;
end if;
close curOrderhdr;

if out_orderid != 0 then
  if oh.orderstatus > '1' then
    out_errorno := 2;
    out_msg := 'Invalid Order Status for replace: ' || oh.orderstatus;
    order_msg('E');
    return;
  end if;

  if nvl(oh.loadno, 0) > 0 then
    zld.deassign_order_from_load(out_orderid, out_shipid, oh.facility, IMP_USERID,
         'N', errorno, msg);
  end if;

  begin
    delete from orderhdrbolcomments
     where orderid = out_orderid
       and shipid = out_shipid;
    delete from orderdtlbolcomments
     where orderid = out_orderid
       and shipid = out_shipid;
    delete from orderdtlline
     where orderid = out_orderid
       and shipid = out_shipid;
    delete from orderdtl
     where orderid = out_orderid
       and shipid = out_shipid;
    delete from asncartondtl
     where orderid = out_orderid
       and shipid = out_shipid;
    delete from orderhdr
     where orderid = out_orderid
       and shipid = out_shipid;
  exception when others then
    null;
  end;

   out_msg := 'Order replace transaction processed';
   order_msg('I');
end if;

zim3.import_asn_item_hdr
(in_custid,in_allow_prod_arrived,in_ordertype,in_apptdate 
,in_po,in_rma,in_tofacility,in_billoflading,in_priority 
,in_shipper,in_carrier,in_reference,in_importfileid 
,in_hdrpassthruchar01,in_hdrpassthruchar02,in_hdrpassthruchar03 
,in_hdrpassthruchar04,in_hdrpassthruchar05,in_hdrpassthruchar06 
,in_hdrpassthruchar07,in_hdrpassthruchar08,in_hdrpassthruchar09 
,in_hdrpassthruchar10,in_hdrpassthruchar11,in_hdrpassthruchar12 
,in_hdrpassthruchar13,in_hdrpassthruchar14,in_hdrpassthruchar15 
,in_hdrpassthruchar16,in_hdrpassthruchar17,in_hdrpassthruchar18 
,in_hdrpassthruchar19,in_hdrpassthruchar20,in_hdrpassthrunum01 
,in_hdrpassthrunum02,in_hdrpassthrunum03,in_hdrpassthrunum04 
,in_hdrpassthrunum05,in_hdrpassthrunum06,in_hdrpassthrunum07 
,in_hdrpassthrunum08,in_hdrpassthrunum09,in_hdrpassthrunum10 
,in_shippername,in_shippercontact,in_shipperaddr1,in_shipperaddr2 
,in_shippercity,in_shipperstate,in_shipperpostalcode 
,in_shippercountrycode,in_shipperphone,in_shipperfax,in_shipperemail
,nvl(in_editransaction,'856'),out_orderid,out_shipid,out_errorno,out_msg 
);

exception when others then
  out_msg := 'zimaihk ' || sqlerrm;
  out_errorno := sqlcode;
end import_asn_item_hdr_Kraft;


procedure import_asn_item_dtl_Kraft
(in_custid IN varchar2
,in_allow_prod_arrived IN varchar2
,in_reference IN varchar2
,in_po IN varchar2
,in_importfileid IN varchar2
,in_trackingno IN varchar2
,in_itementered IN varchar2
,in_lotnumber IN varchar2
,in_serialnumber IN varchar2
,in_useritem1 IN varchar2
,in_useritem2 IN varchar2
,in_useritem3 IN varchar2
,in_inventoryclass IN varchar2
,in_uom IN varchar2
,in_quantity IN number
,in_custreference varchar2
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
,in_dtlcomment IN varchar2
,in_expdate IN date
,in_weight IN number
,in_outbound_consignee IN varchar2
,in_ordertype IN varchar2
,in_assign_lineno IN varchar2
,in_weight_is_kg in varchar2
,in_manufacturedate IN date
,in_invstatus IN varchar2
,in_editransaction IN varchar2
,out_orderid IN OUT number
,out_shipid IN OUT number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) 
is

cursor curOrderHdr is
  select orderid,
         shipid,
         orderstatus,
         ordertype,
         tofacility,
         editransaction
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderstatus;
oh curOrderHdr%rowtype;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(in_reference)
      ||' PO. '||rtrim(in_po)|| ': ' || out_msg;

  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;

  zms.log_msg(IMP_USERID, null, rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;

oh := null;
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
   order_msg('E');
   return;
end if;

if rtrim(in_editransaction) != oh.editransaction then
   out_errorno := 6;
   out_msg := 'Detail edi not the same as Header edi: '||
       oh.orderid||'-'||oh.shipid||' '||in_reference||'  '||
       'Header. '||oh.editransaction||' Detail. '||rtrim(in_editransaction);
   order_msg('E');
   return;
end if;

zim3.import_asn_item_dtl
(in_custid,in_allow_prod_arrived,in_reference,in_po,in_importfileid
,in_trackingno,in_itementered,in_lotnumber,in_serialnumber
,in_useritem1,in_useritem2,in_useritem3,in_inventoryclass 
,in_uom,in_quantity,in_custreference,in_dtlpassthruchar01 
,in_dtlpassthruchar02,in_dtlpassthruchar03,in_dtlpassthruchar04 
,in_dtlpassthruchar05,in_dtlpassthruchar06,in_dtlpassthruchar07 
,in_dtlpassthruchar08,in_dtlpassthruchar09,in_dtlpassthruchar10 
,in_dtlpassthruchar11,in_dtlpassthruchar12,in_dtlpassthruchar13 
,in_dtlpassthruchar14,in_dtlpassthruchar15,in_dtlpassthruchar16 
,in_dtlpassthruchar17,in_dtlpassthruchar18,in_dtlpassthruchar19 
,in_dtlpassthruchar20,in_dtlpassthrunum01,in_dtlpassthrunum02 
,in_dtlpassthrunum03,in_dtlpassthrunum04,in_dtlpassthrunum05 
,in_dtlpassthrunum06,in_dtlpassthrunum07,in_dtlpassthrunum08 
,in_dtlpassthrunum09,in_dtlpassthrunum10,in_dtlcomment 
,in_expdate,in_weight,in_outbound_consignee,in_ordertype 
,in_assign_lineno,in_weight_is_kg,in_manufacturedate 
,in_invstatus,out_orderid,out_shipid,out_errorno,out_msg 
);

exception when others then
  out_msg := 'zimaidk ' || sqlerrm;
  out_errorno := sqlcode;
end import_asn_item_dtl_Kraft;


end zimportproc3;
/
show error package body zimportproc3;
exit;

