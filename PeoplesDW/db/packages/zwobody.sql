create or replace PACKAGE BODY alps.zworkorder
IS
--
-- $Id$
--

PROCEDURE get_next_seq
(out_seq OUT number
,out_msg IN OUT varchar2
)
is

currcount integer;

begin

currcount := 1;
while (currcount = 1)
loop
  select workorderseq.nextval
    into out_seq
    from dual;
  select count(1)
    into currcount
    from custworkorder
   where seq = out_seq;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_next_seq;

PROCEDURE get_next_instr_seq
(out_seq OUT number
,out_msg IN OUT varchar2
)
is

currcount integer;

begin

currcount := 1;
while (currcount = 1)
loop
  select workorderinstrseq.nextval
    into out_seq
    from dual;
  select count(1)
    into currcount
    from workorderinstructions
   where seq = out_seq;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_next_instr_seq;

PROCEDURE validate_kit
(in_custid varchar2
,in_item varchar2
,in_kitted_class varchar2
,out_errorno OUT number
,out_msg IN OUT varchar2
)
is

cursor curClasses is
  select *
    from workorderclasses
   where custid = in_custid
     and item = in_item
     and kitted_class = in_kitted_class;
cl curClasses%rowtype;

cursor curComponents is
  select *
    from workordercomponents
   where custid = in_custid
     and item = in_item
     and kitted_class = in_kitted_class;

cntRows integer;
movement_step_count integer;
complete_step_count integer;
component_count integer;
class_component_count integer;
dests_count integer;
strIsKit custitem.iskit%type;
strUnkitted_Class custitem.unkitted_class%type;
l_instruct_qty pls_integer;

begin

out_errorno := 0;
out_msg := 'OKAY';

cl := null;
open curClasses;
fetch curClasses into cl;
close curClasses;
if cl.custid is null then
  out_errorno := -1;
  out_msg := 'Class record does not exist';
  return;
end if;

begin
  select iskit,unkitted_class
    into strIsKit,strUnkitted_Class
    from custitemview
   where custid = in_custid
     and item = in_item;
exception when others then
  strIsKit := null;
  strUnkitted_Class := null;
end;

if (strIsKit = 'I') and
   (strUnkitted_Class = in_kitted_class) then
  out_errorno := -22;
  out_msg := 'The kit''s class value cannot match the Unkitted Class value for the item';
  return;
end if;

component_count := 0;
class_component_count := 0;

for cm in curComponents
loop
  component_count := component_count + 1;
  if (in_kitted_class <> 'no') and
     (cm.component = in_item) then
      class_component_count := class_component_count + 1;
  end if;
  begin
    select iskit
      into strIsKit
      from custitemview
     where custid = in_custid
       and item = cm.component;
  exception when others then
    strIsKit := null;
  end;
  if ((in_kitted_class = 'no') and (strIsKit = 'I')) or
     ((in_kitted_class <> 'no') and (strIsKit = 'K')) then
    out_errorno := -10;
    out_msg := 'Mixing of kit-by-item and kit-by-class components is not supported (Component ' ||
               cm.component || ')';
    return;
  end if;
end loop;

if component_count = 0 then
  out_errorno := -2;
  out_msg := 'No components have been defined';
  return;
end if;

if (in_kitted_class <> 'no') and
   (class_component_count = 0) then
  out_errorno := -3;
  out_msg := 'A component using item code ' || in_item || ' must be defined for this kit by class';
  return;
end if;

movement_step_count := 0;
complete_step_count := 0;

for instr in (select *
                from workorderinstructions
               where custid = in_custid
                 and item = in_item
                 and kitted_class = in_kitted_class)
loop
  if instr.action = 'MV' then
    movement_step_count := movement_step_count + 1;
  end if;
  if instr.action = 'KR' then
    complete_step_count := complete_step_count + 1;
  end if;
  if nvl(instr.parent,0) <> 0 then
    begin
      select count(1)
        into cntRows
        from workorderinstructions
       where custid = instr.custid
         and item = instr.item
         and kitted_class = instr.kitted_class
         and seq = instr.parent;
    exception when others then
      cntRows := 0;
    end;
    if cntRows = 0 then
      out_errorno := -30;
      out_msg := 'A step has no parent (ID ' || instr.seq || ')';
      return;
    end if;
  end if;

