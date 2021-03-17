create or replace PACKAGE BODY alps.zmiscpackage
IS
--
-- $Id$
--

PROCEDURE cancel_order
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor Corderhdr is
  select nvl(orderstatus,'?') as orderstatus,
         nvl(loadno,0) as loadno,
         nvl(ordertype,'?') as ordertype,
         nvl(tofacility,' ') as tofacility,
         nvl(fromfacility,' ') as fromfacility,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(qtyship,0) as qtyship,
         custid,
         confirmed,
         priority,
         rejectcode,
         rejecttext,
         edicancelpending,
         reference,
         nvl(wave,0) as wave,
         workorderseq
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh Corderhdr%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

cursor curShippingPlate is
  select count(1) as count
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and status = 'SH';
sp curShippingPlate%rowtype;

cursor curCustomer(in_custid varchar2) is
  select nvl(resubmitorder,'N') as resubmitorder
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cntRows integer;

begin

out_msg := '';

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;
close Corderhdr;

if (oh.orderstatus > '8') and
   (oh.orderstatus != 'X') then
  out_msg := 'Invalid order status for cancel: ' ||
    in_orderid || '-' || in_shipid || ' Status: ' || oh.orderstatus;
  return;
end if;

open curCustomer(oh.custid);
fetch curCustomer into cu;
if curCustomer%notfound then
  cu.resubmitorder := 'N';
end if;
close curCustomer;

if oh.ordertype in ('T','U') then  -- branch or ownership transfer
  if (oh.tofacility != in_facility) and
     (oh.fromfacility != in_facility) then
    out_msg := 'Order not associated with your facility ' || oh.tofacility;
    return;
  end if;
elsif oh.ordertype in ('R','Q','P','A','C','I') then  -- inbound
  if oh.tofacility != in_facility then
    out_msg := 'Order not at your facility' || oh.tofacility;
    return;
  end if;
  if oh.qtyrcvd != 0 then
    out_msg := 'Cannot cancel--receipts have been processed';
    return;
  end if;
else
  if oh.fromfacility != in_facility then -- outbound
    out_msg := 'Order not at your facility' || oh.tofacility;
    return;
  end if;
/*
  if oh.qtyship != 0 then
    out_msg := 'Items have been loaded';
    return;
  end if;
*/
end if;

/*
if oh.qtyship != 0 then
  out_msg := 'Cannot cancel--shipments have been processed';
  return;
end if;
*/

if oh.loadno != 0 then
  out_msg := 'Cannot cancel--order ' || in_orderid || '-' || in_shipid ||
   ' is assigned to load ' ||  oh.loadno;
  return;
end if;

sp.count := 0;
open curShippingPlate;
fetch curShippingPlate into sp.count;
if curShippingPlate%notfound then
  sp.count := 0;
end if;
close curShippingPlate;
if sp.count != 0 then
  out_msg := 'Cannot cancel--order ' || in_orderid || '-' || in_shipid ||
   ' has ' ||  sp.count || ' shipped pallets';
  return;
end if;

for od in curOrderdtl
loop
  zwv.unrelease_line
      (oh.fromfacility
      ,oh.custid
      ,in_orderid
      ,in_shipid
      ,od.item
      ,od.uom
      ,od.lotnumber
      ,od.invstatusind
      ,od.invstatus
      ,od.invclassind
      ,od.inventoryclass
      ,od.qty
      ,oh.priority
      ,'X'  -- request type of cancel
      ,in_userid
      ,'N'  -- trace flag off
      ,out_msg
      );
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('OrderCancel', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
  end if;
end loop;

if cu.resubmitorder = 'Y' then
  if oh.rejectcode is null then
    oh.rejectcode := 400;
    begin
      select descr
        into oh.rejecttext
        from ordervalidationerrors
       where code = '400';
    exception when others then
      oh.rejecttext := 'Manual Cancellation';
    end;
    if (oh.ordertype not in ('R','Q','P','A','C','I')) and
       (oh.reference is not null) and
       (oh.confirmed is not null) then
      oh.edicancelpending := 'Y';
    end if;
    oh.confirmed := null;
  end if;
end if;

delete from commitments
 where orderid = in_orderid
   and shipid = in_shipid;

update orderhdr
   set orderstatus = 'X',
       commitstatus = '0',
       rejectcode = oh.rejectcode,
       rejecttext = oh.rejecttext,
       edicancelpending = oh.edicancelpending,
       confirmed = oh.confirmed,
       lastuser = in_userid,
       lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

if oh.wave != 0 then
  begin
    select min(orderstatus)
      into oh.orderstatus
      from orderhdr
     where wave = oh.wave;
  exception when no_data_found then
    oh.orderstatus := '9';
  end;
  if oh.orderstatus > '8' then
    update waves
       set wavestatus = '4',
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave
       and wavestatus < '4';
  end if;
end if;

zmn.change_order(in_orderid,in_shipid,out_msg);

if oh.workorderseq is not null then
	update plate
   	set status = 'A',
          lasttask = 'CN',
          lastoperator = in_userid,
          lastuser = in_userid,
          lastupdate = sysdate
    	where workorderseq = oh.workorderseq
        and status = 'K';
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end cancel_order;
end zmiscpackage;
/
show errors package body zmiscpackage;
exit;
