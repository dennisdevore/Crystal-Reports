create or replace package body alps.gensorts as
--
-- $Id$
--
/*
used to split a base qty into largest
whole unit-of-measure
*/
procedure compute_largest_whole_pickuom
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
,in_baseuom varchar2
,in_baseqty number
,out_pickuom IN OUT varchar2
,out_pickqty IN OUT number
,out_picktotype IN OUT varchar2
,out_cartontype IN OUT varchar2
,out_baseqty IN OUT number
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curCustItemUom is
  select *
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom <> 'K'
     and touom <> 'K'
     and nvl(qty,0) != 0
   order by sequence desc;

begin

out_errorno := 0;
out_msg := 'NotFound';

for uom in curCustItemUom
loop
  zbut.translate_uom(in_custid,in_item,in_baseqty,
    in_baseuom,uom.touom,out_pickqty,out_msg);
  if (substr(out_msg,1,4) = 'OKAY') then
    out_pickqty := floor(out_pickqty);
    if nvl(out_pickqty,0) = 0 then
      goto continue_loop;
    end if;
    zbut.translate_uom(in_custid,in_item,out_pickqty,
        uom.touom,in_baseuom,out_baseqty,out_msg);
    if (substr(out_msg,1,4) = 'OKAY') then
      out_pickuom := uom.touom;
      out_picktotype := zci.picktotype(in_custid,in_item,out_pickuom);
      out_cartontype := zci.cartontype(in_custid,in_item,out_pickuom);
      out_msg := 'FOUND';
    end if;
    exit;
  end if;
<<continue_loop>>
  null;
end loop;

if out_msg != 'FOUND' then
  out_pickuom := in_baseuom;
  out_pickqty := in_baseqty;
  out_picktotype := zci.picktotype(in_custid,in_item,in_baseuom);
  out_cartontype := zci.cartontype(in_custid,in_item,in_baseuom);
  out_baseqty := in_baseqty;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zgscp ' || sqlerrm;
  out_errorno := sqlcode;
end compute_largest_whole_pickuom;

/* used to generate sortation tasks upon completion of batch
   picking or upon user request */