end loop;

if complete_step_count = 0 then
  out_errorno := -4;
  out_msg := 'A completion step has not been defined';
  return;
end if;

if complete_step_count > 1 then
  out_errorno := -5;
  out_msg := 'Multiple completion steps have been defined';
  return;
end if;

if movement_step_count = 0 then
  out_errorno := -6;
  out_msg := 'No movement steps have been defined';
  return;
end if;

for instr in (select *
                from workorderinstructions
               where custid = in_custid
                 and item = in_item
                 and kitted_class = in_kitted_class
                 and action = 'KR')
loop
  begin
    select count(1)
      into cntRows
      from workorderinstructions
     where custid = instr.custid
       and item = instr.item
       and kitted_class = instr.kitted_class
       and parent = instr.seq;
  exception when others then
    cntRows := 0;
  end;
  if cntRows = 0 then
    out_errorno := -31;
    out_msg := 'None of the steps point to the parent (ID ' || instr.seq || ')';
    return;
  end if;
end loop;

for instr in (select *
                from workorderinstructions
               where custid = in_custid
                 and item = in_item
                 and kitted_class = in_kitted_class
                 and action in ('MV','KR'))
loop
  dests_count := 0;
  for dests in (select *
                  from workorderdestinations
                 where custid = in_custid
                   and item = in_item
                   and kitted_class = in_kitted_class
                   and seq = instr.seq)
  loop
    dests_count := dests_count + 1;
  end loop;
  if dests_count = 0 then
    out_errorno := 1;
    if instr.action = 'KR' then
      out_msg := 'No destinations have been specified for a completion step (ID ' || instr.seq || ')';
    else
      out_msg := 'No destinations have been specified for a movement step (ID ' || instr.seq || ')';
    end if;
    return;
  end if;
end loop;

for instr in (select *
                from workorderinstructions
               where custid = in_custid
                 and item = in_item
                 and kitted_class = in_kitted_class
                 and action not in ('MV','KR'))
loop
  dests_count := 0;
  for dests in (select *
                  from workorderdestinations
                 where custid = in_custid
                   and item = in_item
                   and kitted_class = in_kitted_class
                   and seq = instr.seq)
  loop
    dests_count := dests_count + 1;
  end loop;
  if dests_count <> 0 then
    out_errorno := 2;
    out_msg := 'Destinations have been specified for an intruction step (ID ' || instr.seq || ')';
    return;
  end if;
end loop;

for cm in curComponents
loop

  l_instruct_qty := 0;
    
  for instruct in (select qty
                    from workorderinstructions
                   where custid = in_custid
                     and item = in_item
                     and kitted_class = in_kitted_class
                     and component = cm.component)
  loop
   
    l_instruct_qty := l_instruct_qty + nvl(instruct.qty,0);

  end loop;
  
  if l_instruct_qty != nvl(cm.qty,0) then
  
    out_errorno := -1;
    out_msg := 'Quantiy mismatch on component ' || cm.component || '.  Configured: ' ||
               nvl(cm.qty,0) || ' From Instructions: ' || l_instruct_qty;
      
  end if;
  
end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end validate_kit;

procedure update_work_order
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_complete varchar2
,in_stageloc varchar2
,in_userid varchar2
,in_recurse_count number
,out_msg IN OUT varchar2
) is

cursor curOrderDtl is
  select priority,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(qtypick,0) as qtypick,
         nvl(qtyoverpick,0) as qtyoverpick,
         uom,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtyentered,
         uomentered,
         qtytype,
         childorderid,
         childshipid
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
od curOrderDtl%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curAllOrderDtl is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';
aod curAllOrderDtl%rowtype;

cursor curWorkOrderInstructions(in_custid varchar2,in_orderitem varchar2,
                                in_kitted_class varchar2) is
  select *
    from workorderinstructions
   where custid = in_custid
     and item = in_orderitem
     and kitted_class = in_kitted_class
   order by seq;

