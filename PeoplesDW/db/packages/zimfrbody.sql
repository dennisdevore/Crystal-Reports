create or replace package body alps.zimportprocsfr as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';


procedure import_order_linefr
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
         ordertype
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
         ordertype
    from orderhdr
   where custid = rtrim(in_custid)
     and reference = rtrim(in_reference)
     and 'Y' = zedi.import_po(rtrim(in_custid), rtrim(in_po), po)
   order by orderid desc, shipid desc;
oh curOrderHdr%rowtype;

cursor curCustomer is
  select nvl(linenumbersyn,'N') as linenumbersyn,
         nvl(recv_line_check_yn,'N') as recv_line_check_yn,
         nvl(dup_reference_ynw,'N') as dup_reference_ynw
    from customer
   where custid = rtrim(in_custid);
cs curCustomer%rowtype;

cursor curOrderDtl(in_lotnumber varchar2) is
  select *
    from orderdtl
   where orderid = out_orderid
     and shipid = out_shipid
     and itementered = rtrim(in_itementered)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)');
od curOrderDtl%rowtype;

cursor curOrderDtlLineCount(in_item varchar2, in_lotnumber varchar2) is
  select count(1) as count
    from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = rtrim(in_item)
     and nvl(lotnumber,'(none)') = nvl(rtrim(in_lotnumber),'(none)')
     and nvl(xdock,'N') = 'N';
olc curOrderDtlLineCount%rowtype;

