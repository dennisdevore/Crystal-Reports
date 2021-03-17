create or replace package body alps.comments as
--
-- $Id$
--

procedure order_instruction
(in_orderid in number
,in_shipid in number
,out_comment out long
) is

cursor curOrderHdr is
  select comment1,
         ordertype,
         custid,
         shipto
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curInOrderComment(in_custid varchar2) is
  select comment1
    from custitemincomments
   where custid = in_custid
     and item is null;
ioc curInOrderComment%rowtype;

cursor curOutOrderComment(in_custid varchar2, in_consignee varchar2) is
  select comment1
    from custitemoutcomments
   where item = 'default'
     and ( (custid = in_custid)
     and ((consignee = in_consignee) or (consignee = 'default')) )
      or ( (consignee = in_consignee) and (custid = 'default') )
   order by custid, consignee;
ooc curOutOrderComment%rowtype;

begin

out_comment := null;

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  return;
end if;
close curOrderHdr;
if oh.comment1 is not null then
  out_comment := oh.comment1;
  return;
end if;

if oh.ordertype in ('R','Q','P','A','C','I') then -- inbound orders
  open curInOrderComment(oh.custid);
  fetch curInOrderComment into ioc;
  if curInOrderComment%found then
    out_comment := ioc.comment1;
  end if;
  close curInOrderComment;
  return;
else --outbound orders
  open curOutOrderComment(oh.custid,oh.shipto);
  fetch curOutOrderComment into ooc;
  if curOutOrderComment%found then
    out_comment := ooc.comment1;
  end if;
  close curOutOrderComment;
  return;
end if;

exception when others then
  null;
end order_instruction;

procedure order_bolcomment
(in_orderid in number
,in_shipid in number
,out_comment out long
) is

cursor curOrderHdr is
  select comment1,
         ordertype,
         custid,
         shipto
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curBolComment is
  select bolcomment
    from orderhdrbolcomments
   where orderid = in_orderid
     and shipid = in_shipid;
bc curBolComment%rowtype;

cursor curDefaultComment(in_custid varchar2, in_consignee varchar2) is
  select comment1
    from custitembolcomments
   where item = 'default'
     and ( (custid = in_custid)
     and ((consignee = in_consignee) or (consignee = 'default')) )
      or ( (consignee = in_consignee) and (custid = 'default') )
   order by custid, consignee;
df curDefaultComment%rowtype;

begin

out_comment := null;

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  return;
end if;

if oh.ordertype not in ('R','Q','P','A','C','I') then -- outbound orders only
  open curBolComment;
  fetch curBolComment into bc;
  if curBolComment%found then
    out_comment := bc.bolcomment;
  else
    open curDefaultComment(oh.custid,oh.shipto);
    fetch curDefaultComment into df;
    if curDefaultComment%found then
      out_comment := df.comment1;
    end if;
    close curDefaultComment;
  end if;
  close curBolComment;
end if;

exception when others then
  null;
end order_bolcomment;

procedure line_instruction
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,out_comment out long
) is

cursor curOrderHdr is
  select ordertype,
         custid,
         shipto
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select comment1
    from orderDtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
od curOrderDtl%rowtype;

cursor curInLineComment(in_custid varchar2) is
  select comment1
    from custitemincomments
   where custid = in_custid
     and item = in_item;
ioc curInLineComment%rowtype;

cursor curOutItemComment(in_custid varchar2, in_consignee varchar2) is
  select comment1
    from custitemoutcomments
   where item = in_item
     and ( (custid = in_custid)
     and ((consignee = in_consignee) or (consignee = 'default')) )
      or ( (consignee = in_consignee) and (custid = 'default') )
   order by custid, consignee;
ooc curOutItemComment%rowtype;

begin

out_comment := null;

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  return;
end if;
close curOrderHdr;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
  close curOrderDtl;
  return;
end if;
close curOrderDtl;
if od.comment1 is not null then
  out_comment := od.comment1;
  return;
end if;

if oh.ordertype in ('R','Q','P','A','C','I') then -- inbound orders
  open curInLineComment(oh.custid);
  fetch curInLineComment into ioc;
  if curInLineComment%found then
    out_comment := ioc.comment1;
  end if;
  close curInLineComment;
  return;
else --outbound orders
  open curOutItemComment(oh.custid,oh.shipto);
  fetch curOutItemComment into ooc;
  if curOutItemComment%found then
    out_comment := ooc.comment1;
  end if;
  close curOutItemComment;
  return;
end if;

exception when others then
  null;
end line_instruction;

procedure line_bolcomment
(in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,out_comment out long
) is

cursor curOrderHdr is
  select ordertype,
         custid,
         shipto
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curBolComment is
  select bolcomment
    from orderdtlbolcomments
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
bc curBolComment%rowtype;

cursor curDefaultComment(in_custid varchar2, in_consignee varchar2) is
  select comment1
    from custitembolcomments
   where item = in_item
     and ( (custid = in_custid)
     and ((consignee = in_consignee) or (consignee = 'default')) )
      or ( (consignee = in_consignee) and (custid = 'default') )
   order by custid, consignee;
df curDefaultComment%rowtype;

begin

out_comment := null;

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  return;
end if;

if oh.ordertype not in ('R','Q','P','A','C','I') then -- outbound orders only
  open curBolComment;
  fetch curBolComment into bc;
  if curBolComment%found then
    out_comment := bc.bolcomment;
  else
    open curDefaultComment(oh.custid,oh.shipto);
    fetch curDefaultComment into df;
    if curDefaultComment%found then
      out_comment := df.comment1;
    end if;
    close curDefaultComment;
  end if;
  close curBolComment;
end if;

exception when others then
  null;
end line_bolcomment;

end comments;
/
show error package body comments;
exit;