cursor curWorkOrderDestinations(in_custid varchar2,in_orderitem varchar2,in_kitted_class varchar2,
                                in_fromfacility varchar2,in_seq number) is
  select *
    from workorderdestinations
   where custid = in_custid
     and item = in_orderitem
     and kitted_class = in_kitted_class
     and facility = in_facility
     and seq = in_seq;

cursor curWorkOrderComponents(in_custid varchar2,in_orderitem varchar2, in_kitted_class varchar2) is
  select component,
         qty
    from workordercomponents
   where custid = in_custid
     and item = in_orderitem
     and kitted_class = in_kitted_class
   order by component;

cursor curItem(in_custid varchar2, in_item varchar2) is
  select baseuom,
         useramt1,
         iskit,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         unkitted_class
    from custitemview
   where custid = in_custid
     and item = in_item;
it curItem%rowtype;

cursor curOrderItem(in_custid varchar2, in_orderitem varchar2) is
  select iskit,
         unkitted_class
    from custitemview
   where custid = in_custid
     and item = in_orderitem;
oi curOrderItem%rowtype;

qtyRemain integer;
cntLines integer;
strKitted_Class workorderinstructions.kitted_class%type;

begin

if in_recurse_count > 32 then
  out_msg := 'Work Order Propogation limit reached';
  return;
end if;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
  close curOrderDtl;
  out_msg := 'Order Line not found: ' || in_orderid || ' ' ||
    in_shipid || ' ' || in_orderitem || ' ' || in_orderlot;
  return;
end if;
close curOrderDtl;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;

if oh.componenttemplate is not null then
  qtyRemain := od.qtyorder + od.qtyoverpick - od.qtypick;
else
  qtyRemain := od.qtyorder - od.qtycommit - od.qtypick;
end if;
if qtyRemain <= 0 then
  out_msg := 'OKAY--no work order needed';
  return;
end if;

oi := null;
open curOrderItem(oh.custid,in_orderitem);
fetch curOrderItem into oi;
close curOrderItem;

strKitted_Class := 'no';
if (oi.iskit = 'I') and
   (od.inventoryclass <> oi.unkitted_class) then
  strKitted_Class := od.inventoryclass;
end if;