procedure create_sortation_tasks
(in_facility varchar2
,in_orderid number
,in_shipid number
,in_taskpriority varchar2
,in_userid varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curShipPlates is
  select sp.*
    from shippingplateview sp
   where sp.taskid = 0
     and sp.orderid = in_orderid
     and sp.shipid = in_shipid
     and sp.type in ('F','P')
     and sp.status = 'U'
     and sp.location is null
     and exists(
     select 1
       from plate pl, location lo
      where pl.lpid = sp.fromlpid
        and lo.facility = pl.facility
        and lo.locid = pl.location)
   order by sp.orderitem,sp.orderlot,sp.item,sp.lotnumber;

cursor curOrderHdr is
  select orderid,
         shipid,
         custid,
         wave,
         stageloc,
         loadno,
         stopno,
         shipno,
         nvl(original_wave_before_combine,0) original_wave_before_combine,
         qtyorder
    from orderhdrview
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl(in_item varchar2, in_lotnumber varchar2) is
  select qtytype
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
od curOrderDtl%rowtype;

cursor curWaves(in_wave IN number) is
  select nvl(combined_wave,'N') combined_wave,
         nvl(consolidated,'N') consolidated
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cursor curPlate(in_lpid varchar2) is
  select *
    from plate
   where lpid = in_lpid;
lp plate%rowtype;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select locid,
		 section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;

cursor curItem (p_custid varchar2, p_item varchar2) is
  select labeluom
    from custitemview
   where custid = p_custid
     and item = p_item;
ci curItem%rowtype;

cursor curShipPlateQuantity is
  select sum(quantity) quantity
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and type in ('F','P');
spq curShipPlateQuantity%rowtype;

cursor curBatchTaskQuantity is
  select sum(qty) qty
    from batchtasks
   where orderid = in_orderid
     and shipid = in_shipid;
btq curBatchTaskQuantity%rowtype;

type orderdtltype is record (
  orderitem    orderdtl.item%type,
  orderlot    orderdtl.lotnumber%type
);

type orderdtltbltype is table of orderdtltype
     index by binary_integer;

orderdtl_tbl orderdtltbltype;

cntSubTasks integer;
sb subtasks%rowtype;
qtyRemain subtasks.qty%type;
st_qty subtasks.qty%type;
shippinglpid shippingplate.lpid%type;
errmsg appmsgs.msgtext%type;
ix integer;
neworderlot boolean;
l_wave waves.wave%type;
l_combined_wave waves.combined_wave%type;
strMsg varchar2(255);

begin

orderdtl_tbl.delete;

cntSubTasks := 0;

out_errorno := 0;
out_msg := '';

open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;

l_wave := oh.wave;
open curWaves(l_wave);
fetch curWaves into wv;
close curWaves;

l_combined_wave := wv.combined_wave;
if (l_combined_wave = 'Y') and (oh.original_wave_before_combine <> 0) then
  l_wave := oh.original_wave_before_combine;

  wv := null;
  open curWaves(l_wave);
  fetch curWaves into wv;
  close curWaves;
end if;

for sp in curShipPlates
loop
  if (wv.consolidated <> 'Y') or (oh.original_wave_before_combine = 0) then
  -- MP's don't have a unitofmeasure
     sp.unitofmeasure := nvl(sp.unitofmeasure, zci.baseuom(sp.custid, sp.item));
  -- split the quantity on the shippingplate record in whole
  -- units-of-measure, creating subtasks until the quantity is exhausted
    qtyRemain := sp.quantity;
  --zut.prt('shippingplateqty: ' || sp.quantity);
    while (qtyRemain > 0)
    loop
      open curPlate(sp.fromlpid);
      fetch curPlate into lp;
      close curPlate;
      if lp.status not in ('A','P') then
        qtyRemain := 0;
        goto continue_loop;
      end if;
      zgs.compute_largest_whole_pickuom(in_facility,sp.custid,sp.item,
          sp.unitofmeasure, qtyRemain,
          sb.pickuom, sb.pickqty, sb.picktotype, sb.cartontype, sb.qty,
          out_errorno, out_msg);
      ci := null;
      if sb.picktotype in ('PAL','FULL') then
        if zwv.single_shipping_units_only(in_orderid,in_shipid) = 'Y' then
          sb.picktotype := 'LBL';
          open curItem(oh.custid, sp.item);
          fetch curItem into ci;
          close curItem;
        end if;
      end if;
  --  zut.prt(sb.pickuom || ' ' ||sb.pickqty || ' ' || sb.picktotype || ' '
  --      || sb.cartontype || ' ' || sb.qty);
      qtyRemain := qtyRemain - sb.qty;
      open curLocation(in_facility,lp.location);
      fetch curLocation into fromloc;
      close curLocation;
      open curLocation(in_facility,oh.stageloc);
      fetch curLocation into toloc;
      close curLocation;
      sb.cartonseq := null;
      sb.tasktype := 'SO';
      sb.taskid := 0;
      sb.facility := null;
      if sb.qty = lp.quantity then
        sb.shippingtype := 'F';
      else
        sb.shippingtype := 'P';
      end if;
      if qtyRemain = 0 then
  --    zut.prt('update plate ' || sb.pickuom || ' ' || sb.pickqty || ' '
  --       || sb.qty);
        update shippingplate
           set quantity = sb.qty,
               pickuom = sb.pickuom,
               pickqty = sb.pickqty,
               type = sb.shippingtype,
               location = lp.location
         where rowid = sp.shippingplaterowid;
         shippinglpid := sp.lpid;
      else
  --    zut.prt('update plate ' || sb.pickuom || ' ' || sb.pickqty || ' '
  --       || sb.qty);
        zsp.get_next_shippinglpid(shippinglpid,out_msg);
        insert into shippingplate
          (lpid, item, custid, facility, location, status, holdreason,
          unitofmeasure, quantity, type, fromlpid, serialnumber,
          lotnumber, parentlpid, useritem1, useritem2, useritem3,
          lastuser, lastupdate, invstatus, qtyentered, orderitem,
          uomentered, inventoryclass, loadno, stopno, shipno,
          orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
          pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
          values
          (shippinglpid, sp.item, sp.custid, sp.facility, lp.location,
           'P', sp.holdreason, sp.unitofmeasure, sb.qty,
           sb.shippingtype, sp.fromlpid, sp.serialnumber, sp.lotnumber, null,
           sp.useritem1, sp.useritem2, sp.useritem3,
           sp.lastuser, sysdate, sp.invstatus, sp.QtyEntered,
           sp.orderitem, sp.uomentered, sp.inventoryclass,
           sp.loadno, sp.stopno, sp.shipno, sp.orderid,
           sp.shipid, zcwt.lp_item_weight(sp.fromlpid,sp.custid,sp.item,sb.pickuom) * sb.pickqty,
           null, null, 0, sp.orderlot,
           sb.pickuom, sb.pickqty, null, sp.manufacturedate, sp.expirationdate);
      end if;
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
        (sb.taskid,sb.tasktype,null,
         fromloc.section,lp.location,fromloc.equipprof,toloc.section,
         oh.stageloc,toloc.equipprof,null,oh.custid,sp.item,
         nvl(lp.parentlpid,lp.lpid),
         sp.unitofmeasure,sb.qty,fromloc.pickingseq,oh.loadno,
         oh.stopno,oh.shipno,in_orderid,in_shipid,sp.orderitem,
         sp.orderlot,decode(in_taskpriority,'(none)','3',in_taskpriority),
         decode(in_taskpriority,'(none)','3',in_taskpriority),
         null,in_userid,
         sysdate,sb.pickuom,sb.pickqty,sb.picktotype,l_wave,
         fromloc.pickingzone,sb.cartontype,
         zcwt.lp_item_weight(lp.lpid,oh.custid,sp.item,sb.pickuom) * sb.pickqty,
         zci.item_cube(oh.custid,sp.item,sb.pickuom) * sb.pickqty,
         zlb.staff_hours(in_facility,oh.custid,sp.item,sb.tasktype,
         fromloc.pickingzone,sb.pickuom,sb.pickqty),sb.cartonseq,
         shippinglpid, sb.shippingtype, zwv.cartontype_group(sb.cartontype), ci.labeluom);
      cntSubTasks := cntSubTasks + 1;
      neworderlot := True;
      if orderdtl_tbl.count != 0 then
        for ix in 1..orderdtl_tbl.count loop
          if (orderdtl_tbl(ix).orderitem = sp.orderitem) and
             (nvl(orderdtl_tbl(ix).orderlot,'(none)') = nvl(sp.orderlot,'(none)'))  then
            neworderlot := False;
            exit;
          end if;
        end loop;
      end if;
      if (neworderlot) then
        ix := orderdtl_tbl.count + 1;
        orderdtl_tbl(ix).orderitem := sp.orderitem;
        orderdtl_tbl(ix).orderlot := sp.orderlot;
      end if;
    <<continue_loop>>
      null;
    end loop;
  else
    open curPlate(sp.fromlpid);
    fetch curPlate into lp;
    close curPlate;
    open curLocation(in_facility,lp.location);
    fetch curLocation into fromloc;
    close curLocation;
    open curLocation(in_facility,oh.stageloc);
    fetch curLocation into toloc;
    close curLocation;
    open curOrderDtl(sp.orderitem, sp.orderlot);
    fetch curOrderDtl into od;
    close curOrderDtl;

    select count(1)
      into cntSubTasks
      from subtasks
     where wave = l_wave
       and tasktype = 'SO'
       and nvl(lpid,'(none)') = nvl(sp.fromlpid,'(none)')
       and orderid = l_wave
       and shipid = 0
       and priority <> 0
       and taskid <> 0;
       
    if sb.qty = lp.quantity then
      sb.shippingtype := 'F';
    else
      sb.shippingtype := 'P';
    end if;
       
    if (cntSubTasks = 0) then
      zgs.compute_largest_whole_pickuom(in_facility,sp.custid,sp.item,
          sp.unitofmeasure, sp.quantity,
          sb.pickuom, sb.pickqty, sb.picktotype, sb.cartontype, sb.qty,
          out_errorno, out_msg);

      if (sb.qty < sp.quantity) then
        sb.qty := sp.quantity;
        sb.pickqty := sp.quantity;
        sb.pickuom := sp.unitofmeasure;
        sb.picktotype := zci.picktotype(sp.custid,sp.item,sp.unitofmeasure);
        sb.cartontype := zci.cartontype(sp.custid,sp.item,sp.unitofmeasure);
      end if;

      sb.taskid := 0;
      sb.cartonseq := null;
      sb.tasktype := 'SO';

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
        (sb.taskid,sb.tasktype,null,
         fromloc.section,lp.location,fromloc.equipprof,toloc.section,
         oh.stageloc,toloc.equipprof,null,oh.custid,sp.item,
         nvl(lp.parentlpid,lp.lpid),
         sp.unitofmeasure,sb.qty,fromloc.pickingseq,oh.loadno,
         oh.stopno,oh.shipno,l_wave,0,sp.orderitem,
         sp.orderlot,decode(in_taskpriority,'(none)','3',in_taskpriority),
         decode(in_taskpriority,'(none)','3',in_taskpriority),
         null,in_userid,
         sysdate,sb.pickuom,sb.pickqty,sb.picktotype,l_wave,
         fromloc.pickingzone,sb.cartontype,
         zcwt.lp_item_weight(lp.lpid,oh.custid,sp.item,sb.pickuom) * sb.pickqty,
         zci.item_cube(oh.custid,sp.item,sb.pickuom) * sb.pickqty,
         zlb.staff_hours(in_facility,oh.custid,sp.item,sb.tasktype,
         fromloc.pickingzone,sb.pickuom,sb.pickqty),sb.cartonseq,
         shippinglpid, sb.shippingtype, zwv.cartontype_group(sb.cartontype), null);
         
      cntSubTasks := 1;
    else
      select taskid, qty
        into sb.taskid, st_qty
        from subtasks
       where wave = l_wave
         and tasktype = 'SO'
         and nvl(lpid,'(none)') = nvl(sp.fromlpid,'(none)')
         and orderid = l_wave
         and shipid = 0
         and priority <> 0
         and taskid <> 0
         and rownum = 1;

      zgs.compute_largest_whole_pickuom(in_facility,sp.custid,sp.item,
          sp.unitofmeasure, st_qty + sp.quantity,
          sb.pickuom, sb.pickqty, sb.picktotype, sb.cartontype, sb.qty,
          out_errorno, out_msg);
          
      if (sb.qty < (st_qty + sp.quantity)) then
        sb.qty := st_qty + sp.quantity;
        sb.pickqty := st_qty + sp.quantity;
        sb.pickuom := sp.unitofmeasure;
        sb.picktotype := zci.picktotype(sp.custid,sp.item,sp.unitofmeasure);
        sb.cartontype := zci.cartontype(sp.custid,sp.item,sp.unitofmeasure);
      end if;

      update subtasks
         set qty = sb.qty,
             pickuom = sb.pickuom,
             pickqty = sb.pickqty,
             weight = sb.pickqty * zcwt.lp_item_weight(lp.lpid,oh.custid,sp.item,sb.pickuom),
             cube = sb.pickqty * zci.item_cube(oh.custid,sp.item,sb.pickuom),
             staffhrs = zlb.staff_hours(in_facility,oh.custid,sp.item,sb.tasktype,
               fromloc.pickingzone,sb.pickuom,sb.pickqty),
             picktotype = sb.picktotype,
             cartontype = sb.cartontype,
             shippingtype = sb.shippingtype
       where taskid = sb.taskid
         and wave = l_wave
         and nvl(lpid,'(none)') = nvl(sp.fromlpid,'(none)')
         and orderid = l_wave
         and shipid = 0
         and priority <> 0;
          
      update tasks
         set qty =
               (select sum(qty)
                  from subtasks
                 where taskid = sb.taskid),
             pickqty =
               (select sum(pickqty)
                  from subtasks
                 where taskid = sb.taskid),
             weight =
               (select sum(weight)
                  from subtasks
                 where taskid = sb.taskid),
             cube =
               (select sum(cube)
                  from subtasks
                 where taskid = sb.taskid),
             staffhrs =
               (select sum(staffhrs)
                  from subtasks
                 where taskid = sb.taskid)
       where taskid = sb.taskid
         and wave = l_wave;
    end if;

    zgs.compute_largest_whole_pickuom(in_facility,sp.custid,sp.item,
        sp.unitofmeasure, sp.quantity,
        sb.pickuom, sb.pickqty, sb.picktotype, sb.cartontype, sb.qty,
        out_errorno, out_msg);
      
    if (sb.qty < sp.quantity) then
      sb.qty := sp.quantity;
      sb.pickqty := sp.quantity;
      sb.pickuom := sp.unitofmeasure;
      sb.picktotype := zci.picktotype(sp.custid,sp.item,sp.unitofmeasure);
      sb.cartontype := zci.cartontype(sp.custid,sp.item,sp.unitofmeasure);
    end if;

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
      (sb.taskid,'BP',null,
       fromloc.section,lp.location,fromloc.equipprof,toloc.section,
       oh.stageloc,toloc.equipprof,null,oh.custid,sp.item,
       nvl(lp.parentlpid,lp.lpid),
       sp.unitofmeasure,sb.qty,fromloc.pickingseq,oh.loadno,
       oh.stopno,oh.shipno,in_orderid,in_shipid,sp.orderitem,
       sp.orderlot,decode(in_taskpriority,'(none)','3',in_taskpriority),
       decode(in_taskpriority,'(none)','3',in_taskpriority),
       null,in_userid,
       sysdate,sb.pickuom,sb.pickqty,sb.picktotype,l_wave,
       fromloc.pickingzone,sb.cartontype,
       zcwt.lp_item_weight(lp.lpid,oh.custid,sp.item,sb.pickuom) * sb.pickqty,
       zci.item_cube(oh.custid,sp.item,sb.pickuom) * sb.pickqty,
       zlb.staff_hours(in_facility,oh.custid,sp.item,sb.tasktype,
       fromloc.pickingzone,sb.pickuom,sb.pickqty),sb.cartonseq,
       shippinglpid, sb.shippingtype, lp.invstatus, lp.inventoryclass,
       od.qtytype, lp.lotnumber);

    delete
      from shippingplate
     where lpid = sp.lpid;

    oh.orderid := l_wave;
    oh.shipid := 0;
  end if;
end loop;

if cntSubTasks = 0 then
  out_errorno := -1;
  out_msg := 'No sortation picks are pending for ' || in_orderid ||
    '-' || in_shipid;
  return;
end if;

if in_taskpriority = '(none)' then
  sb.priority := '3';
else
  sb.priority := in_taskpriority;
end if;

zwv.complete_pick_tasks(l_wave,in_facility,oh.orderid,oh.shipid,
  sb.priority,sb.priority,null,in_userid,null,null,'N','N',out_errorno,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  zms.log_msg('CreateSorts', in_facility, oh.custid,
      out_msg, 'E', in_userid, errmsg);
  return;
end if;

if (wv.consolidated = 'Y') and (oh.original_wave_before_combine <> 0) then
  select count(1)
    into cntSubTasks
    from batchtasks
   where wave = l_wave
     and orderid = in_orderid
     and shipid = in_shipid
     and taskid = 0;
  
  if cntSubTasks > 0 then
    update batchtasks bt
       set taskid = (
      select min(taskid)
        from subtasks st
       where st.wave = l_wave
         and st.taskid <> 0
         and st.tasktype = 'SO'
         and nvl(st.lpid,'(none)') = nvl(bt.lpid,'(none)')
         and st.orderid = l_wave
         and st.shipid = 0
         and qty > nvl((
           select sum(qty)
             from batchtasks
            where taskid = st.taskid
              and wave = l_wave),0))
     where wave = l_wave
       and orderid = in_orderid
       and shipid = in_shipid
       and taskid = 0;
  end if;
end if;

for ix in 1..orderdtl_tbl.count loop
  zlb.compute_line_labor(in_orderid,in_shipid,orderdtl_tbl(ix).orderitem,
    orderdtl_tbl(ix).orderlot,in_userid,'BAT',in_facility,'Y',
    out_errorno, out_msg);
  if out_errorno != 0 then
    zms.log_msg('LABORCALC', in_facility, oh.custid,
      out_msg, 'E', in_userid, strMsg);
  end if;
end loop;
orderdtl_tbl.delete;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zgscst ' || sqlerrm;
  out_errorno := sqlcode;
end create_sortation_tasks;

end gensorts;
/
show errors package body gensorts;
exit;
