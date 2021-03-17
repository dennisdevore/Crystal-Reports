create or replace package body alps.zitemdemand as
--
-- $Id$
--

function include_exclude
(in_indicator varchar2
,in_indicator_values varchar2
,in_value varchar2
) return boolean
is
begin

if rtrim(in_indicator_values) is null then
  return True;
end if;

if in_indicator = 'I' then
  if instr(in_indicator_values,in_value) != 0 then
    return True;
  else
    return False;
  end if;
end if;

if in_indicator = 'E' then
  if instr(in_indicator_values,in_value) = 0 then
    return True;
  else
    return False;
  end if;
end if;

return True;

exception when others then
  return False;
end;

function default_xdocklocid
(in_facility varchar2
) return varchar2
is
out_locid location.locid%type;

begin

out_locid := null;

select xdockloc
  into out_locid
  from facility
 where facility = in_facility;

if out_locid is null then
  out_locid := 'XDOCK?';
end if;

return out_locid;

exception when others then
  return 'XDOCK?';
end;

procedure lip_placed_at_xdock
(in_lpid varchar2
,in_taskpriority varchar2
,in_userid varchar2
,out_errorno in out number
,out_msg in out varchar2
)
is

newpriority tasks.priority%type;
begin

if rtrim(in_taskpriority) is null then
  newpriority := '2';
else
  newpriority := in_taskpriority;
end if;

update tasks
   set prevpriority = priority,
       priority = newpriority,
       lastuser = in_userid,
       lastupdate = sysdate
 where lpid = in_lpid
   and priority = '9';

exception when others then
  out_errorno := sqlcode;
  out_msg := 'zidlpax ' || sqlerrm;
end;

procedure xdock_pick_complete
(in_lpid varchar2
,in_userid varchar2
,out_errorno in out number
,out_msg in out varchar2
)
is

cursor curPlate is
  select *
    from plate
   where lpid = in_lpid;
pl curPlate%rowtype;

cursor curXDockOrders is
  select *
    from orderdtl od
   where xdockorderid = pl.orderid
     and xdockshipid = pl.shipid
     and linestatus != 'X'
     and qtyorder - nvl(qtycommit,0) - nvl(qtypick,0) > 0
     and exists (select *
                   from orderhdr oh
                  where od.orderid = oh.orderid
                    and od.shipid = oh.shipid
                    and oh.orderstatus < '4')
  order by priority,orderid,shipid;

cursor curSubTasks is
  select count(1) as cnt
    from subtasks
   where lpid = in_lpid
     and nvl(qtypicked, 0) = 0;
sb curSubTasks%rowtype;

strLocType location.loctype%type;

begin

out_errorno := 0;
out_msg := '';

pl := null;
open curPlate;
fetch curPlate into pl;
close curPlate;
if pl.lpid is null then
  out_errorno := -1;
  out_msg := 'Plate row not found: ' || in_lpid;
  return;
end if;

strLocType := null;
begin
  select loctype
    into strloctype
    from location
   where facility = pl.facility
     and locid = pl.location;
exception when no_data_found then
  out_errorno := -3;
  out_msg := 'Location not found: ' || pl.facility || ' ' || pl.location;
  return;
end;

if nvl(strLocType,'x') <> 'CD' then
  out_errorno := -4;
  out_msg := 'Location not Cross Dock Type: ' || strLocType;
  return;
end if;

if nvl(pl.qtytasked,0) != 0 then
  sb := null;
  open curSubTasks;
  fetch curSubTasks into sb;
  close curSubTasks;
  if nvl(sb.cnt,0) != 0 then
    out_errorno := -2;
    out_msg := 'There are still pick tasks';
    return;
  end if;
end if;

for xo in curXDockOrders
loop
  out_errorno := -3;
  out_msg := 'Unreleased Cross Dock orders exist';
  return;
end loop;

out_errorno := 0;
out_msg := 'OKAY to put away';

exception when others then
  out_errorno := sqlcode;
  out_msg := 'zidxpc ' || sqlerrm;
end;

procedure create_itemdemand_for_shortage
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderHdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and linestatus != 'X';
od curOrderDtl%rowtype;

cursor curItemList is
  select in_orderitem as itemsub,
         -1 as seq
    from dual
   union all
  select itemsub,
         seq
    from custitemsubs
   where custid = oh.custid
     and item = in_orderitem
   order by 2,1;