if od.childorderid is null then
  zoe.get_next_orderid(oh.orderid,out_msg);
  oh.shipid := 1;
  zwo.get_next_seq(oh.workorderseq,out_msg);
  if oh.componenttemplate is not null then
    oh.parentorderitem := oh.componenttemplate;
    oh.parentorderlot := null;
  else
    oh.parentorderitem := in_orderitem;
    oh.parentorderlot := in_orderlot;
  end if;
  insert into orderhdr
  (orderid,shipid,custid,ordertype,apptdate,shipdate,po,rma,
   fromfacility,tofacility,shipto,billoflading,priority,shipper,
   consignee,shiptype,carrier,reference,shipterms,lastuser,lastupdate,
   orderstatus,commitstatus,statususer,entrydate, parentorderid,
   parentshipid, parentorderitem, parentorderlot, workorderseq)
  values
  (oh.orderid,oh.shipid,oh.custid,'K',null,oh.shipdate,oh.po,oh.rma,
   oh.fromfacility,oh.tofacility,null,oh.billoflading,oh.priority,null,
   null,null,null,oh.reference,null,in_userid,sysdate,
   '3','2',in_userid,sysdate,in_orderid,
   in_shipid,oh.parentorderitem,oh.parentorderlot,oh.workorderseq);
  insert into custworkorder
    (seq,custid,item,requestedqty,status,kitted_class)
    values
    (oh.workorderseq,oh.custid,nvl(oh.componenttemplate,in_orderitem),
     qtyRemain,'P',strKitted_Class);
  if oh.componenttemplate is null then
    for woi in curWorkOrderInstructions(oh.custid,in_orderitem,strKitted_Class)
    loop
      insert into custworkorderinstructions
      (seq,subseq,parent,action,notes,title,qty,
      component,status,completedqty)
      values
      (oh.workorderseq,woi.seq,woi.parent,woi.action,woi.notes,
      woi.title,woi.qty * qtyRemain,woi.component,'P',0);
      for wod in curWorkOrderDestinations(oh.custid,in_orderitem,strKitted_Class,oh.fromfacility,woi.seq)
      loop
        insert into custworkorderdestinations
        (seq,subseq,facility,location,loctype)
        values
        (oh.workorderseq,woi.seq,wod.facility,wod.location,wod.loctype);
      end loop;
    end loop;
    for woc in curWorkOrderComponents(oh.custid,in_orderitem,strKitted_Class) loop
      open curItem(oh.custid,woc.component);
      fetch curItem into it;
      close curItem;
      if strKitted_Class <> 'no' then
        it.invclassind := 'I';
        it.inventoryclass := it.unkitted_class;
      end if;
      woc.qty := woc.qty * qtyRemain;
      insert into orderdtl
      (orderid,shipid,item,lotnumber,uom,linestatus,
      qtyentered,itementered,uomentered,
      qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,
      backorder,allowsub,qtytype,invstatusind,invstatus,invclassind,
      inventoryclass,consigneesku,statususer
      )
      values
      (oh.orderid,oh.shipid,woc.component,in_orderlot,it.baseuom,'A',
      woc.qty,woc.component,it.baseuom,
      woc.qty,zci.item_weight(oh.custid,woc.component,it.baseuom) * woc.qty,
      zci.item_cube(oh.custid,woc.component,it.baseuom) * woc.qty,
      zci.item_amt(oh.custid,null,null,woc.component,null) * woc.qty, in_userid, sysdate, --prn 25133
      'N','N','E',it.invstatusind,it.invstatus,it.invclassind,it.inventoryclass,
      null,in_userid
      );
      if zwo.work_order_update_needed(oh.ordertype,oh.componenttemplate,it.iskit,
             null,it.inventoryclass,it.inventoryclass) = 'Y' then
        zwo.update_work_order(
          oh.orderid,
          oh.shipid,
          woc.component,
          in_orderlot,
          in_reqtype,
          in_facility,
          in_taskpriority,
          in_picktype,
          in_complete,
          in_stageloc,
          in_userid,
          in_recurse_count + 1,
          out_msg);
      end if;
    end loop;
    update orderdtl
       set childorderid = oh.orderid,
           childshipid = oh.shipid
     where orderid = in_orderid
       and shipid = in_shipid
       and item = in_orderitem
       and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
  else
    cntLines := 1;
    for aod in curAllOrderDtl
    loop
      open curItem(oh.custid,aod.item);
      fetch curItem into it;
      close curItem;
      aod.qtycommit := aod.qtyorder + nvl(aod.qtyoverpick,0);
      for woi in curWorkOrderInstructions(oh.custid,oh.componenttemplate,strKitted_Class)
      loop
        -- only add a "kit-complete" for the first line
        if (woi.action = 'KR') and
           (cntLines <> 1) then
          goto continue_instr_loop;
        end if;
        if (woi.action <> 'KR') then
          woi.seq := woi.seq + (cntLines * 1000);
        end if;
        insert into custworkorderinstructions
        (seq,subseq,parent,action,notes,title,qty,component,status,completedqty)
        values
        (oh.workorderseq,woi.seq,woi.parent,woi.action,woi.notes,
        woi.title,woi.qty * aod.qtycommit,decode(woi.action,'KR',null,aod.item),'P',0);
        for wod in curWorkOrderDestinations(oh.custid,oh.componenttemplate,strKitted_Class,oh.fromfacility,woi.seq)
        loop
          insert into custworkorderdestinations
          (seq,subseq,facility,location,loctype)
          values
          (oh.workorderseq,woi.seq,wod.facility,wod.location,wod.loctype);
        end loop;
      << continue_instr_loop >>
        null;
      end loop;
      insert into orderdtl
      (orderid,shipid,item,lotnumber,uom,linestatus,
      qtyentered,itementered,uomentered,
      qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,
      backorder,allowsub,qtytype,invstatusind,invstatus,invclassind,
      inventoryclass,consigneesku,statususer
      )
      values
      (oh.orderid,oh.shipid,aod.item,aod.lotnumber,it.baseuom,'A',
      aod.qtycommit,aod.item,it.baseuom,
      aod.qtycommit,zci.item_weight(oh.custid,aod.item,it.baseuom) * aod.qtycommit,
      zci.item_cube(oh.custid,aod.item,it.baseuom) * aod.qtycommit,
      zci.item_amt(oh.custid,null,null,aod.item,null) * aod.qtycommit, in_userid, sysdate, --prn 25133
      'N','N','E',it.invstatusind,it.invstatus,it.invclassind,it.inventoryclass,
      null,in_userid
      );
      delete
        from commitments
       where orderid = in_orderid
         and shipid = in_shipid
         and orderitem = aod.item
         and nvl(orderlot,'(none)') = nvl(aod.lotnumber,'(none)');
      update orderdtl
         set childorderid = oh.orderid,
             childshipid = oh.shipid
       where orderid = in_orderid
         and shipid = in_shipid
         and item = aod.item
         and nvl(lotnumber,'(none)') = nvl(aod.lotnumber,'(none)');
      cntLines := cntLines + 1;
    end loop;
  end if;