cursor curOrderDtlLine(in_item varchar2, in_linenumber number, in_lotnumber varchar2) is
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
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
strItem custitem.item%type;
strLineNumbers char(1);
dtedtlpassthrudate01 date;
dtedtlpassthrudate02 date;
dtedtlpassthrudate03 date;
dtedtlpassthrudate04 date;
l_comment long;
numQtyEntered orderdtl.qtyentered%type;
numWeight_Entered_Lbs orderdtl.weight_entered_lbs%type;
numWeight_Entered_Kgs orderdtl.weight_entered_kgs%type;
Order_by_weight boolean;
cntEntered integer;
strReference orderhdr.reference%type;
LineNumber integer;
cntRows integer;
strLotnumber orderdtl.lotnumber%type;
msgseq integer;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  msgseq := msgseq + 1;
  out_msg := ' Cust. ' || rtrim(in_custid) || ' Ref. ' || rtrim(strReference) || ': ' || out_msg;
  if out_orderid != 0 then
    out_msg := 'Order ' || out_orderid || '-' || out_shipid || ' ' || out_msg;
  end if;
  out_msg := 'Item ' || rtrim(in_itementered) || '/' || nvl(rtrim(strLotnumber),'(none)')
    || ' ' || out_msg;
  out_msg :=  to_char(msgseq,'FM0999') || ' ' || out_msg;
  zms.log_msg(IMP_USERID, nvl(oh.fromfacility,oh.tofacility), rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
end;


begin

out_errorno := 0;
out_msg := '';
out_orderid := 0;
out_shipid := 0;
msgseq := 0;
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

open curCustomer;
fetch curCustomer into cs;
if curCustomer%notfound then
  cs.linenumbersyn := 'N';
  cs.dup_reference_ynw := 'N';
end if;
close curCustomer;
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

strLotnumber := in_dtlpassthruchar02 || in_dtlpassthruchar01;



od := null;
open curOrderDtl(strLotnumber);
fetch curOrderDtl into od;
if curOrderDtl%found then
  chk.item := od.item;
  chk.lotnumber := od.lotnumber;
else
  chk.item := null;
  chk.lotnumber := null;
end if;
close curOrderDtl;

select count(1) into cntRows
   from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid;
if cntRows = 0 then
   LineNumber := 1;
else
   LineNumber := cntRows + 1;
end if;

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
  if nvl(LineNumber,0) <= 0 then
    out_errorno := 5;
    out_msg := 'Invalid Line Number: ' || LineNumber;
    item_msg('E');
    return;
  end if;
  open curOrderDtlLineCount(strItem, strLotnumber);
  fetch curOrderDtlLineCount into olc;
  if curOrderDtlLineCount%notfound then
    olc.count := 0;
  end if;
  close curOrderDtlLineCount;
  chk.linenumber := null;
  if olc.count != 0 then
    open curOrderDtlLine(strItem,LineNumber,strLotnumber);
    fetch curOrderDtlLine into ol;
    if curOrderDtlLine%notfound then
      chk.linenumber := null;
    else
      chk.linenumber := LineNumber;
    end if;
    close curOrderDtlLine;
  else
    if od.dtlpassthrunum10 = LineNumber then
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
end if;

if (numQtyEntered = 0) and
   (numWeight_Entered_Lbs <> 0 or numWeight_Entered_Kgs <> 0) then
  Order_by_Weight := True;
else
  Order_by_Weight := False;
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

if (Order_by_Weight) then
  qtyBase :=
    zwt.calc_order_by_weight_qty(in_custid,strItem,ci.baseuom,
                                 numWeight_Entered_Lbs,numWeight_Entered_Kgs,
                                 nvl(rtrim(in_qtytype),ci.qtytype));
  strUOMBase := ci.baseuom;
else
  zoe.get_base_uom_equivalent(rtrim(in_custid),rtrim(in_itementered),
                              nvl(rtrim(in_uomentered),ci.baseuom),
                              numQtyEntered,strItem,strUOMBase,qtyBase,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    strItem := rtrim(in_itementered);
    strUOMBase :=  nvl(rtrim(in_uomentered),ci.baseuom);
    qtyBase := numQtyEntered;
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
    dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
    dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
    dtlpassthrunum09, dtlpassthrunum10,
    dtlpassthrudate01, dtlpassthrudate02,
    dtlpassthrudate03, dtlpassthrudate04,
    dtlpassthrudoll01, dtlpassthrudoll02,
    rfautodisplay, comment1, weight_entered_lbs, weight_entered_kgs,
    variancepct, variancepct_overage, variancepct_use_default
    )
    values
    (out_orderid,out_shipid,nvl(strItem,' '),rtrim(strLotnumber),strUOMBase,'A',
     numQtyEntered,rtrim(in_itementered), nvl(rtrim(in_uomentered),ci.baseuom),
     qtyBase,
     zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered,
     zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered,
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
     decode(LineNumber,0,null,LineNumber),
     dtedtlpassthrudate01, dtedtlpassthrudate02,
     dtedtlpassthrudate03, dtedtlpassthrudate04,
     decode(in_dtlpassthrudoll01,0,null,in_dtlpassthrudoll01),
     decode(in_dtlpassthrudoll02,0,null,in_dtlpassthrudoll02),
     in_rfautodisplay, in_comment, numWeight_Entered_lbs, numWeight_Entered_kgs,
     in_variance_pct_shortage, in_variance_pct_overage, in_variance_use_default_yn
     );
	 
     -- prn 25133 - need to update the orderdtl amtorder based on pass-thru values if using % of sales
     -- this needs to happen after the insert, because at insert the function won't have visibility to the values to use
     update orderdtl
     set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
     where orderid = out_orderid
       and shipid = out_shipid
       and item = nvl(strItem,' ')
       and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)');
	 
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
          lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs
         )
         values
         (out_orderid,out_shipid,nvl(strItem,' '),rtrim(strLotnumber),
          LineNumber,qtyBase,
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
          decode(nvl(od.dtlpassthrunum10,0),nvl(LineNumber,0),
            od.dtlpassthrunum10,nvl(LineNumber,0)),
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
          dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
          dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
          dtlpassthrunum09, dtlpassthrunum10, DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
          DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
          QTYAPPROVED, lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs
         )
         values
         (out_orderid,out_shipid,nvl(strItem,' '),rtrim(strLotnumber),
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
        dtlpassthrunum01, dtlpassthrunum02, dtlpassthrunum03, dtlpassthrunum04,
        dtlpassthrunum05, dtlpassthrunum06, dtlpassthrunum07, dtlpassthrunum08,
        dtlpassthrunum09, dtlpassthrunum10, DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,
        DTLPASSTHRUDATE03,DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02,
        lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs
       )
       values
       (out_orderid,out_shipid,nvl(strItem,' '),rtrim(strLotnumber),
        LineNumber,qtyBase,
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
        decode(nvl(od.dtlpassthrunum10,0),nvl(LineNumber,0),
          od.dtlpassthrunum10,nvl(LineNumber,0)),
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
             + zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered,
           cubeorder = cubeorder
             + zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered,
           amtorder = amtorder + (qtyBase*zci.item_amt(custid,orderid,shipid,item,lotnumber)),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           weight_entered_lbs = weight_entered_lbs + numWeight_Entered_lbs,
           weight_entered_kgs = weight_entered_kgs + numWeight_Entered_kgs
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)');
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
           dtlpassthrunum10 = nvl(decode(LineNumber,0,null,LineNumber),dtlpassthrunum10),
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
       and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)')
       and linenumber = chk.linenumber;
    update orderdtl
       set qtyentered = qtyentered + numQtyEntered - ol.qty,
           qtyorder = qtyorder + qtyBase - ol.qty,
           weightorder = weightorder
             + (zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered)
             - (zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * ol.qty),
           cubeorder = cubeorder
             + (zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered)
             - (zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * ol.qty),
           amtorder = amtorder + (qtyBase - ol.qty) * zci.item_amt(custid,orderid,shipid,item,lotnumber),
           lastuser = IMP_USERID,
           lastupdate = sysdate,
           weight_entered_lbs = weight_entered_lbs + numWeight_Entered_lbs - ol.weight_entered_lbs,
           weight_entered_kgs = weight_entered_kgs + numWeight_Entered_kgs - ol.weight_entered_kgs,
           variancepct = in_variance_pct_shortage,
           variancepct_overage = in_variance_pct_overage,
           variancepct_use_default = in_variance_use_default_yn
     where orderid = out_orderid
       and shipid = out_shipid
       and item = strItem
       and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)');
  else
    if in_comment is not null then
      l_comment := in_comment;
    else
      select comment1 into l_comment
        from orderdtl
        where orderid = out_orderid
          and shipid = out_shipid
          and item = strItem
          and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)');
    end if;
    update orderdtl
       set uomentered = nvl(rtrim(in_uomentered),ci.baseuom),
           qtyentered = numQtyEntered,
           uom = strUOMBase,
           qtyorder = qtyBase,
           weightorder = zci.item_weight(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered,
           cubeorder = zci.item_cube(rtrim(in_custid),strItem,nvl(rtrim(in_uomentered),ci.baseuom)) * numQtyEntered,
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
           dtlpassthrunum10 = nvl(decode(LineNumber,0,null,LineNumber),dtlpassthrunum10),
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
       and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)');
	   
	   -- prn 25133 - need to do this again afterwards, in case any of the dtl pass-thrus that matter changed
	   update orderdtl
	   set amtorder = qtyorder*zci.item_amt(custid,orderid,shipid,item,lotnumber)
	   where orderid = out_orderid
		   and shipid = out_shipid
		   and item = strItem
		   and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)');
  end if;
elsif rtrim(in_func) = 'D' then -- delete function (do a cancel)
  update orderdtl
     set linestatus = 'X',
         lastuser = IMP_USERID,
         lastupdate = sysdate
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(strLotnumber,'(none)');
  delete from orderdtlline
   where orderid = out_orderid
     and shipid = out_shipid
     and item = strItem
     and nvl(lotnumber,'(none)') = nvl(rtrim(strLotnumber),'(none)');
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziol ' || sqlerrm;
  out_errorno := sqlcode;
end import_order_linefr;

end zimportprocsfr;
/
show error package body zimportprocsfr;
exit;