cursor curItem is
  select iskit
    from custitemview
   where custid = oh.custid
     and item = in_orderitem;
it curItem%rowtype;

qtyDemand orderdtl.qtyorder%type;

begin

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := -1;
  out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;

if oh.componenttemplate is not null then
  out_msg := 'OKAY--no item demand needed for component orders';
  return;
end if;

if nvl(oh.xdockprocessing,'S') = 'N' then
  out_msg := 'OKAY--item demand not needed for no-opportunistic';
  return;
end if;

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;
if od.orderid is null then
  out_errorno := -2;
  out_msg := 'Order Line not found: ' || in_orderid || '-' || in_shipid || ' ' ||
    in_orderitem || '/' || in_orderlot;
  return;
end if;

if zwt.is_ordered_by_weight(in_orderid,in_shipid,in_orderitem,in_orderlot) = 'Y' then
  od.qtyorder := zwt.order_by_weight_qty (in_orderid,in_shipid,in_orderitem,in_orderlot);
  update orderdtl
     set qtyorder = od.qtyorder,
         weightorder = zci.item_weight(custid,item,uom) * od.qtyorder,
         cubeorder = zci.item_cube(custid,item,uom) * od.qtyorder,
         amtorder =  zci.item_amt(custid,orderid,shipid,item,lotnumber) * od.qtyorder --prn 25133
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and qtyOrder != od.qtyorder;
end if;

qtyDemand := nvl(od.qtyorder,0) - nvl(od.qtypick,0) - nvl(od.qtycommit,0);
if qtyDemand <= 0 then
  out_msg := 'OKAY--no shortage for this item';
  return;
end if;

it := null;
open curItem;
fetch curItem into it;
close curItem;
if it.iskit is null then
  out_errorno := -3;
  out_msg := 'Invalid item code: ' || oh.custid || ' ' || in_orderitem;
  return;
end if;

if it.iskit != 'N' then
  out_msg := 'OKAY--no item demand needed for kit items';
  return;
end if;

for dmd in curItemList -- create itemdemand for item and any substitutes
loop
  insert into ITEMDEMAND
  (FACILITY,ITEM,LOTNUMBER,PRIORITY,INVSTATUSIND,INVCLASSIND,INVSTATUS,
  INVENTORYCLASS,DEMANDTYPE,ORDERID,SHIPID,LOADNO,STOPNO,SHIPNO,
  ORDERITEM,ORDERLOT,QTY,LASTUSER,LASTUPDATE,CUSTID
  )
  values
  (oh.FROMFACILITY,dmd.ITEMSUB,od.LOTNUMBER,oh.PRIORITY,od.INVSTATUSIND,
  od.INVCLASSIND,od.INVSTATUS,od.INVENTORYCLASS,'O',
  od.ORDERID,od.SHIPID,oh.LOADNO,oh.STOPNO,oh.SHIPNO,od.ITEM,
  od.LOTNUMBER,qtyDemand,in_userid,sysdate,oh.CUSTID
  );
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zidcis ' || sqlerrm;
  out_errorno := sqlcode;
end create_itemdemand_for_shortage;