end if;

<< return_okay_message >>

out_msg := 'OKAY';

exception when others then
  out_msg := 'zwouwo ' || sqlerrm;
end update_work_order;

function top_ordertype
(in_orderid IN number
,in_shipid IN number
) return varchar2 is

oh orderhdr%rowtype;

begin

oh := null;
oh.parentorderid := in_orderid;
oh.parentshipid := in_shipid;

while (1=1)
loop
  begin
    select parentorderid,parentshipid,ordertype
      into oh.parentorderid,oh.parentshipid,oh.ordertype
      from orderhdr
     where orderid = oh.parentorderid
       and shipid = oh.parentshipid;
  exception when others then
    oh.ordertype := null;
    exit;
  end;
  if oh.parentorderid is null then
    exit;
  end if;
end loop;

return nvl(oh.ordertype,'N');

exception when others then
  return 'N';
end top_ordertype;

function work_order_update_needed
(in_ordertype varchar2
,in_componenttemplate varchar2
,in_iskit varchar2
,in_childorderid number
,in_inventoryclass varchar2
,in_unkitted_class varchar2
) return varchar2 is

out_yn char(1);

begin

out_yn := 'N';

if (in_ordertype = 'O' and in_componenttemplate is not null) then
  out_yn := 'Y';
elsif (in_iskit = 'K' and nvl(in_childorderid,0) = 0) then
  out_yn := 'Y';
elsif (in_iskit = 'I' and nvl(in_childorderid,0) = 0) and
      (in_unkitted_class <> in_inventoryclass) then
  out_yn := 'Y';
end if;

return out_yn;

exception when others then
  return 'N';
end work_order_update_needed;

PROCEDURE validate_ordered_kit_by_class
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_custid varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,out_errorno OUT number
,out_msg IN OUT varchar2
) is

cntRows integer;
strIsKit custitem.iskit%type;
classfound boolean;
strClassList varchar2(255);
numErrorNo integer;
strMsg varchar2(255);

begin

out_errorno := 0;
out_msg := 'OKAY';

classfound := False;

if in_invclassind <> 'I' then
  out_errorno := -2;
  out_msg := 'Inventory class indicator must be an ''I'' for kit-by-class items';
  return;
end if;

cntRows := 0;
begin
  select count(1)
    into cntRows
    from workorderclasses
   where custid = in_custid
     and item = in_item
     and kitted_class = in_inventoryclass;
exception when others then
  cntRows := 0;
end;

if cntRows <> 1 then
  out_errorno := -3;
  out_msg := 'Invalid inventory class specified for a kit-by-class item';
  return;
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end validate_ordered_kit_by_class;

end zworkorder;
/
show error package body zworkorder;
exit;
