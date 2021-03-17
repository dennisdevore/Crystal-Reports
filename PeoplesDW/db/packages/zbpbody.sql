create or replace package body alps.batchpicks as
--
-- $Id$
--

procedure generate_batch_tasks
(in_wave number
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_batchcartontype varchar2
,in_sortloc varchar2
,in_userid varchar2
,in_trace varchar2
,in_consolidated varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curBatchSum is
  select custid,
         orderitem,
         item,
         orderlot,
         nvl(lpid,'(none)') as lpid,
         fromloc,
         invstatus,
         inventoryclass,
         uom,
         pickuom,
         picktotype,
         cartontype,
         qtytype,
         sum(qty) as qty,
         sum(pickqty) as pickqty
    from batchtasks
   where wave = in_wave
     and facility is null
     and taskid = 0
     and tasktype = 'BP'
   group by custid,orderitem,item,orderlot,lpid,fromloc,invstatus,
         inventoryclass,uom,pickuom,picktotype,cartontype,qtytype
   order by custid,orderitem,item,orderlot,lpid,fromloc,invstatus,
         inventoryclass,uom,pickuom,picktotype,cartontype,qtytype;

cursor curPlate(in_lpid varchar2) is
  select lpid,
         location,
         quantity,
         holdreason,
         unitofmeasure,
         serialnumber,
         lotnumber,
         useritem1,
         useritem2,
         useritem3,
         nvl(qtyrcvd,0) qtyrcvd
    from plate
   where lpid = in_lpid;
lp curPlate%rowtype;

cursor curItem (in_custid varchar2, in_item varchar2) is
  select rcpt_qty_is_full_qty
    from custitemview
   where custid = in_custid
     and item = in_item;
ci curItem%rowtype;

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

cursor curPickingZone(in_facility varchar2, in_pickingzone varchar2) is
  select picktype
    from zone
   where facility = in_facility
     and zoneid = in_pickingzone;
zo curPickingZone%rowtype;

cursor curWave is
  select nvl(sdi_sortation_yn,'N') sdi_sortation_yn
    from waves
   where wave = in_wave;
wv curWave%rowtype;

shippingplatetype shippingplate.type%type;
sp shippingplate%rowtype;
tk tasks%rowtype;
findbaseqty plate.quantity%type;
findbaseuom tasks.pickuom%type;
findpickuom tasks.pickuom%type;
findpickqty plate.quantity%type;
findpicktotype custitem.picktotype%type;
findcartontype custitem.cartontype%type;
findpickfront char(1);
findpicktype waves.picktype%type;
findwholeunitsonly char(1);
findweight plate.weight%type;
findlabeluom tasks.pickuom%type;
cntTasks integer;
batchcartontype waves.batchcartontype%type;
uomtofind varchar2(12);
stdAllocation boolean;
passCount number;

procedure trace_msg(in_msg varchar2) is
strMsg appmsgs.msgtext%type;

begin

  if nvl(in_trace,'x') != 'Y' then
    return;
  end if;

  zms.log_msg('GENBATCH', in_facility, null,
    substr(in_msg,1,254), 'T', in_userid, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';

trace_msg('begin generate batch tasks');
if rtrim(in_batchcartontype) is null then
  begin
    select rtrim(substr(defaultvalue,1,10))
      into batchcartontype
      from systemdefaults
     where defaultid = 'BATCHTOTETYPE';
  exception when others then
    batchcartontype := 'TOTE';
  end;
else
  batchcartontype := in_batchcartontype;
end if;

wv := null;
open curWave;
fetch curWave into wv;
close curWave;

cntTasks := 0;

for bs in curBatchSum
loop
  trace_msg('batchsum: ' || bs.item || ' ' || bs.orderlot || ' ' ||
       bs.invstatus || ' ' || bs.inventoryclass || ' ' || bs.qty || ' '
       || bs.qtytype);
  if bs.lpid != '(none)' then
    open curPlate(bs.lpid);
    fetch curPlate into lp;
    close curPlate;
    open curLocation(in_facility,lp.location);
    fetch curLocation into fromloc;
    close curLocation;
    open curLocation(in_facility,in_sortloc);
    fetch curLocation into toloc;
    close curLocation;
    if bs.qty = lp.quantity then
      shippingplatetype := 'F';
    else
      shippingplatetype := 'P';
    end if;
    tk.taskid := 0;
    tk.cartonseq := null;
    tk.tasktype := 'BP';
    tk.facility := null;
    findlabeluom := null;
    if in_consolidated = 'Y' then
      if (nvl(rtrim(in_picktype),'(none)') <> '(none)') then
        zo.picktype := in_picktype;
      else
        zo := null;
        open curPickingZone(in_facility,fromloc.pickingzone);
        fetch curPickingZone into zo;
        close curPickingZone;
      end if;
      if nvl(zo.picktype,'x') not in ('ORDR','LINE') then
        zo.picktype := 'LINE';
      end if;
      if zo.picktype = 'LINE' then
        tk.tasktype := 'PK';
      else
        tk.tasktype := 'OP';
      end if;
      bs.cartontype := zci.cartontype(bs.custid, bs.item, bs.pickuom);
      if bs.picktotype in ('PAL','FULL') then
        if zwv.single_shipping_units_only(in_wave, 0) = 'Y' then
          bs.picktotype := 'LBL';
        end if;
      end if;
      if findwholeunitsonly = 'Y' then
        findlabeluom := findpickuom;
      end if;
    else
    	if (nvl(rtrim(in_picktype),'(none)') = '(none)') then
        open curPickingZone(in_facility,fromloc.pickingzone);
        fetch curPickingZone into zo;
        close curPickingZone;
        if zo.picktype = 'LINE' then
          tk.tasktype := 'PK';
        elsif zo.picktype = 'ORDR' then
          tk.tasktype := 'OP';
        else
          tk.tasktype := 'BP';
        end if;
      end if;

      if bs.picktotype not in ('FULL','PAL','LBL') then
        bs.picktotype := 'TOTE';
        bs.cartontype := batchcartontype;
      end if;

      open curItem(bs.custid,bs.item);
      fetch curItem into ci;
      close curItem;
      if (ci.rcpt_qty_is_full_qty = 'Y') then
        if (bs.qty = lp.qtyrcvd) and (bs.qty = lp.quantity) then
          bs.picktotype := 'FULL';
        elsif (tk.tasktype = 'BP') and (wv.sdi_sortation_yn = 'Y') then
          bs.picktotype := 'TOTE';
        end if;
      end if;

    end if;
    trace_msg('gbtl subtasks insert ' || bs.item || ' ' || bs.qty);
    insert into subtasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
       shippinglpid, shippingtype, cartongroup, labeluom)
      values
      (tk.taskid,tk.tasktype,tk.facility,
       fromloc.section,lp.location,fromloc.equipprof,toloc.section,
       in_sortloc,toloc.equipprof,null,bs.custid,bs.item,lp.lpid,
       lp.unitofmeasure,bs.qty,fromloc.pickingseq,null,
       null,null,0,0,bs.orderitem,bs.orderlot,in_taskpriority,
       in_taskpriority,null,in_userid,sysdate,
       bs.pickuom,bs.pickqty,bs.picktotype,in_wave,
       fromloc.pickingzone,bs.cartontype,
       zcwt.lp_item_weight(lp.lpid,bs.custid,bs.item,bs.pickuom) * bs.pickqty,
       zci.item_cube(bs.custid,bs.item,bs.pickuom) * bs.pickqty,
       zlb.staff_hours(in_facility,bs.custid,bs.item,tk.tasktype,
       fromloc.pickingzone,bs.pickuom,bs.pickqty),tk.cartonseq,
       null, shippingplatetype, zwv.cartontype_group(bs.cartontype),findlabeluom);
    cntTasks := cntTasks + 1;
    goto continue_batch_loop;
  end if;
  stdAllocation := True;
  while bs.qty > 0
  loop
    out_msg := '';
    if stdAllocation = True then
      uomtofind := ''; -- follow standard allocation qty rules
    else
      uomtofind := 'IGNORE';  -- follow rules but disregard quantity
    end if;
    trace_msg('gbt prefind: ' || bs.item || ' ' || bs.orderlot || ' ' ||
       bs.invstatus || ' ' || bs.inventoryclass || ' ' || bs.qty || ' '
       || bs.qtytype || ' ' || uomtofind);
    passCount := 1;
<< find_again >>
    findpicktype := 'BAT';
    zwv.find_a_pick(in_facility,bs.custid,null,null,bs.item,bs.orderlot,
      bs.invstatus, bs.inventoryclass, bs.qty,
      uomtofind, 'N', -- NOT replenish request
      'STO', 'N', 'E', in_wave, 'N', null, 'N', 'N', 0, null, passCount,
      lp.lpid, findbaseuom, findbaseqty, findpickuom, findpickqty,
      findpickfront, findpicktotype, findcartontype, findpicktype,
      findwholeunitsonly,findweight,in_trace,out_msg);
    trace_msg('gbt postfind: ' || bs.item || ' ' || bs.orderlot || ' ' ||
      bs.invstatus || ' ' || bs.inventoryclass || ' ' || bs.qty || ' ' ||
      lp.lpid || ' ' || findbaseqty || ' ' || findpickuom || ' ' || findpickqty ||
      ' ' || findpickfront || ' ' || out_msg);
    if substr(out_msg,1,4) = 'OKAY' then
      if findpickfront = 'Y' then
        lp.location := lp.lpid;
        lp.lpid := null;
        lp.quantity := findbaseqty;
        lp.holdreason := null;
        lp.unitofmeasure := findbaseuom;
        lp.serialnumber := null;
        lp.lotnumber := null;
        lp.useritem1 := null;
        lp.useritem2 := null;
        lp.useritem3 := null;
      elsif lp.lpid is not null then
        open curPlate(lp.lpid);
        fetch curPlate into lp;
        close curPlate;
      else
        lp.quantity := 0;
      end if;
      bs.qty := bs.qty - findbaseqty;
      if (findpickfront = 'N') and
         (findbaseqty = lp.quantity) then
        shippingplatetype := 'F';
      else
        shippingplatetype := 'P';
      end if;
      tk.cartonseq := null;
      tk.tasktype := 'BP';
      tk.taskid := 0;
      tk.facility := null;
      findlabeluom := null;
      open curLocation(in_facility,lp.location);
      fetch curLocation into fromloc;
      close curLocation;
      open curLocation(in_facility,in_sortloc);
      fetch curLocation into toloc;
      close curLocation;
      if in_consolidated = 'Y' then
        if (nvl(rtrim(in_picktype),'(none)') <> '(none)') then
          zo.picktype := in_picktype;
        else
          open curPickingZone(in_facility,fromloc.pickingzone);
          fetch curPickingZone into zo;
          close curPickingZone;
        end if;
        if nvl(zo.picktype,'x') not in ('ORDR','LINE') then
          zo.picktype := 'ORDR';
        end if;
        if zo.picktype = 'LINE' then
          tk.tasktype := 'PK';
        else
          tk.tasktype := 'OP';
        end if;
        findcartontype := zci.cartontype(bs.custid, bs.item, findpickuom);
        if findpicktotype in ('PAL','FULL') then
          if zwv.single_shipping_units_only(in_wave, 0) = 'Y' then
            findpicktotype := 'LBL';
          end if;
        end if;
        if findwholeunitsonly = 'Y' then
          findlabeluom := findpickuom;
        end if;
      else
      	if (nvl(rtrim(in_picktype),'(none)') = '(none)') then
          open curPickingZone(in_facility,fromloc.pickingzone);
          fetch curPickingZone into zo;
          close curPickingZone;
          if zo.picktype = 'LINE' then
            tk.tasktype := 'PK';
          elsif zo.picktype = 'ORDR' then
            tk.tasktype := 'OP';
          else
            tk.tasktype := 'BP';
          end if;
        end if;
        open curItem(bs.custid,bs.item);
        fetch curItem into ci;
        close curItem;
        if findpicktotype not in ('FULL','PAL','LBL') then
          findpicktotype := 'TOTE';
          findcartontype := batchcartontype;
        end if;
        if (ci.rcpt_qty_is_full_qty = 'Y') then
          if (findbaseqty = lp.qtyrcvd) and (findbaseqty = lp.quantity) then
            findpicktotype := 'FULL';
          elsif (tk.tasktype = 'BP') and (wv.sdi_sortation_yn = 'Y') then
            findpicktotype := 'TOTE';
          end if;
        end if;
      end if;
      trace_msg('gbtn subtasks insert ' || bs.item || ' ' || findbaseqty);
      insert into subtasks
        (taskid, tasktype, facility, fromsection, fromloc,
         fromprofile,tosection,toloc,toprofile,touserid,
         custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
         orderid,shipid,orderitem,orderlot,priority,
         prevpriority,curruserid,lastuser,lastupdate,
         pickuom, pickqty, picktotype, wave,
         pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
         shippinglpid, shippingtype, cartongroup, labeluom)
        values
        (tk.taskid,tk.tasktype,tk.facility,
         fromloc.section,lp.location,fromloc.equipprof,toloc.section,
         in_sortloc,toloc.equipprof,null,bs.custid,bs.item,lp.lpid,
         lp.unitofmeasure,findbaseqty,fromloc.pickingseq,null,null,null,
         0,0,bs.orderitem,bs.orderlot,
         in_taskpriority,in_taskpriority,null,in_userid,
         sysdate,findpickuom,findpickqty,findpicktotype,in_wave,
         fromloc.pickingzone,findcartontype,
         zcwt.lp_item_weight(lp.lpid,bs.custid,bs.item,findpickuom) * findpickqty,
         zci.item_cube(bs.custid,bs.item,findpickuom) * findpickqty,
         zlb.staff_hours(in_facility,bs.custid,bs.item,tk.tasktype,
         fromloc.pickingzone,findpickuom,findpickqty),tk.cartonseq,
         null, shippingplatetype, zwv.cartontype_group(findcartontype),findlabeluom);
      cntTasks := cntTasks + 1;
      if lp.lpid is not null then
        update plate
           set qtytasked = nvl(qtytasked,0) + findbaseqty,
		       lastuser = in_userid,
           lastupdate = sysdate
         where lpid = lp.lpid
           and parentfacility is not null;
      end if;
    else
      if (nvl(passCount,2) < 2) then
        passCount := nvl(passCount,2) + 1;
        goto find_again;
      end if;
      if stdAllocation = True then
        stdAllocation := False;
      else
        if (bs.qtytype = 'E') or (cntTasks = 0) then
          out_msg := out_msg || ' ' || in_wave || '-' ||
            0 || ' ' || bs.item || ' ' || bs.orderlot || ' ' ||
            bs.invstatus || ' ' || bs.inventoryclass || ' ' || bs.qty;
          zms.log_msg('WaveRelease', in_facility, bs.custid,
            out_msg, 'W', in_userid, out_msg);
        elsif out_msg = 'No inventory found' then
          out_msg := 'No more inventory found' || ' ' || in_wave || '-' ||
            0 || ' ' || bs.item || ' ' || bs.orderlot || ' ' ||
            bs.invstatus || ' ' || bs.inventoryclass || ' ' || bs.qty;
          zms.log_msg('WaveRelease', in_facility, bs.custid,
            out_msg, 'W', in_userid, out_msg);
        end if;
        bs.qty := 0;
      end if;
    end if;
  end loop; -- task create loop
<<continue_batch_loop>>
  null;
end loop;

if cntTasks != 0 then
  zwv.complete_pick_tasks(in_wave,in_facility,0,0,in_taskpriority,in_taskpriority,
    in_picktype,in_userid,null,null,in_consolidated,in_trace,out_errorno,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveRelease', in_facility, null,
        out_msg, 'W', in_userid, out_msg);
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'bpcbt ' || sqlerrm;
  out_errorno := sqlcode;
end generate_batch_tasks;

procedure allocate_picks_to_orders
(in_wave number
,in_facility varchar2
,in_orderid number
,in_shipid number
,in_taskpriority varchar2
,in_picktype varchar2
,in_userid varchar2
,in_consolidated varchar2
,in_trace varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curSubTasks is
  select taskid,
         lpid,
         custid,
         item,
         qty,
         pickqty,
         pickuom,
         tasktype,
         orderitem,
         orderlot,
         fromloc,
         fromprofile,
         locseq,
         rowid subtasksrowid
    from subtasks
   where wave = in_wave
     and facility is null
     and orderid = in_orderid
     and shipid = in_shipid
     and not exists (select 1
                       from zone
                      where zone.facility = in_facility
                        and zone.zoneid = subtasks.pickingzone
                        and nvl(zone.deconsolidation,'N') = 'Y')
   order by qty desc, tasktype, picktotype, cartontype, locseq,
            fromloc, item;
sb  curSubTasks%rowtype;

cursor curSubTasksDecon is
  select taskid,
         lpid,
         custid,
         item,
         qty,
         pickqty,
         pickuom,
         tasktype,
         orderitem,
         orderlot,
         fromloc,
         fromprofile,
         locseq,
         rowid subtasksrowid
    from subtasks
   where wave = in_wave
     and facility is null
     and orderid = in_orderid
     and shipid = in_shipid
     and exists (select 1
                   from zone
                  where zone.facility = in_facility
                    and zone.zoneid = subtasks.pickingzone
                    and nvl(zone.deconsolidation,'N') = 'Y')
   order by qty, tasktype, picktotype, cartontype, locseq,
            fromloc, item;

cursor curBatchTasks(in_custid varchar2, in_item varchar2, in_lot varchar2) is
  select bt.*
    from batchtasksview bt, orderhdr oh
   where bt.wave = in_wave
     and bt.taskid = 0
     and bt.custid = in_custid
     and bt.orderitem = in_item
     and nvl(bt.orderlot,'(none)') = nvl(in_lot,'(none)')
     and oh.orderid = bt.orderid
     and oh.shipid = bt.shipid
   order by nvl(oh.original_wave_before_combine,0), bt.qty desc, bt.orderid, bt.shipid;
  /*select batchtasks.*,
         rowid batchtasksrowid
    from batchtasks
   where wave = in_wave
     and taskid = 0
     and custid = in_custid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lot,'(none)')
   order by qty desc, orderid, shipid; */

cursor curBatchTasks2(in_taskid number, in_custid varchar2, in_item varchar2, in_lot varchar2) is
  select batchtasksview.*
         --rowid batchtasksrowid
    from batchtasksview
   where taskid = in_taskid
     and custid = in_custid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lot,'(none)')
     and not exists
     (select 1
        from subtasks stv
       where taskid = in_taskid
         and tasktype = 'BP');

cursor curPlate(in_lpid varchar2) is
  select lpid,
         location,
         quantity,
         holdreason,
         unitofmeasure,
         serialnumber,
         lotnumber,
         useritem1,
         useritem2,
         useritem3
    from plate
   where lpid = in_lpid;

cursor curWave(in_wave number) is
  select stageloc
    from waves
   where wave = in_wave;

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select oh.orderid,
         oh.shipid,
         oh.loadno,
         oh.stopno,
         oh.shipno,
         nvl(oh.stageloc,nvl(lds.stageloc,ld.stageloc)) stageloc,
         oh.carrier,
         oh.fromfacility,
         oh.shiptype
    from orderhdr oh, loads ld, loadstop lds
   where orderid = in_orderid
     and shipid = in_shipid
     and oh.loadno = ld.loadno(+)
     and oh.loadno = lds.loadno(+)
     and oh.stopno = lds.stopno(+);

cursor curOrderDtl(in_orderid number, in_shipid number, in_item varchar2, in_lotnumber varchar2) is
  select item,
         lotnumber,
         qtyentered,
         uomentered
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');

cursor curCarrierStageLoc(in_carrier varchar2, in_fromfacility varchar2, in_shiptype varchar2) is
  select stageloc
    from carrierstageloc
   where carrier = in_carrier
     and facility = in_fromfacility
     and shiptype = in_shiptype;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select locid,
         section,
         equipprof
    from location
   where facility = in_facility
     and locid = in_locid;

cursor curParentPlates is
  select pl.parentlpid, st.taskid, st.fromloc, st.item, st.orderlot, sum(st.qty)
    from subtasks st, plate pl, custitemview cit
   where st.wave = in_wave
     and st.picktotype = 'FULL'
     and st.tasktype = 'BP'
     and cit.custid = st.custid
     and cit.item = st.item
     and cit.rcpt_qty_is_full_qty = 'Y'
     and pl.lpid = st.lpid
   group by pl.parentlpid, st.taskid, st.fromloc, st.item, st.orderlot
  having sum(st.qty) = (
    select quantity
      from plate
     where lpid = pl.parentlpid
       and item = st.item
       and (nvl(lotnumber,'(none)') = nvl(st.orderlot,'(none)')
        or  st.orderlot is null));
cpp curParentPlates%rowtype;

bt curBatchTasks%rowtype;
bt2 curBatchTasks%rowtype;
lp curPlate%rowtype;
wv curWave%rowtype;
oh curOrderHdr%rowtype;
od curOrderDtl%rowtype;
cs curCarrierStageLoc%rowtype;
toloc curLocation%rowtype;
wrkQty subtasks.qty%type;
new batchtasks%rowtype;

procedure trace_msg(in_msg varchar2) is
strOutMsg appmsgs.msgtext%type;
numCols integer;

begin

  if nvl(in_trace,'x') != 'Y' then
    return;
  end if;

  numCols := 1;
  while (numCols * 254) < (Length(in_msg)+254)
  loop
    zms.log_msg('BATCHALLOC', in_facility, bt.custid,
                substr(in_msg,((numCols-1)*254)+1,254),
                'T', in_userid, strOutMsg);
    numCols := numCols + 1;
  end loop;

end;

begin

trace_msg('begin allocate picks to orders-*not* deconsolidated');
open curSubTasks;
while (1=1)
loop
  sb := null;
  fetch curSubTasks into sb;
  if curSubTasks%notfound then
    exit;
  end if;
  wrkQty := sb.qty;
  trace_msg('sub task ' || sb.tasktype || ' ' || sb.orderitem || ' '  || sb.orderlot ||
            ' ' || sb.qty || ' ' || wrkQty);
  while (wrkQty > 0)
  loop
    bt := null;
    open curBatchTasks(sb.custid, sb.orderitem, sb.orderlot);
    fetch curBatchTasks into bt;
    if curBatchTasks%notfound then
      trace_msg('no more batch ' || sb.custid || ' ' || sb.orderitem || ' ' ||
                sb.orderlot || ' ' || sb.lpid || ' ' || sb.qty || ' ' || wrkQty);
      zms.log_msg('BatchAlloc', in_facility, sb.custid,
     'No more: ' || sb.orderitem || ' ' || sb.orderlot || ' ' ||
       bt.invstatus || ' ' || bt.inventoryclass || ' ' || sb.qty,
      'I', in_userid, out_msg);
      close curBatchTasks;
      exit;
    end if;
    close curBatchTasks;
    if (wrkQty = sb.qty) and
       (bt.qty = sb.qty) then
      trace_msg('one only ' || sb.item || ' ' || wrkQty);
      update batchtasks
         set taskid = sb.taskid,
             pickuom = sb.pickuom,
             pickqty = sb.pickqty,
             lpid = sb.lpid,
             item = sb.item,
             fromloc = sb.fromloc,
             fromprofile = sb.fromprofile
       where rowid = bt.batchtasksrowid;
      wrkQty := 0;
    elsif bt.qty <= wrkQty then
      update batchtasks
         set taskid = sb.taskid,
             pickuom = uom,
             pickqty = bt.qty,
             lpid = sb.lpid,
             item = sb.item,
             fromloc = sb.fromloc,
             fromprofile = sb.fromprofile
       where rowid = bt.batchtasksrowid;
      trace_msg('pick set to base ' || sb.item || ' ' || bt.qty);
      wrkQty := wrkQty - bt.qty;
    else
      bt2 := bt;
      bt.qty := wrkQty;
      bt2.qty := bt2.qty - bt.qty;
      if (wrkQty = sb.qty) then
        new.pickuom := sb.pickuom;
        new.pickqty := sb.pickqty;
      else
        new.pickuom := bt.uom;
        new.pickqty := bt.qty;
      end if;
      update batchtasks
         set taskid = sb.taskid,
             qty = bt.qty,
             pickuom = new.pickuom,
             pickqty = new.pickqty,
             weight = zcwt.lp_item_weight(sb.lpid,bt.custid,bt.item,bt.uom) * bt.qty,
             cube = zci.item_cube(bt.custid,bt.item,bt.uom) * bt.qty,
             staffhrs = zlb.staff_hours(in_facility,bt.custid,bt.item,bt.tasktype,
               bt.pickingzone,bt.uom,bt.qty),
             lpid = sb.lpid,
             item = sb.item,
             fromloc = sb.fromloc,
             fromprofile = sb.fromprofile
       where rowid = bt.batchtasksrowid;
      trace_msg('bsum batchtask update  ' || bt.item || ' ' || bt.qty);
      trace_msg('bsum batchtasks insert ' || bt.item || ' ' || bt2.qty);
      insert into batchtasks
        (taskid, tasktype, facility, fromsection, fromloc,
         fromprofile,tosection,toloc,toprofile,touserid,
         custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
         orderid,shipid,orderitem,orderlot,priority,
         prevpriority,curruserid,lastuser,lastupdate,
         pickuom, pickqty, picktotype, wave,
         pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
         shippinglpid, shippingtype, invstatus, inventoryclass,
         qtytype, lotnumber)
      values
        (0,bt2.tasktype,bt2.facility,
         bt2.fromsection,bt2.fromloc,bt2.fromprofile,bt2.tosection,
         bt2.toloc,bt2.toprofile,null,bt2.custid,bt2.item,bt2.lpid,
         bt2.uom,bt2.qty,bt2.locseq,bt2.loadno,
         bt2.stopno,bt2.shipno,bt2.orderid,bt2.shipid,bt2.orderitem,
         bt2.orderlot,bt2.priority,bt2.prevpriority,null,in_userid,
         sysdate,bt2.uom,bt2.qty,bt2.picktotype,bt2.wave,
         bt2.pickingzone,bt2.cartontype,
         zcwt.lp_item_weight(sb.lpid,bt2.custid,bt2.item,bt2.uom) * bt2.qty,
         zci.item_cube(bt2.custid,bt2.item,bt2.uom) * bt2.qty,
         zlb.staff_hours(in_facility,bt2.custid,bt2.item,bt2.tasktype,
         bt2.pickingzone,bt2.uom,bt2.qty),bt2.cartonseq,
         null, bt2.shippingtype, bt2.invstatus, bt2.inventoryclass,
         bt2.qtytype, bt2.lotnumber);
      wrkQty := 0;
    end if;
  end loop;
  if ((in_consolidated <> 'Y') and ((sb.tasktype = 'PK') or (sb.tasktype = 'OP'))) then
    bt := null;
    open curBatchTasks2(sb.taskid, sb.custid, sb.orderitem, sb.orderlot);
    fetch curBatchTasks2 into bt;
    if curBatchTasks2%notfound then
      trace_msg('deconsolidated batch task not found');
      close curBatchTasks2;
    else
      close curBatchTasks2;
      
      oh := null;
      open curOrderHdr(bt.orderid, bt.shipid);
      fetch curOrderHdr into oh;
      close curOrderHdr;

      if oh.stageloc is null then
        wv := null;
        open curWave(bt.wave);
        fetch curWave into wv;
        close curWave;
        if wv.stageloc is not null then
          oh.stageloc := wv.stageloc;
        else
          cs := null;
          open curCarrierStageloc(oh.carrier, oh.fromfacility, oh.shiptype);
          fetch curCarrierStageLoc into cs;
          close curCarrierStageLoc;
          if cs.stageloc is not null then
            oh.stageloc := cs.stageloc;
          else
            oh.stageloc := bt.toloc;
          end if;
        end if;
      end if;

      toloc := null;
      open curLocation(oh.fromfacility,oh.stageloc);
      fetch curLocation into toloc;
      close curLocation;

      zsp.get_next_shippinglpid(bt.shippinglpid,out_msg);

    	update subtasks
    	   set facility = in_facility,
    	       item = bt.item,
    	       orderitem = bt.orderitem,
    	       orderlot = bt.orderlot,
    	       lpid = bt.lpid,
    	       picktotype = bt.picktotype,
    	       qty = bt.qty,
    	       weight = weight * (bt.qty / sb.qty),
    	       cube = cube * (bt.qty / sb.qty),
    	       uom = bt.uom,
    	       pickqty = bt.pickqty,
    	       pickuom = bt.pickuom,
    	       shippinglpid = bt.shippinglpid,
    	       orderid = bt.orderid,
    	       shipid = bt.shipid,
    	       loadno = bt.loadno,
    	       stopno = bt.stopno,
    	       shipno = bt.shipno,
    	       tosection = toloc.section,
    	       toloc = toloc.locid,
    	       toprofile = toloc.equipprof
    	 where rowid = sb.subtasksrowid;
    	update tasks
    	   set facility = in_facility,
    	       item = decode(sb.tasktype,'OP',null,bt.item),
    	       orderitem = decode(sb.tasktype,'OP',null,bt.orderitem),
    	       orderlot = decode(sb.tasktype,'OP',null,bt.orderlot),
    	       lpid = decode(sb.tasktype,'OP',null,bt.lpid),
    	       picktotype = decode(sb.tasktype,'OP',null,bt.picktotype),
    	       qty = bt.qty,
    	       weight = weight * (bt.qty / sb.qty),
    	       cube = cube * (bt.qty / sb.qty),
    	       pickqty = bt.pickqty,
    	       orderid = bt.orderid,
    	       shipid = bt.shipid,
    	       loadno = bt.loadno,
    	       stopno = bt.stopno,
    	       shipno = bt.shipno,
    	       tosection = toloc.section,
    	       toloc = toloc.locid,
    	       toprofile = toloc.equipprof
    	 where taskid = sb.taskid;
    	if bt.lpid is not null then
    		update plate
    		   set qtytasked = qtytasked + bt.qty - sb.qty
    		 where lpid = bt.lpid;
      end if;

      if in_trace = 'Y' then
        trace_msg('Insert shipping: ' || bt.item || ' ' || bt.lotnumber || ' ' ||
                   bt.invstatus || ' ' || bt.inventoryclass || ' ' || bt.qty || ' ' ||
                   bt.lpid);
      end if;
      lp := null;
      open curPlate(bt.lpid);
      fetch curPlate into lp;
      close curPlate;
      od := null;
      open curOrderDtl(bt.orderid, bt.shipid, bt.orderitem, bt.orderlot);
      fetch curOrderDtl into od;
      close curOrderDtl;

      insert into shippingplate
        (lpid, item, custid, facility, location, status, holdreason,
        unitofmeasure, quantity, type, fromlpid, serialnumber,
        lotnumber, parentlpid, useritem1, useritem2, useritem3,
        lastuser, lastupdate, invstatus, qtyentered, orderitem,
        uomentered, inventoryclass, loadno, stopno, shipno,
        orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
        pickuom, pickqty, cartonseq)
        values
        (bt.shippinglpid, bt.item, bt.custid, in_facility, lp.location,
         'U', lp.holdreason, lp.unitofmeasure, bt.qty,
         bt.shippingtype, bt.lpid, lp.serialnumber, lp.lotnumber, null,
         lp.useritem1, lp.useritem2, lp.useritem3,
         in_userid, sysdate, bt.invstatus, od.qtyentered,
         od.item, od.uomentered, bt.inventoryclass,
         oh.loadno, oh.stopno, oh.shipno, bt.orderid,
         bt.shipid, zcwt.lp_item_weight(lp.lpid,bt.custid,bt.item,bt.pickuom) * bt.pickqty,
         null, null, bt.taskid, od.lotnumber,
         bt.pickuom, bt.pickqty, bt.cartonseq);

      delete from batchtasks
       where rowid = bt.batchtasksrowid;
    end if;
  end if;
end loop;
close curSubTasks;

trace_msg('begin allocate picks to orders-deconsolidated');
open curSubTasksDecon;
while (1=1)
loop
  sb := null;
  fetch curSubTasksDecon into sb;
  if curSubTasksDecon%notfound then
    exit;
  end if;
  wrkQty := sb.qty;
  trace_msg('sub task ' || sb.tasktype || ' ' || sb.orderitem || ' '  || sb.orderlot ||
            ' ' || sb.qty || ' ' || wrkQty);
  while (wrkQty > 0)
  loop
    bt := null;
    open curBatchTasks(sb.custid, sb.orderitem, sb.orderlot);
    fetch curBatchTasks into bt;
    if curBatchTasks%notfound then
      trace_msg('no more batch ' || sb.custid || ' ' || sb.orderitem || ' ' ||
                sb.orderlot || ' ' || sb.lpid || ' ' || sb.qty || ' ' || wrkQty);
      close curBatchTasks;
      zms.log_msg('BatchAlloc', in_facility, sb.custid,
     'No more: ' || sb.orderitem || ' ' || sb.orderlot || ' ' ||
       bt.invstatus || ' ' || bt.inventoryclass || ' ' || sb.qty,
      'I', in_userid, out_msg);
      close curBatchTasks;
      exit;
    end if;
    close curBatchTasks;
    if (wrkQty = sb.qty) and
       (bt.qty = sb.qty) then
      trace_msg('one only ' || sb.item || ' ' || wrkQty);
      update batchtasks
         set taskid = sb.taskid,
             pickuom = sb.pickuom,
             pickqty = sb.pickqty,
             lpid = sb.lpid,
             item = sb.item,
             fromloc = sb.fromloc,
             fromprofile = sb.fromprofile
       where rowid = bt.batchtasksrowid;
      wrkQty := 0;
    elsif bt.qty <= wrkQty then
      update batchtasks
         set taskid = sb.taskid,
             pickuom = uom,
             pickqty = bt.qty,
             lpid = sb.lpid,
             item = sb.item,
             fromloc = sb.fromloc,
             fromprofile = sb.fromprofile
       where rowid = bt.batchtasksrowid;
      trace_msg('pick set to base ' || sb.item || ' ' || bt.qty);
      wrkQty := wrkQty - bt.qty;
    else
      bt2 := bt;
      bt.qty := wrkQty;
      bt2.qty := bt2.qty - bt.qty;
      if (wrkQty = sb.qty) then
        new.pickuom := sb.pickuom;
        new.pickqty := sb.pickqty;
      else
        new.pickuom := bt.uom;
        new.pickqty := bt.qty;
      end if;
      update batchtasks
         set taskid = sb.taskid,
             qty = bt.qty,
             pickuom = new.pickuom,
             pickqty = new.pickqty,
             weight = zcwt.lp_item_weight(sb.lpid,bt.custid,bt.item,bt.uom) * bt.qty,
             cube = zci.item_cube(bt.custid,bt.item,bt.uom) * bt.qty,
             staffhrs = zlb.staff_hours(in_facility,bt.custid,bt.item,bt.tasktype,
               bt.pickingzone,bt.uom,bt.qty),
             lpid = sb.lpid,
             item = sb.item,
             fromloc = sb.fromloc,
             fromprofile = sb.fromprofile
       where rowid = bt.batchtasksrowid;
      trace_msg('bsum batchtask update  ' || bt.item || ' ' || bt.qty);
      trace_msg('bsum batchtasks insert ' || bt.item || ' ' || bt2.qty);
      insert into batchtasks
        (taskid, tasktype, facility, fromsection, fromloc,
         fromprofile,tosection,toloc,toprofile,touserid,
         custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
         orderid,shipid,orderitem,orderlot,priority,
         prevpriority,curruserid,lastuser,lastupdate,
         pickuom, pickqty, picktotype, wave,
         pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
         shippinglpid, shippingtype, invstatus, inventoryclass,
         qtytype, lotnumber)
      values
        (0,bt2.tasktype,bt2.facility,
         bt2.fromsection,bt2.fromloc,bt2.fromprofile,bt2.tosection,
         bt2.toloc,bt2.toprofile,null,bt2.custid,bt2.item,bt2.lpid,
         bt2.uom,bt2.qty,bt2.locseq,bt2.loadno,
         bt2.stopno,bt2.shipno,bt2.orderid,bt2.shipid,bt2.orderitem,
         bt2.orderlot,bt2.priority,bt2.prevpriority,null,in_userid,
         sysdate,bt2.uom,bt2.qty,bt2.picktotype,bt2.wave,
         bt2.pickingzone,bt2.cartontype,
         zcwt.lp_item_weight(sb.lpid,bt2.custid,bt2.item,bt2.uom) * bt2.qty,
         zci.item_cube(bt2.custid,bt2.item,bt2.uom) * bt2.qty,
         zlb.staff_hours(in_facility,bt2.custid,bt2.item,bt2.tasktype,
         bt2.pickingzone,bt2.uom,bt2.qty),bt2.cartonseq,
         null, bt2.shippingtype, bt2.invstatus, bt2.inventoryclass,
         bt2.qtytype, bt2.lotnumber);
      wrkQty := 0;
    end if;
  end loop;

  if ((in_consolidated <> 'Y') and ((sb.tasktype = 'PK') or (sb.tasktype = 'OP'))) then
    bt := null;
    open curBatchTasks2(sb.taskid, sb.custid, sb.orderitem, sb.orderlot);
    fetch curBatchTasks2 into bt;
    if curBatchTasks2%notfound then
      trace_msg('deconsolidated batch task not found');
      close curBatchTasks2;
    else
      close curBatchTasks2;
      
      oh := null;
      open curOrderHdr(bt.orderid, bt.shipid);
      fetch curOrderHdr into oh;
      close curOrderHdr;

      if oh.stageloc is null then
        wv := null;
        open curWave(bt.wave);
        fetch curWave into wv;
        close curWave;
        if wv.stageloc is not null then
          oh.stageloc := wv.stageloc;
        else
          cs := null;
          open curCarrierStageloc(oh.carrier, oh.fromfacility, oh.shiptype);
          fetch curCarrierStageLoc into cs;
          close curCarrierStageLoc;
          if cs.stageloc is not null then
            oh.stageloc := cs.stageloc;
          else
            oh.stageloc := bt.toloc;
          end if;
        end if;
      end if;

      toloc := null;
      open curLocation(oh.fromfacility,oh.stageloc);
      fetch curLocation into toloc;
      close curLocation;

      zsp.get_next_shippinglpid(bt.shippinglpid,out_msg);

    	update subtasks
    	   set facility = in_facility,
    	       item = bt.item,
    	       orderitem = bt.orderitem,
    	       orderlot = bt.orderlot,
    	       lpid = bt.lpid,
    	       picktotype = bt.picktotype,
    	       qty = bt.qty,
    	       weight = weight * (bt.qty / sb.qty),
    	       cube = cube * (bt.qty / sb.qty),
    	       uom = bt.uom,
    	       pickqty = bt.pickqty,
    	       pickuom = bt.pickuom,
    	       shippinglpid = bt.shippinglpid,
    	       orderid = bt.orderid,
    	       shipid = bt.shipid,
    	       loadno = bt.loadno,
    	       stopno = bt.stopno,
    	       shipno = bt.shipno,
    	       tosection = toloc.section,
    	       toloc = toloc.locid,
    	       toprofile = toloc.equipprof
    	 where rowid = sb.subtasksrowid;
    	update tasks
    	   set facility = in_facility,
    	       item = decode(sb.tasktype,'OP',null,bt.item),
    	       orderitem = decode(sb.tasktype,'OP',null,bt.orderitem),
    	       orderlot = decode(sb.tasktype,'OP',null,bt.orderlot),
    	       lpid = decode(sb.tasktype,'OP',null,bt.lpid),
    	       picktotype = decode(sb.tasktype,'OP',null,bt.picktotype),
    	       qty = bt.qty,
    	       weight = weight * (bt.qty / sb.qty),
    	       cube = cube * (bt.qty / sb.qty),
    	       pickqty = bt.pickqty,
    	       orderid = bt.orderid,
    	       shipid = bt.shipid,
    	       loadno = bt.loadno,
    	       stopno = bt.stopno,
    	       shipno = bt.shipno,
    	       tosection = toloc.section,
    	       toloc = toloc.locid,
    	       toprofile = toloc.equipprof
    	 where taskid = sb.taskid;
    	if bt.lpid is not null then
    		update plate
    		   set qtytasked = qtytasked + bt.qty - sb.qty
    		 where lpid = bt.lpid;
      end if;

      if in_trace = 'Y' then
        trace_msg('Insert shipping: ' || bt.item || ' ' || bt.lotnumber || ' ' ||
                   bt.invstatus || ' ' || bt.inventoryclass || ' ' || bt.qty || ' ' ||
                   bt.lpid);
      end if;
      lp := null;
      open curPlate(bt.lpid);
      fetch curPlate into lp;
      close curPlate;
      od := null;
      open curOrderDtl(bt.orderid, bt.shipid, bt.orderitem, bt.orderlot);
      fetch curOrderDtl into od;
      close curOrderDtl;

      insert into shippingplate
        (lpid, item, custid, facility, location, status, holdreason,
        unitofmeasure, quantity, type, fromlpid, serialnumber,
        lotnumber, parentlpid, useritem1, useritem2, useritem3,
        lastuser, lastupdate, invstatus, qtyentered, orderitem,
        uomentered, inventoryclass, loadno, stopno, shipno,
        orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
        pickuom, pickqty, cartonseq)
        values
        (bt.shippinglpid, bt.item, bt.custid, in_facility, lp.location,
         'U', lp.holdreason, lp.unitofmeasure, bt.qty,
         bt.shippingtype, bt.lpid, lp.serialnumber, lp.lotnumber, null,
         lp.useritem1, lp.useritem2, lp.useritem3,
         in_userid, sysdate, bt.invstatus, od.qtyentered,
         od.item, od.uomentered, bt.inventoryclass,
         oh.loadno, oh.stopno, oh.shipno, bt.orderid,
         bt.shipid, zcwt.lp_item_weight(lp.lpid,bt.custid,bt.item,bt.pickuom) * bt.pickqty,
         null, null, bt.taskid, od.lotnumber,
         bt.pickuom, bt.pickqty, bt.cartonseq);

      delete from batchtasks
       where rowid = bt.batchtasksrowid;
    end if;
  end if;
end loop;
close curSubTasksDecon;

/* Combine tasks where all of a parent plate is being picked */ 
for cpp in curParentPlates
loop
  insert into subtasks
  (taskid,tasktype,facility,fromsection,fromloc,fromprofile,tosection,
   toloc,toprofile,touserid,custid,item,lpid,uom,qty,locseq,loadno,
   stopno,shipno,orderid,shipid,orderitem,orderlot,priority,
   prevpriority,curruserid,lastuser,lastupdate,pickuom,pickqty,
   picktotype,wave,pickingzone,cartontype,weight,cube,staffhrs,
   cartonseq,shippinglpid,shippingtype,cartongroup,qtypicked,labeluom,
   step1_complete)
  select st.taskid,
         st.tasktype,
         st.facility,
         st.fromsection,
         st.fromloc,
         st.fromprofile,
         st.tosection,
         st.toloc,
         st.toprofile,
         null touserid,
         st.custid,
         st.item,
         pl.parentlpid lpid,
         st.uom,
         sum(st.qty) qty,
         st.locseq,
         st.loadno,
         st.stopno,
         st.shipno,
         st.orderid,
         st.shipid,
         st.orderitem,
         st.orderlot,
         st.priority,
         st.prevpriority,
         null curruserid,
         st.lastuser,
         sysdate lastupdate,
         st.pickuom,
         sum(st.pickqty) pickqty,
         st.picktotype,
         st.wave,
         st.pickingzone,
         st.cartontype,
         sum(st.weight) weight,
         sum(st.cube) cube,
         sum(st.staffhrs) staffhrs,
         st.cartonseq,
         st.shippinglpid,
         st.shippingtype,
         st.cartongroup,
         null qtypicked,
         st.labeluom,
         st.step1_complete
    from subtasks st,
         plate pl
   where st.wave = in_wave
     and st.picktotype = 'FULL'
     and st.tasktype = 'BP'
     and st.taskid = cpp.taskid
     and st.fromloc = cpp.fromloc
     and st.item = cpp.item
     and nvl(st.orderlot,'(none)') = nvl(cpp.orderlot,'(none)')
     and pl.lpid = st.lpid
     and pl.parentlpid = cpp.parentlpid
   group by st.taskid,
         st.tasktype,
         st.facility,
         st.fromsection,
         st.fromloc,
         st.fromprofile,
         st.tosection,
         st.toloc,
         st.toprofile,
         st.custid,
         st.item,
         pl.parentlpid,
         st.uom,
         st.locseq,
         st.loadno,
         st.stopno,
         st.shipno,
         st.orderid,
         st.shipid,
         st.orderitem,
         st.orderlot,
         st.priority,
         st.prevpriority,
         st.lastuser,
         st.pickuom,
         st.picktotype,
         st.wave,
         st.pickingzone,
         st.cartontype,
         st.cartonseq,
         st.shippinglpid,
         st.shippingtype,
         st.cartongroup,
         st.labeluom,
         st.step1_complete;

  delete from subtasks st
   where st.wave = in_wave
     and st.picktotype = 'FULL'
     and st.tasktype = 'BP'
     and st.taskid = cpp.taskid
     and st.fromloc = cpp.fromloc
     and st.item = cpp.item
     and nvl(st.orderlot,'(none)') = nvl(cpp.orderlot,'(none)')
     and exists(select 1
                  from plate pl
                 where pl.lpid = st.lpid
                   and pl.parentlpid = cpp.parentlpid);

  insert into batchtasks
  (taskid,tasktype,facility,fromsection,fromloc,fromprofile,tosection,
   toloc,toprofile,touserid,custid,item,lpid,uom,qty,locseq,loadno,
   stopno,shipno,orderid,shipid,orderitem,orderlot,priority,
   prevpriority,curruserid,lastuser,lastupdate,pickuom,pickqty,
   picktotype,wave,pickingzone,cartontype,weight,cube,staffhrs,
   cartonseq,shippinglpid,shippingtype,invstatus,inventoryclass,
   qtytype,lotnumber)
  select bt.taskid,
         bt.tasktype,
         bt.facility,
         bt.fromsection,
         bt.fromloc,
         bt.fromprofile,
         bt.tosection,
         bt.toloc,
         bt.toprofile,
         null touserid,
         bt.custid,
         bt.item,
         pl.parentlpid lpid,
         bt.uom,
         sum(bt.qty) qty,
         bt.locseq,
         bt.loadno,
         bt.stopno,
         bt.shipno,
         bt.orderid,
         bt.shipid,
         bt.orderitem,
         bt.orderlot,
         bt.priority,
         bt.prevpriority,
         null curruserid,
         bt.lastuser,
         sysdate lastupdate,
         bt.pickuom,
         sum(bt.pickqty) pickqty,
         bt.picktotype,
         bt.wave,
         bt.pickingzone,
         bt.cartontype,
         sum(bt.weight) weight,
         sum(bt.cube) cube,
         sum(bt.staffhrs) staffhrs,
         bt.cartonseq,
         bt.shippinglpid,
         bt.shippingtype,
         bt.invstatus,
         bt.inventoryclass,
         bt.qtytype,
         bt.lotnumber
    from batchtasks bt,
         plate pl
   where bt.wave = in_wave
     and bt.tasktype = 'BP'
     and bt.taskid = cpp.taskid
     and bt.fromloc = cpp.fromloc
     and bt.item = cpp.item
     and nvl(bt.orderlot,'(none)') = nvl(cpp.orderlot,'(none)')
     and pl.lpid = bt.lpid
     and pl.parentlpid = cpp.parentlpid
   group by bt.taskid,
         bt.tasktype,
         bt.facility,
         bt.fromsection,
         bt.fromloc,
         bt.fromprofile,
         bt.tosection,
         bt.toloc,
         bt.toprofile,
         bt.custid,
         bt.item,
         pl.parentlpid,
         bt.uom,
         bt.locseq,
         bt.loadno,
         bt.stopno,
         bt.shipno,
         bt.orderid,
         bt.shipid,
         bt.orderitem,
         bt.orderlot,
         bt.priority,
         bt.prevpriority,
         bt.lastuser,
         bt.pickuom,
         bt.picktotype,
         bt.wave,
         bt.pickingzone,
         bt.cartontype,
         bt.cartonseq,
         bt.shippinglpid,
         bt.shippingtype,
         bt.invstatus,
         bt.inventoryclass,
         bt.qtytype,
         bt.lotnumber;

  delete from batchtasks bt
   where bt.wave = in_wave
     and bt.tasktype = 'BP'
     and bt.taskid = cpp.taskid
     and bt.fromloc = cpp.fromloc
     and bt.item = cpp.item
     and nvl(bt.orderlot,'(none)') = nvl(cpp.orderlot,'(none)')
     and exists(select 1
                  from plate pl
                 where pl.lpid = bt.lpid
                   and pl.parentlpid = cpp.parentlpid);
end loop;

-- get rid of any shortages
delete from batchtasks
   where wave = in_wave
     and facility is null
     and taskid = 0;

delete from subtasks
 where wave = in_wave
   and tasktype = 'BP'
   and not exists (select 1
                     from batchtasks
                    where subtasks.taskid = batchtasks.taskid);
delete from tasks
 where wave = in_wave
   and tasktype = 'BP'
   and not exists (select 1
                     from subtasks
                    where tasks.taskid = subtasks.taskid);

update subtasks st
   set picktotype = 'FULL'
 where st.wave = in_wave
   and nvl(picktotype,'xxx') != 'FULL'
   and exists(select 1
                from custitemview ci 
               where ci.custid = st.custid
                 and ci.item = st.item
                 and ci.rcpt_qty_is_full_qty = 'Y')
   and st.qty = (select lp.quantity
                   from plate lp
                  where lp.lpid = st.lpid)
   and st.qty = (select nvl(lp.qtyrcvd,0)
                   from plate lp
                  where lp.lpid = st.lpid);
update subtasks st
   set picktotype = 'TOTE'
 where st.wave = in_wave
   and st.tasktype = 'BP'
   and nvl(picktotype,'xxx') != 'TOTE'
   and exists(select 1
                from waves wv
               where wv.wave = in_wave
                 and nvl(wv.sdi_sortation_yn,'N') = 'Y')
   and exists(select 1
                from custitemview ci 
               where ci.custid = st.custid
                 and ci.item = st.item
                 and ci.rcpt_qty_is_full_qty = 'Y')
   and (st.qty <> (select lp.quantity
                     from plate lp
                    where lp.lpid = st.lpid)
    or  st.qty <> (select nvl(lp.qtyrcvd,0)
                     from plate lp
                    where lp.lpid = st.lpid));
out_msg := 'OKAY';

exception when others then
  out_msg := 'bpapo ' || sqlerrm;
  out_errorno := sqlcode;
end allocate_picks_to_orders;

procedure update_consolidated_tasks
(in_wave number
,in_userid varchar2
,in_trace varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curSubTasks is
  select distinct taskid,tasktype
    from subtasks
   where wave = in_wave;

strMsg varchar2(255);

begin

for st in curSubTasks
loop

  if in_trace = 'Y' then
    zms.log_msg('UpdCons', null, null,
      'SubTask ID ' || st.taskid || ' Task Type ' || st.tasktype, 'T', in_userid, strMsg);
  end if;

  update subtasks
     set orderid = in_wave,
         shipid = 0
   where taskid = st.taskid
     and (orderid <> in_wave
      or  shipid <> 0);

  update tasks
     set orderid = in_wave,
         shipid = 0,
         tasktype = st.tasktype
   where taskid = st.taskid
     and (orderid <> in_wave
      or  shipid <> 0);

end loop;

exception when others then
  out_msg := 'bpuct ' || sqlerrm;
  out_errorno := sqlcode;
end;

PROCEDURE delete_batchtasks_by_orderitem
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,in_reqtype varchar2
,out_msg IN OUT varchar2
) is

cursor curBatchTasks(p_orderid number, p_shipid number) is
  select rowid,
         taskid,
         custid,
         facility,
         lpid,
         orderid,
         shipid,
         orderitem,
         orderlot,
         item,
         weight,
         qty,
         pickqty
    from batchtasks
   where orderid = p_orderid
     and shipid = p_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and not exists
       (select * from tasks
         where batchtasks.taskid = tasks.taskid
           and tasks.priority = '0');

strMsg appmsgs.msgtext%type;
delete_commitments_yn varchar2(1);
cntBatchTasks integer;
cntBatchTasks integer;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_order_complete_yn char(1);
l_qtytasked pls_integer;
l_inventoryclass plate.inventoryclass%type;
l_invstatus plate.invstatus%type;
l_lotnumber plate.lotnumber%type;
l_subtask_cnt pls_integer;
l_batchtask_cnt pls_integer;
l_commit_qty pls_integer;

begin

out_msg := '';

if in_reqtype = '1' then -- wave release form request
  delete_commitments_yn := 'N';
else
  delete_commitments_yn := 'Y';
end if;

l_orderid := zcord.cons_orderid(in_orderid, in_shipid);
if l_orderid = 0 then
  l_orderid := in_orderid;
  l_shipid := in_shipid;
else
  l_shipid := 0;
end if;

if in_reqtype = 'X' then
  l_order_complete_yn := 'Y';
else
  l_order_complete_yn := 'N';
end if;

for bt in curBatchTasks(l_orderid, l_shipid)
loop
  delete from batchtasks
        where rowid = bt.rowid;
  update subtasks
     set qty = qty - bt.qty,
         pickqty = pickqty - bt.pickqty,
         weight = weight - bt.weight
   where taskid = bt.taskid
     and custid = bt.custid
     and nvl(orderitem,'(none)') = nvl(bt.orderitem,'(none)')
     and nvl(orderlot,'(none)') = nvl(bt.orderlot,'(none)')
     and item = bt.item
     and nvl(lpid,'(none)') = nvl(bt.lpid,'(none)');
  select count(1)
    into l_batchtask_cnt
    from batchtasks
   where taskid = bt.taskid
     and custid = bt.custid
     and nvl(orderitem,'(none)') = nvl(bt.orderitem,'(none)')
     and nvl(orderlot,'(none)') = nvl(bt.orderlot,'(none)')
     and item = bt.item
     and nvl(lpid,'(none)') = nvl(bt.lpid,'(none)');
  if l_batchtask_cnt = 0 then
    delete from subtasks
     where taskid = bt.taskid
       and custid = bt.custid
       and nvl(orderitem,'(none)') = nvl(bt.orderitem,'(none)')
       and nvl(orderlot,'(none)') = nvl(bt.orderlot,'(none)')
       and item = bt.item
       and nvl(lpid,'(none)') = nvl(bt.lpid,'(none)');
  end if;
  update tasks
     set qty = qty - bt.qty,
         pickqty = pickqty - bt.pickqty,
         weight = weight - bt.weight
   where taskid = bt.taskid;
  select count(1)
    into l_subtask_cnt
    from subtasks
   where taskid = bt.taskid;
  if l_subtask_cnt = 0 then
    delete from tasks
          where taskid = bt.taskid;
  end if;  
  update plate
     set qtytasked = nvl(qtytasked,0) - bt.qty,
         lasttask = 'BD',
         lastuser = in_userid,
         lastupdate = sysdate
   where lpid = bt.lpid
   returning inventoryclass, invstatus, lotnumber, qtytasked
        into l_inventoryclass, l_invstatus, l_lotnumber, l_qtytasked;
  if l_qtytasked <= 0 then
    update plate
       set qtytasked = null,
           lasttask = 'BD',
           lastuser = in_userid,
           lastupdate = sysdate
     where lpid = bt.lpid;
  end if;
  if delete_commitments_yn = 'Y' then
    update commitments
       set qty = qty - bt.qty
     where orderid = bt.orderid
       and shipid = bt.shipid
       and orderitem = bt.orderitem
       and nvl(orderlot,'(none)') = nvl(bt.orderlot,'(none)')
       and item = bt.item
       and nvl(lotnumber,'(none)') = nvl(l_lotnumber,'(none)')
       and inventoryclass = l_inventoryclass
       and invstatus = l_invstatus
     returning qty into l_commit_qty;
    if l_commit_qty <= 0 then
      delete from commitments
       where orderid = bt.orderid
         and shipid = bt.shipid
         and orderitem = bt.orderitem
         and nvl(orderlot,'(none)') = nvl(bt.orderlot,'(none)')
         and item = bt.item
         and nvl(lotnumber,'(none)') = nvl(l_lotnumber,'(none)')
         and inventoryclass = l_inventoryclass
         and invstatus = l_invstatus;
    end if;
  end if;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tkdbo ' || substr(sqlerrm,1,80);
end delete_batchtasks_by_orderitem;

end batchpicks;
/
show error package body batchpicks;
exit;