procedure check_for_active_itemdemand
(in_lpid varchar2
,out_destlocation IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curPlate is
  select *
    from plate
   where lpid = in_lpid;
pl curPlate%rowtype;

cursor curXDockOrders is
  select *
    from orderdtl od
   where xdockorderid = pl.orderid
     and xdockshipid = pl.shipid
     and linestatus != 'X'
     and item = pl.item
     and qtyorder - nvl(qtycommit,0) - nvl(qtypick,0) > 0
     and exists (select *
                   from orderhdr oh
                  where od.orderid = oh.orderid
                    and od.shipid = oh.shipid
                    and oh.orderstatus < '9'
                    and oh.custid = pl.custid)
  order by priority,orderid,shipid;

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select *
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curWave(in_wave number) is
  select taskpriority
    from waves
   where wave = in_wave;
wv curWave%rowtype;

cursor curItemDemand is
  select orderid, shipid, orderitem, orderlot, demandtype, qty
    from itemdemand
   where facility = pl.facility
     and item = pl.item
     and custid = pl.custid
     and ( (orderlot is null) or
           (orderlot = pl.lotnumber) )
     for update of qty
   order by demandtype,priority,orderid,shipid;
dmd curItemDemand%rowtype;

cursor curItemDemandOrd(in_orderid number, in_shipid number, in_item varchar2, in_lotnumber varchar2) is
  select qty
    from itemdemand
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
     and rownum < 2
     for update of qty;
dmdord curItemDemandOrd%rowtype;

cursor curOrderDtl(in_orderid number,in_shipid number,in_orderitem varchar2,
  in_orderlot varchar2) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
od curOrderDtl%rowtype;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;

qtyRemain orderdtl.qtyorder%type;
qtyApply  orderdtl.qtyorder%type;
tk tasks%rowtype;
sb subtasks%rowtype;
sp shippingplate%rowtype;
singleonly char(1);
strMsg varchar2(255);
intErrorno integer;
qtyDmd integer;

begin

out_destlocation := '';
out_errorno := -1;
out_msg := '';

pl := null;
open curPlate;
fetch curPlate into pl;
close curPlate;
if pl.lpid is null then
  out_errorno := -1;
  out_msg := 'Plate row not found: ' || in_lpid;
  return;
end if;

qtyRemain := pl.quantity;

for xd in curXDockOrders
loop
  if qtyRemain <= 0 then
    exit;
  end if;
  if zid.include_exclude(xd.invclassind,xd.inventoryclass,pl.inventoryclass) = False then
    goto continue_xdock_loop;
  end if;
  if zid.include_exclude(xd.invstatusind,xd.invstatus,pl.invstatus) = False then
    goto continue_xdock_loop;
  end if;
  oh := null;
  open curOrderHdr(xd.orderid,xd.shipid);
  fetch curOrderHdr into oh;
  close curOrderHdr;
  wv := null;
  open curWave(oh.wave);
  fetch curWave into wv;
  close curWave;
  if wv.taskpriority is null then
    wv.taskpriority := '3';
  end if;
  qtyApply := xd.qtyorder - nvl(xd.qtycommit,0) - nvl(xd.qtypick,0);
  if qtyApply > qtyRemain then
    qtyApply := qtyRemain;
  end if;
  if qtyApply <= 0 then
    goto continue_xdock_loop;
  end if;
  qtyRemain := qtyRemain - qtyApply;
  if xd.xdocklocid is null then
    out_destlocation := zid.default_xdocklocid(pl.facility);
  else
    out_destlocation := xd.xdocklocid;
  end if;
  if oh.orderstatus < '4' then
     goto continue_xdock_loop;
  end if;

  open curItemDemandOrd(xd.orderid, xd.shipid, xd.item, xd.lotnumber);
  fetch curItemDemandOrd into dmdord;

  begin
    insert into commitments
    (facility, custid, item, inventoryclass,
     invstatus, status, lotnumber, uom,
     qty, orderid, shipid, orderitem, orderlot,
     priority, lastuser, lastupdate)
    values
    (pl.facility, pl.custid, pl.item, pl.inventoryclass,
     pl.invstatus, 'CM', xd.lotnumber, pl.unitofmeasure,
     qtyApply, xd.orderid, xd.shipid, xd.item, xd.lotnumber,
     xd.priority, 'ITEMDEMAND', sysdate);
  exception when dup_val_on_index then
    update commitments
       set qty = qty + qtyApply,
           priority = xd.priority,
           lastuser = 'ITEMDEMAND',
           lastupdate = sysdate
     where facility = pl.facility
       and custid = pl.custid
       and item = pl.item
       and inventoryclass = pl.inventoryclass
       and invstatus = pl.invstatus
       and status = 'CM'
       and nvl(lotnumber,'(none)') = nvl(xd.lotnumber,'(none)')
       and orderid = xd.orderid
       and shipid = xd.shipid
       and orderitem = xd.item
       and nvl(orderlot,'(none)') = nvl(xd.lotnumber,'(none)');
  end;
  out_errorno := 0;
  tk := null;
  sb := null;
  sp := null;
  singleonly := zwv.single_shipping_units_only(xd.orderid,xd.shipid);
  if singleonly = 'Y' then
    tk.picktotype := 'LBL';
  else
    tk.picktotype := 'PAL';
  end if;
  tk.priority := '9';
  tk.tasktype := 'PK';
  tk.cartontype := 'NONE';
  tk.cartonseq := null;
  ztsk.get_next_taskid(tk.taskid,strMsg);
  zsp.get_next_shippinglpid(sp.lpid,strMsg);
  if qtyApply = pl.quantity then
    sp.type := 'F';
  else
    sp.type := 'P';
  end if;
  if oh.stageloc is null then
    begin
      select loadstopstageloc
        into tk.toloc
        from loadsorderview
       where orderid = oh.orderid
         and shipid = oh.shipid;
    exception when others then
      tk.toloc := 'PROBLEM';
    end;
  else
    tk.toloc := oh.stageloc;
  end if;
  tk.fromloc := out_destlocation;
  zgs.compute_largest_whole_pickuom(pl.facility,pl.custid,pl.item,
    pl.unitofmeasure, qtyApply,
    tk.pickuom, tk.pickqty, sb.picktotype, sb.cartontype, sb.qty,
    intErrorno, strMsg);
  if sb.qty != qtyApply then
    tk.pickuom := pl.unitofmeasure;
    tk.pickqty := qtyApply;
  end if;
  insert into shippingplate
    (lpid, item, custid, facility, location, status, holdreason,
    unitofmeasure, quantity, type, fromlpid, serialnumber,
    lotnumber, parentlpid, useritem1, useritem2, useritem3,
    lastuser, lastupdate, invstatus, qtyentered, orderitem,
    uomentered, inventoryclass, loadno, stopno, shipno,
    orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
    pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
    values
    (sp.lpid, pl.item, pl.custid, pl.facility, tk.fromloc,
     'U', pl.holdreason, pl.unitofmeasure, qtyApply,
     sp.type, pl.lpid, pl.serialnumber, pl.lotnumber, null,
     pl.useritem1, pl.useritem2, pl.useritem3,
     'ITEMDEMAND', sysdate, pl.invstatus, qtyApply,
     xd.item, xd.uomentered, pl.inventoryclass,
     oh.loadno, oh.stopno, oh.shipno, oh.orderid,
     oh.shipid, zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     null, null, tk.taskid, xd.lotnumber,
     tk.pickuom, tk.pickqty, tk.cartonseq, pl.manufacturedate, pl.expirationdate);
  open curLocation(pl.facility,tk.fromloc);
  fetch curLocation into fromloc;
  close curLocation;
  open curLocation(pl.facility,tk.toloc);
  fetch curLocation into toloc;
  close curLocation;
  insert into tasks
    (taskid, tasktype, facility, fromsection, fromloc,
     fromprofile,tosection,toloc,toprofile,touserid,
     custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
     orderid,shipid,orderitem,orderlot,priority,
     prevpriority,curruserid,lastuser,lastupdate,
     pickuom, pickqty, picktotype, wave,
     pickingzone, cartontype, weight, cube, staffhrs)
    values
    (tk.taskid, tk.tasktype, pl.facility, fromloc.section,tk.fromloc,
     fromloc.equipprof,toloc.section,tk.toloc,toloc.equipprof,null,
     pl.custid,pl.item,pl.lpid,pl.unitofmeasure,qtyApply,
     fromloc.pickingseq,oh.loadno,oh.stopno,oh.shipno,
     oh.orderid,oh.shipid,xd.item,xd.lotnumber,
     tk.priority,tk.priority,null,'ITEMDEMAND',sysdate,
     tk.pickuom,tk.pickqty,tk.picktotype,oh.wave,
     fromloc.pickingzone,tk.cartontype,
     zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zlb.staff_hours(pl.facility,pl.custid,pl.item,tk.tasktype,
     fromloc.pickingzone,tk.pickuom,tk.pickqty));
  insert into subtasks
    (taskid, tasktype, facility, fromsection, fromloc,
     fromprofile,tosection,toloc,toprofile,touserid,
     custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
     orderid,shipid,orderitem,orderlot,priority,
     prevpriority,curruserid,lastuser,lastupdate,
     pickuom, pickqty, picktotype, wave,
     pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
     shippinglpid, shippingtype, cartongroup)
    values
    (tk.taskid,tk.tasktype,pl.facility,
     fromloc.section,tk.fromloc,fromloc.equipprof,toloc.section,
     tk.toloc,toloc.equipprof,null,pl.custid,pl.item,pl.lpid,
     pl.unitofmeasure,qtyApply,fromloc.pickingseq,oh.loadno,
     oh.stopno,oh.shipno,oh.orderid,oh.shipid,xd.item,
     xd.lotnumber,tk.priority,tk.priority,null,'ITEMDEMAND',
     sysdate,tk.pickuom,tk.pickqty,tk.picktotype,oh.wave,
     fromloc.pickingzone,tk.cartontype,
     zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zlb.staff_hours(pl.facility,pl.custid,pl.item,tk.tasktype,
     fromloc.pickingzone,tk.pickuom,tk.pickqty),tk.cartonseq,
     sp.lpid, sp.type,zwv.cartontype_group(tk.cartontype));
  update plate
     set qtytasked = nvl(qtytasked,0) + qtyApply
   where lpid = in_lpid
     and parentfacility is not null;
  begin
    if qtyApply >= dmdord.qty then
      delete from itemdemand
       where current of curItemDemandOrd;
    else
      update itemdemand
         set qty = qty - qtyApply
       where current of curItemDemandOrd;
    end if;
    close curItemDemandOrd;
  exception when others then
    close curItemDemandOrd;
    null;
  end;
<<continue_xdock_loop>>
  null;
end loop;

if qtyRemain <= 0 then
  goto finish_it;
end if;

for dmd in curItemDemand
loop
  if qtyRemain <= 0 then
    exit;
  end if;
  if dmd.demandtype = 'R' then  -- skip replenishment Demand
    goto continue_demand_loop;
  end if;
  od := null;
  open curOrderDtl(dmd.orderid,dmd.shipid,dmd.orderitem,dmd.orderlot);
  fetch curOrderDtl into od;
  close curOrderDtl;
  if od.orderid is null then
    goto continue_demand_loop;
  end if;
  if od.linestatus = 'X' then
    goto continue_demand_loop;
  end if;
  if zid.include_exclude(od.invclassind,od.inventoryclass,pl.inventoryclass) = False then
    goto continue_demand_loop;
  end if;
  if zid.include_exclude(od.invstatusind,od.invstatus,pl.invstatus) = False then
    goto continue_demand_loop;
  end if;
  oh := null;
  open curOrderHdr(od.orderid,od.shipid);
  fetch curOrderHdr into oh;
  close curOrderHdr;
  if (oh.orderstatus < '4') or
     (oh.orderstatus > '8') then
    goto continue_demand_loop;
  end if;
  qtyApply := od.qtyorder - nvl(od.qtycommit,0) - nvl(od.qtypick,0);
  if qtyApply > dmd.qty then
    qtyApply := dmd.qty;
  end if;
  if qtyApply > qtyRemain then
    qtyApply := qtyRemain;
  end if;
  if qtyApply <= 0 then
    goto continue_demand_loop;
  end if;
  qtyRemain := qtyRemain - qtyApply;
  begin
    insert into commitments
    (facility, custid, item, inventoryclass,
     invstatus, status, lotnumber, uom,
     qty, orderid, shipid, orderitem, orderlot,
     priority, lastuser, lastupdate)
    values
    (pl.facility, pl.custid, pl.item, pl.inventoryclass,
     pl.invstatus, 'CM', od.lotnumber, pl.unitofmeasure,
     qtyApply, od.orderid, od.shipid, od.item, od.lotnumber,
     od.priority, 'ITEMDEMAND', sysdate);
  exception when dup_val_on_index then
    update commitments
       set qty = qty + qtyApply,
           priority = od.priority,
           lastuser = 'ITEMDEMAND',
           lastupdate = sysdate
     where facility = pl.facility
       and custid = pl.custid
       and item = pl.item
       and inventoryclass = pl.inventoryclass
       and invstatus = pl.invstatus
       and status = 'CM'
       and nvl(lotnumber,'(none)') = nvl(od.lotnumber,'(none)')
       and orderid = od.orderid
       and shipid = od.shipid
       and orderitem = od.item
       and nvl(orderlot,'(none)') = nvl(od.lotnumber,'(none)');
  end;
  out_errorno := 0;
  if od.xdocklocid is null then
    tk.fromloc := zid.default_xdocklocid(pl.facility);
  else
    tk.fromloc := od.xdocklocid;
  end if;
  if out_destlocation is null then
    out_destlocation := tk.fromloc;
  end if;
  tk := null;
  sb := null;
  sp := null;
  singleonly := zwv.single_shipping_units_only(dmd.orderid,dmd.shipid);
  if singleonly = 'Y' then
    tk.picktotype := 'LBL';
  else
    tk.picktotype := 'PAL';
  end if;
  wv := null;
  open curWave(oh.wave);
  fetch curWave into wv;
  close curWave;
  if wv.taskpriority is null then
    wv.taskpriority := '3';
  end if;
  tk.priority := '9';
  tk.tasktype := 'PK';
  tk.cartontype := 'NONE';
  tk.cartonseq := null;
  ztsk.get_next_taskid(tk.taskid,strMsg);
  zsp.get_next_shippinglpid(sp.lpid,strMsg);
  if qtyApply = pl.quantity then
    sp.type := 'F';
  else
    sp.type := 'P';
  end if;
  if oh.stageloc is null then
    begin
      select loadstopstageloc
        into tk.toloc
        from loadsorderview
       where orderid = oh.orderid
         and shipid = oh.shipid;
    exception when others then
      tk.toloc := 'PROBLEM';
    end;
  else
    tk.toloc := oh.stageloc;
  end if;
  tk.fromloc := out_destlocation;
  zgs.compute_largest_whole_pickuom(pl.facility,pl.custid,pl.item,
    pl.unitofmeasure, qtyApply,
    tk.pickuom, tk.pickqty, sb.picktotype, sb.cartontype, sb.qty,
    intErrorno, strMsg);
  if sb.qty != qtyApply then
    tk.pickuom := pl.unitofmeasure;
    tk.pickqty := qtyApply;
  end if;
  insert into shippingplate
    (lpid, item, custid, facility, location, status, holdreason,
    unitofmeasure, quantity, type, fromlpid, serialnumber,
    lotnumber, parentlpid, useritem1, useritem2, useritem3,
    lastuser, lastupdate, invstatus, qtyentered, orderitem,
    uomentered, inventoryclass, loadno, stopno, shipno,
    orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
    pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
    values
    (sp.lpid, pl.item, pl.custid, pl.facility, tk.fromloc,
     'U', pl.holdreason, pl.unitofmeasure, qtyApply,
     sp.type, pl.lpid, pl.serialnumber, pl.lotnumber, null,
     pl.useritem1, pl.useritem2, pl.useritem3,
     'ITEMDEMAND', sysdate, pl.invstatus, qtyApply,
     od.item, pl.unitofmeasure, pl.inventoryclass,
     oh.loadno, oh.stopno, oh.shipno, oh.orderid,
     oh.shipid, zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     null, null, tk.taskid, od.lotnumber,
     tk.pickuom, tk.pickqty, tk.cartonseq, pl.manufacturedate, pl.expirationdate);
  open curLocation(pl.facility,tk.fromloc);
  fetch curLocation into fromloc;
  close curLocation;
  open curLocation(pl.facility,tk.toloc);
  fetch curLocation into toloc;
  close curLocation;
  insert into tasks
    (taskid, tasktype, facility, fromsection, fromloc,
     fromprofile,tosection,toloc,toprofile,touserid,
     custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
     orderid,shipid,orderitem,orderlot,priority,
     prevpriority,curruserid,lastuser,lastupdate,
     pickuom, pickqty, picktotype, wave,
     pickingzone, cartontype, weight, cube, staffhrs)
    values
    (tk.taskid, tk.tasktype, pl.facility, fromloc.section,tk.fromloc,
     fromloc.equipprof,toloc.section,tk.toloc,toloc.equipprof,null,
     pl.custid,pl.item,pl.lpid,pl.unitofmeasure,qtyApply,
     fromloc.pickingseq,oh.loadno,oh.stopno,oh.shipno,
     oh.orderid,oh.shipid,dmd.orderitem,dmd.orderlot,
     tk.priority,tk.priority,null,'ITEMDEMAND',sysdate,
     tk.pickuom,tk.pickqty,tk.picktotype,oh.wave,
     fromloc.pickingzone,tk.cartontype,
     zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zlb.staff_hours(pl.facility,pl.custid,pl.item,tk.tasktype,
     fromloc.pickingzone,tk.pickuom,tk.pickqty));
  insert into subtasks
    (taskid, tasktype, facility, fromsection, fromloc,
     fromprofile,tosection,toloc,toprofile,touserid,
     custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
     orderid,shipid,orderitem,orderlot,priority,
     prevpriority,curruserid,lastuser,lastupdate,
     pickuom, pickqty, picktotype, wave,
     pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
     shippinglpid, shippingtype, cartongroup)
    values
    (tk.taskid,tk.tasktype,pl.facility,
     fromloc.section,tk.fromloc,fromloc.equipprof,toloc.section,
     tk.toloc,toloc.equipprof,null,pl.custid,pl.item,pl.lpid,
     pl.unitofmeasure,qtyApply,fromloc.pickingseq,oh.loadno,
     oh.stopno,oh.shipno,oh.orderid,oh.shipid,dmd.orderitem,
     dmd.orderlot,tk.priority,tk.priority,null,'ITEMDEMAND',
     sysdate,tk.pickuom,tk.pickqty,tk.picktotype,oh.wave,
     fromloc.pickingzone,tk.cartontype,
     zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
     zlb.staff_hours(pl.facility,pl.custid,pl.item,tk.tasktype,
     fromloc.pickingzone,tk.pickuom,tk.pickqty),tk.cartonseq,
     sp.lpid, sp.type,zwv.cartontype_group(tk.cartontype));
  update plate
     set qtytasked = nvl(qtytasked,0) + qtyApply
   where lpid = in_lpid
     and parentfacility is not null;
   if qtyApply >= dmd.qty then
     delete from itemdemand
      where current of curItemDemand;
   else
     update itemdemand
        set qty = qty - qtyApply
      where current of curItemDemand;
   end if;
<<continue_demand_loop>>
  null;
end loop;

<<finish_it>>

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zidcis ' || sqlerrm;
  out_errorno := sqlcode;
end check_for_active_itemdemand;

procedure check_xdock_receipt_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_custid varchar2
,in_orderitem varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select *
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem;
od curOrderDtl%rowtype;

begin

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_errorno := -1;
  out_msg := 'Cross Dock Receipt Order not found: ' || in_orderid ||
    '-' || in_shipid;
  return;
end if;

if oh.ordertype not in ('R','Q','P','A') then
  out_errorno := -2;
  out_msg := 'Cross Dock Receipt Order must be an inbound order: ' || oh.ordertype;
  return;
end if;

if oh.tofacility != in_facility then
  out_errorno := -3;
  out_msg := 'Cross Dock Receipt Order not destined for this order''s facility: ' || oh.tofacility;
  return;
end if;

if oh.custid != in_custid then
  out_errorno := -4;
  out_msg := 'Cross Dock Receipt Order associated with different customer: ' || oh.custid;
  return;
end if;

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;
if od.orderid is null then
  out_errorno := -5;
  out_msg := 'Receipt Order Detail not on file for this item';
  return;
end if;

if od.linestatus = 'X' then
  out_errorno := -6;
  out_msg := 'Receipt Order Detail is cancelled';
  return;
end if;

if oh.orderstatus > '3' then
  out_errorno := -7;
  out_msg := 'Cross Dock Receipt Order must be entered or planned: ' || in_orderid ||
    '-' || in_shipid;
  return;
end if;

out_errorno := 0;
out_msg := 'OKAY';

exception when others then
  out_msg := 'zidcxro ' || sqlerrm;
  out_errorno := sqlcode;
end check_xdock_receipt_order;

procedure unhold_outbound_xdock_orders
(in_orderid number
,in_shipid number
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderDtl is
  select distinct orderid,shipid
    from orderdtl od
   where xdockorderid = in_orderid
     and xdockshipid = in_shipid
     and linestatus != 'X'
     and exists (select *
                   from orderhdr oh
                  where od.orderid = oh.orderid
                    and od.shipid = oh.shipid
                    and oh.orderstatus = '0');

cursor curOtherXDockOrders(this_orderid number, this_shipid number) is
  select count(1) as count
    from orderdtl od
   where orderid = this_orderid
     and shipid = this_shipid
     and linestatus != 'X'
     and xdockorderid != in_orderid
     and xdockshipid != in_shipid
     and exists (select *
                  from orderhdr oh
                 where od.xdockorderid = oh.orderid
                   and od.xdockshipid = oh.shipid
                   and oh.orderstatus < 'A');
ox curOtherXDockOrders%rowtype;

begin

out_errorno := 0;
out_msg := '';

for od in curOrderDtl
loop
  open curOtherXDockOrders(od.orderid,od.shipid);
  fetch curOtherXDockOrders into ox;
  close curOtherXDockOrders;
  if ox.count = 0 then  -- if no other xdock orders pending, release held order
    update orderhdr
       set orderstatus = '1',
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = od.orderid
       and shipid = od.shipid;
  end if;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ziduoxo ' || sqlerrm;
  out_errorno := sqlcode;
end unhold_outbound_xdock_orders;

end zitemdemand;
/
show errors package body zitemdemand;
exit;
