create or replace package body alps.genlinepicks as
--
-- $Id$
--

function total_picks_for_order
(in_orderid in number
,in_shipid in number
) return integer
is

l_total_picks orderhdr.qtypick%type;
l_orderhdr_picks orderhdr.qtypick%type;
l_task_picks orderhdr.qtypick%type;
l_subtask_picks orderhdr.qtypick%type;
l_batchtask_picks orderhdr.qtypick%type;
l_orderstatus orderhdr.orderstatus%type;

begin

l_total_picks := 0;
l_orderhdr_picks := 0;
l_task_picks := 0;
l_subtask_picks := 0;
l_batchtask_picks := 0;

begin
  select nvl(qtypick,0), orderstatus
    into l_orderhdr_picks, l_orderstatus
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
exception when others then
  l_orderhdr_picks := 0;
  l_orderstatus := '9';
end;

if l_orderstatus < '9' then

  begin
    select nvl(sum(nvl(qty,0)),0)
      into l_task_picks
      from tasks
     where orderid = in_orderid
       and shipid = in_shipid
       and tasktype in ('PK');
  exception when others then
    l_task_picks := 0;
  end;

  begin
    select nvl(sum(nvl(qty,0)),0)
      into l_subtask_picks
      from subtasks
     where orderid = in_orderid
       and shipid = in_shipid
       and tasktype in ('SO','OP');
  exception when others then
    l_subtask_picks := 0;
  end;

  begin
    select nvl(sum(nvl(qty,0)),0)
      into l_batchtask_picks
      from batchtasks
     where orderid = in_orderid
       and shipid = in_shipid;
  exception when others then
    l_batchtask_picks := 0;
  end;

end if;

l_total_picks := l_orderhdr_picks
               + l_task_picks
               + l_subtask_picks
               + l_batchtask_picks;

return l_total_picks;

exception when others then
  return -1;
end total_picks_for_order;

function total_picks_for_wave
(in_wave in number
) return integer
is
l_total_picks_for_order orderhdr.qtypick%type;
l_total_picks_for_wave orderhdr.qtypick%type;

begin

l_total_picks_for_wave := 0;
for oh in (select orderid,shipid
             from orderhdr
            where wave = in_wave)
loop
  l_total_picks_for_wave := l_total_picks_for_wave
                          + total_picks_for_order(oh.orderid,oh.shipid);
end loop;

return l_total_picks_for_wave;

exception when others then
  return -1;
end total_picks_for_wave;

procedure gen_line_item_pick
(in_facility          in varchar2
,in_orderid           in number
,in_shipid            in number
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,in_qty               in number
,in_taskpriority      in varchar2
,in_picktype          in varchar2
,in_regen             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is

l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_orderlot orderdtl.lotnumber%type;

cursor curOrderHdr is
  select nvl(OH.loadno,0) as loadno,
         nvl(OH.stopno,0) as stopno,
         OH.orderstatus,
         OH.ordertype,
         OH.wave,
         OH.custid,
         OH.stageloc,
         OH.carrier,
         nvl(CU.paperbased, 'N') as paperbased,
         OH.qtyship,
         OH.qtypick
    from orderhdrview OH, customer CU
   where OH.orderid = l_orderid
     and OH.shipid = l_shipid
     and CU.custid = OH.custid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select priority,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(qtypick,0) as qtypick,
         uom,
         item,
         lotnumber,
         linestatus,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtyentered,
         uomentered,
         qtytype,
         nvl(qtyorderdiff,0) as qtyorderdiff,
         rowid
    from orderdtl
   where orderid = l_orderid
     and shipid = l_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(l_orderlot,'(none)');
od curOrderDtl%rowtype;

cursor curWaves(in_wave in number) is
  select nvl(picktype,'ORDR') as picktype,
         nvl(taskpriority,'9') as taskpriority
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cursor curSubTasks is
  select rowid,
         taskid,
         custid,
         facility,
         lpid,
         qty,
         tasktype
    from subtasks
   where orderid = l_orderid
     and shipid = l_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(l_orderlot,'(none)')
     and exists
       (select * from tasks
         where subtasks.taskid = tasks.taskid
           and tasks.priority = '9');

CURSOR C_WAVE_ORDER(in_wave number, in_item varchar2, in_lot varchar2)
IS
SELECT O.orderid, O.shipid
  FROM orderhdr O, orderdtl D
 WHERE O.wave = in_wave
   AND O.orderid = D.orderid
   AND O.shipid = D.shipid
   AND D.item = in_item
   AND nvl(D.lotnumber,'(none)') = nvl(in_lot,'(none)');


CURSOR C_SD(in_id varchar2)
IS
SELECT defaultvalue
  FROM systemdefaults
 WHERE defaultid = in_id;

csd C_SD%rowtype;

parms waves%rowtype;
strMsg varchar2(255);
reqtype varchar2(10);

cons_wave waves.wave%type;

l_cnt pls_integer;
l_status orderhdr.orderstatus%type;


begin

out_errorno := 0;
out_msg := '';

l_orderlot := in_orderlot;

if in_shipid = 0 then
    l_orderid := null;
    l_shipid := null;
    OPEN C_WAVE_ORDER(in_orderid, in_orderitem, l_orderlot);
    FETCH C_WAVE_ORDER into l_orderid, l_shipid;
    CLOSE C_WAVE_ORDER;
    if l_orderid is null then
      out_msg := 'Wave Order Header Not Found: ' || in_orderid || '-' || in_shipid;
      out_errorno := -1;
      return;
    end if;

else
    l_orderid := in_orderid;
    l_shipid := in_shipid;
end if;

cons_wave := zcord.cons_orderid(l_orderid, l_shipid);

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderHdr;
  out_msg := 'Order Header Not Found: ' || l_orderid || '-' || l_shipid;
  out_errorno := -1;
  return;
end if;
close curOrderhdr;

if (oh.orderstatus < '4') or
   (oh.orderstatus > '8') then
  out_msg := 'Invalid Order Status: ' || l_orderid || '-' || l_shipid ||
     ' Status: ' || oh.orderstatus;
  out_errorno := -2;
  return;
end if;

if oh.ordertype in ('R','Q','P','A','C','I') then
  out_msg := 'Invalid Order Type: ' || l_orderid || '-' || l_shipid ||
     ' Type: ' || oh.ordertype;
  out_errorno := -3;
  return;
end if;

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;
if od.rowid is null then
  if rtrim(in_orderlot) is not null then
    l_orderlot := null;
    open curOrderDtl;
    fetch curOrderDtl into od;
    close curOrderDtl;
  end if;
  if od.rowid is null then
    out_msg := 'Order Detail Not Found: ' || l_orderid || '-' || l_shipid
     || ' ' || in_orderitem || ' ' || l_orderlot;
    out_errorno := -4;
    return;
  end if;
end if;

if od.linestatus = 'X' then
  out_msg := 'Line is cancelled: ' || l_orderid || '-' || l_shipid
   || ' ' || in_orderitem || ' ' || l_orderlot || ' Status: ' || od.linestatus;
  out_errorno := -5;
  return;
end if;


if cons_wave > 0 then
    l_orderid := cons_wave;
    l_shipid := 0;
end if;

for st in curSubTasks
loop
  if ((nvl(in_regen,'N') <> 'Y')  or (st.tasktype <> 'SO')) then
    ztk.subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
      in_userid, 'Y', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_autonomous_msg('DeleteTask', st.facility, st.custid,
         out_msg, 'E', in_userid, strMsg);
      out_errorno := -6;
    else
      update tasks
         set qty=qty-st.qty,
             lastuser=in_userid,
             lastupdate=sysdate
       where taskid=st.taskid;
    end if;
  end if;
end loop;

delete from batchtasks
 where wave = oh.wave
   and orderid = l_orderid
   and shipid = l_shipid
   and facility is null;

delete from subtasks
 where wave = oh.wave
   and orderid = l_orderid
   and shipid = l_shipid
   and (facility is null
    or  taskid = 0);

delete from tasks
 where wave = oh.wave
   and orderid = l_orderid
   and shipid = l_shipid
   and facility is null;

delete from batchtasks
 where orderid = l_orderid
   and shipid = l_shipid
   and not exists
      (select 1
          from subtasks
         where subtasks.taskid = batchtasks.taskid
           and subtasks.item = batchtasks.item
           and nvl(subtasks.orderlot,'(none)') = nvl(batchtasks.orderlot,'(none)')
           and rownum = 1);

if (in_picktype = 'MatIssue') then
  reqtype := 'MatIssue';
  parms.picktype := 'LINE';
else
  reqtype := '2';
  open curWaves(oh.wave);
  fetch curWaves into wv;
  if curWaves%notfound then
    if in_picktype = '(none)' then
      wv.picktype := 'ORDR';		-- (none) will not fit in the column
    else
      wv.picktype := in_picktype;
    end if;
    wv.taskpriority := in_taskpriority;
  end if;
  close curWaves;

  if (in_picktype = '(none)') or
     (in_picktype = 'BAT') then

    open C_SD('REGENZONECONFIG');
    fetch C_SD into csd;
    close C_SD;

    if (wv.picktype = 'BAT') and ((nvl(csd.defaultvalue,'N') <> 'Y') or (nvl(in_regen,'N') <> 'Y')) then
      parms.picktype := 'ORDR';
    else
      parms.picktype := wv.picktype;
    end if;
  else
    parms.picktype := in_picktype;
  end if;
end if;

if in_taskpriority = '(none)' then
  if od.priority = '0' then
    parms.taskpriority := '2';
  else
    parms.taskpriority := '3';
  end if;
else
  parms.taskpriority := in_taskpriority;
end if;

if in_trace = 'Y' then
  zut.prt('cons_wave is ' || cons_wave);
end if;

if cons_wave = 0 then
  if in_trace= 'Y' then
    zut.prt('call zwv.release_line');
  end if;
  zwv.release_line(
    in_orderid,
    in_shipid,
    od.item,
    od.lotnumber,
    reqtype,
    in_facility,
    parms.taskpriority,
    parms.picktype,
    'Y',
    oh.stageloc,
    null,
    null,
    in_regen,
    in_userid,
    in_trace,
    1, -- initialize recursion counter to one
    out_msg);

  if oh.paperbased = 'Y' then
    update orderhdr
       set orderstatus = '5'
     where orderid = in_orderid
       and shipid = in_shipid
       and orderstatus > '5';

    for st in (select S.taskid, S.lpid, S.shippinglpid, S.qty
                 from subtasks S, tasks T
                 where S.orderid = in_orderid
                   and S.shipid = in_shipid
                   and T.taskid = S.taskid
                   and T.touserid is null) loop
      insert into agginvtasks
        (shippinglpid, lpid, qty)
      values
        (st.shippinglpid, st.lpid, st.qty);
      update shippingplate
         set type ='P'
         where lpid = st.shippinglpid;
      update subtasks
         set shippingtype = 'P'
         where taskid = st.taskid;
    end loop;

    update tasks
      set touserid = '(AggInven)'
      where touserid is null
        and orderid = in_orderid
        and shipid = in_shipid
        and tasktype in ('OP','PK');
  end if;

  if substr(out_msg,1,4) != 'OKAY' then
    out_errorno := 1;
  else
    out_errorno := 0;
  end if;
else
  if in_trace = 'Y' then
    zut.prt('release consolidated wave ' || cons_wave);
  end if;
  parms.picktype := 'BAT';

  for crec in (select OD.*
                 from orderdtl OD, orderhdr OH
                 where OH.wave = cons_wave
                   and OH.orderid = OD.orderid
                   and OH.shipid = OD.shipid
                   and OD.item = in_orderitem
                   and OH.orderstatus != 'X'
                   and OD.linestatus != 'X'
                   and nvl(OD.lotnumber,'(none)')
                        = nvl(l_orderlot,'(none)'))
  loop
    if in_trace = 'Y' then
      zut.prt('release consolidated order ' || crec.orderid || '-' || crec.shipid);
    end if;
    zwv.release_line(
      crec.orderid,
      crec.shipid,
      crec.item,
      crec.lotnumber,
      reqtype,
      in_facility,
      parms.taskpriority,
      parms.picktype,
      'N',
      oh.stageloc,
      null,
      null,
      'N',
      in_userid,
      in_trace,
      1, -- initialize recursion counter to one
      out_msg);

    if substr(out_msg,1,4) != 'OKAY' then
      out_errorno := 1;
    else
      out_errorno := 0;
    end if;
  end loop;

  zbp.generate_batch_tasks(cons_wave,in_facility,parms.taskpriority,
    parms.picktype,null,null,in_userid,
    in_trace,'Y',out_errorno,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('RegenPick', in_facility, null,
      out_msg, 'W', in_userid, strMsg);
  end if;

  zbp.update_consolidated_tasks(cons_wave,in_userid,in_trace,out_errorno,out_msg);
  if out_errorno <> 0 then
    zms.log_msg('RegenPick', in_facility, null,
      out_msg, 'W', in_userid, strMsg);
  end if;

end if;

if od.qtyorderdiff != 0 then
   update orderdtl
      set qtyorderdiff = 0
      where rowid = od.rowid;

   select count(1) into l_cnt
      from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid;

   if l_cnt = 0 then             -- no shippingplates, leave status alone
      l_status := oh.orderstatus;
   else
      select count(1) into l_cnt
         from shippingplate
         where orderid = in_orderid
        and shipid = in_shipid
        and status = 'U';

      if l_cnt != 0 then
         select count(1) into l_cnt
            from shippingplate
            where orderid = in_orderid
              and shipid = in_shipid
              and status != 'U';

         if l_cnt != 0 then
            l_status := '5';     -- picked and unpicked => picking
         else
            l_status := '4';     -- only unpicked => released
         end if;
      else
         select count(1) into l_cnt
            from shippingplate
            where orderid = in_orderid
              and shipid = in_shipid
              and status = 'L';

         if l_cnt = 0 then
            select count(1) into l_cnt
               from batchtasks
               where orderid = in_orderid
                 and shipid = in_shipid;
            if l_cnt != 0 then
               l_status := '4';  -- unpicked batch task => released
            else
               l_status := '6';  -- only picked => picked
            end if;
         elsif oh.qtyship = oh.qtypick then
            l_status := '8';     -- all loaded => loaded
         else
            l_status := '7';     -- not all loaded => loading
         end if;
      end if;
   end if;

   if l_status != oh.orderstatus then
      update orderhdr
         set orderstatus = l_status,
             lastuser = in_userid,
             lastupdate = sysdate
         where orderid = in_orderid
           and shipid = in_shipid;

      if nvl(oh.loadno, 0) != 0 then
         select min(orderstatus) into l_status
            from orderhdr
            where loadno = oh.loadno
              and stopno = oh.stopno;
         update loadstop
            set loadstopstatus = l_status,
                lastuser = in_userid,
                lastupdate = sysdate
            where loadno = oh.loadno
              and stopno = oh.stopno
              and loadstopstatus != l_status;

         select min(loadstopstatus) into l_status
            from loadstop
            where loadno = oh.loadno;
         update loads
            set loadstatus = l_status,
                lastuser = in_userid,
                lastupdate = sysdate
            where loadno = oh.loadno
              and loadstatus != l_status;
      end if;
   end if;
end if;

exception when OTHERS then
  out_msg := 'zblgl ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end gen_line_item_pick;

procedure validate_manual_pick
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is

cursor curOrder is
  select custid,orderid,shipid,orderstatus
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
OH curOrder%rowtype;
l_task_count pls_integer;

cursor curCustomer(in_custid varchar2) is
  select customer.custid as custid,
         nvl(allow_manual_pick_select_yn,'N') as allow_manual_pick_select_yn,
         nvl(paperbased,'N') as paperbased
    from customer, customer_aux
   where customer.custid = in_custid
     and customer.custid = customer_aux.custid(+);
CU curCustomer%rowtype;

begin

  out_msg := 'OKAY';
  out_errorno := 0;

  OH := null;
  open curOrder;
  fetch curOrder into OH;
  close curOrder;
  if OH.orderid is null then  -- no order, assume entry is underway
    return;
  end if;

  CU := null;
  open curCustomer(OH.custid);
  fetch curCustomer into CU;
  close curCustomer;
  if CU.custid is null then  -- no order, assume entry is underway
    out_errorno := -101;
    out_msg := 'Customer not found: ' || oh.custid;
    return;
  end if;

  if cu.allow_manual_pick_select_yn = 'N' or
     cu.paperbased = 'Y' then
    out_errorno := -1012;
    out_msg := 'Manual Pick Selection is not allowed for this customer: ' || OH.custid;
    return;
  end if;


  select count(1)
    into l_task_count
    from subtasks
   where orderid = in_orderid
     and shipid = in_shipid;
  if l_task_count <> 0 then
    out_errorno := -1;
    out_msg := 'Order has outstanding tasks';
  end if;

exception when OTHERS then
  out_msg := 'zglvmp ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end validate_manual_pick;

procedure validate_unset_manual_pick
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)
is

cursor curOrder is
  select orderid,shipid,orderstatus
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
OH curOrder%rowtype;
l_task_count pls_integer;

begin
  out_msg := 'OKAY';
  out_errorno := 0;

  OH := null;
  open curOrder;
  fetch curOrder into OH;
  close curOrder;
  if OH.orderid is null then  -- no order, assume entry is underway
    return;
  end if;

  select count(1)
    into l_task_count
    from tasks
   where orderid = in_orderid
     and shipid = in_shipid;
  if l_task_count <> 0 then
    out_errorno := -1;
    out_msg := 'Order has outstanding tasks';
  end if;

exception when OTHERS then
  out_msg := 'zglvump ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end validate_unset_manual_pick;

procedure gen_manual_pick
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,in_lpid              in varchar2
,in_topick_qty        in number
,out_errorno          in out number
,out_msg              in out varchar2)
is

cursor curOrderHdr is
  select orderid,shipid,fromfacility,custid,orderstatus,priority,
         loadno,stopno,shipno,stageloc,wave
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
OH curOrderHdr%rowtype;

cursor curWave(in_wave IN number) is
  select picktype
    from waves
   where wave = in_wave;
WV curWave%rowtype;

cursor curOrderDtl is
  select orderid,shipid,item,lotnumber,qtyorder,qtypick,qtyentered,
         uomentered,qtycommit,
         invstatus,invstatusind,inventoryclass,invclassind
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'x') = nvl(in_orderlot,'x');
OD curOrderDtl%rowtype;

cursor curTasks is
  select tk.taskid, tk.rowid
    from tasks tk
   where tk.orderid = in_orderid
     and tk.shipid = in_shipid
     and tk.tasktype = 'OP';
ct curTasks%rowtype;

cursor curLpid is
   select lpid,custid,item,nvl(quantity,0) as quantity,nvl(qtytasked,0) as qtytasked,
          facility,location,
          inventoryclass,invstatus,unitofmeasure,lotnumber,
          serialnumber,useritem1,useritem2,useritem3,
          holdreason,type,status
     from plate
    where lpid = in_lpid;
LP curLpid%rowtype;

cursor curSPLpid is
   select lpid
     from shippingplate
    where fromlpid = in_lpid
      and type = 'F'
      and status <> 'SH';

cursor curItemFacility(in_fromfacility varchar2, in_custid varchar2, in_item varchar2) is
  select custid, item, allocrule
    from custitemfacilityview
   where custid = in_custid
     and item = in_item
     and facility = in_fromfacility;
ITF curItemFacility%rowtype;

cursor curCustomer(in_custid varchar2) is
  select pick_by_line_number_yn,
         nvl(paperbased, 'N') as paperbased
    from customer
   where custid = in_custid;
CU curCustomer%rowtype;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from location
   where facility = in_facility
     and locid = in_locid;
FRLOC curLocation%rowtype;
TOLOC curLocation%rowtype;

SP shippingplate%rowtype;
TK tasks%rowtype;
ST subtasks%rowtype;
l_picktype zone.picktype%type;
l_msg varchar2(255);
l_msg2 varchar2(255);
l_subtask_qty pls_integer;
splpid varchar2(15);
l_sp_qty pls_integer;
AR allocrulesdtl%rowtype;
l_singleonly char(1);
l_pickqty number;
l_qtycommit orderdtl.qtycommit%type;
l_qtyremain orderdtl.qtycommit%type;
l_cmd varchar2(4000);
l_match_count pls_integer;

begin

  out_msg := 'OKAY';
  out_errorno := 0;

  OH := null;
  open curOrderHdr;
  fetch curOrderHdr into OH;
  close curOrderHdr;
  if OH.orderid is null then
    out_errorno := -1;
    out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
    return;
  end if;

  if OH.orderstatus > '8' then
    out_errorno := -101;
    out_msg := 'Invalid order status ' || in_orderid || '-' || in_shipid ||
               ': ' || OH.orderstatus;
    return;
  end if;

  OD := null;
  open curOrderDtl;
  fetch curOrderDtl into OD;
  close curOrderDtl;
  if OD.orderid is null then
    out_errorno := -2;
    out_msg := 'Order Item not found: ' || in_orderid || '-' || in_shipid || ' ' ||
               in_orderitem || '/' || in_orderlot;
    return;
  end if;

  CU := null;
  open curCustomer(OH.custid);
  fetch curCustomer into CU;
  close curCustomer;

  if CU.paperbased = 'Y' then
    out_errorno := -505;
    out_msg := 'Manual allocation is not allowed for Aggregate Inventory Customers';
    return;
  end if;

  l_subtask_qty := 0;
  begin
    select sum(qty)
      into l_subtask_qty
      from subtasks
     where orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_orderitem
       and nvl(orderlot,'x') = nvl(in_orderlot,'x');
  exception when others then
    l_subtask_qty := 0;
  end;

  l_qtyremain := nvl(OD.qtyorder,0) - nvl(OD.qtypick,0) - l_subtask_qty;
  if in_topick_qty > l_qtyremain then
    out_errorno := -202;
    out_msg := 'Too much selected: ' || in_orderid || '-' || in_shipid || ' ' ||
               in_orderitem || '/' || in_orderlot || CHR(13) || CHR(10) ||
               'Selected: ' || in_topick_qty || ' Remaining: ' || l_qtyremain;
    return;
  end if;

  LP := null;
  open curlpid;
  fetch curlpid into LP;
  close curlpid;
  if LP.lpid is null then
    out_errorno := -1;
    out_msg := 'LiP not found: ' || in_lpid;
    return;
  end if;

  if LP.quantity < LP.qtytasked + in_topick_qty then
    out_errorno := -3;
    out_msg := 'LiP quantity not allocable: ' || in_lpid;
    return;
  end if;

  if LP.type <> 'PA' then
    out_errorno := -4;
    out_msg := 'Invalid LiP Type: ' || LP.type;
    return;
  end if;

  if LP.status <> 'A' then
    out_errorno := -5;
    out_msg := 'Invalid LiP Status: ' || LP.status;
    return;
  end if;

  if LP.item <> in_orderitem then
    out_errorno := -6;
    out_msg := 'Invalid Item: ' || LP.item;
    return;
  end if;

  if rtrim(in_orderlot) is not null then
    if in_orderlot <> LP.lotnumber then
      out_errorno := -7;
      out_msg := 'Invalid Lot: ' || LP.lotnumber;
      return;
    end if;
  end if;

  splpid := null;
  open curSPLpid;
  fetch curSPLpid into splpid;
  close curSPLpid;
  if splpid is not null then
    out_errorno := -203;
    out_msg := 'LiP ' || in_lpid || ' already fully allocated on ' || splpid;
    return;
  end if;

  l_sp_qty := 0;
  begin
    select sum(quantity)
      into l_sp_qty
      from shippingplate
     where fromlpid=in_lpid
       and type in('F','P')
       and status <> 'SH';
  exception when others then
    l_sp_qty := 0;
  end;

  if LP.quantity < l_sp_qty + in_topick_qty then
    out_errorno := -3;
    out_msg := 'LiP quantity not allocable: ' || in_lpid;
    return;
  end if;

  if rtrim(OD.invstatus) is not null then
    l_cmd := 'select count(1) from dual where ''' || LP.invstatus ||
             ''' ' || zcm.in_str_clause(OD.invstatusind,OD.invstatus);
    execute immediate l_cmd into l_match_count;
    if l_match_count = 0 then
      out_errorno := -8;
      out_msg := 'Invalid inventory status: ' || LP.invstatus;
      return;
    end if;
  end if;

  if rtrim(OD.inventoryclass) is not null then
    l_cmd := 'select count(1) from dual where ''' || LP.inventoryclass ||
              ''' ' || zcm.in_str_clause(OD.invclassind,OD.inventoryclass);
    execute immediate l_cmd into l_match_count;
    if l_match_count = 0 then
      out_errorno := -9;
      out_msg := 'Invalid inventory class: ' || LP.inventoryclass;
      return;
    end if;
  end if;

  ITF := null;
  open curItemFacility(OH.fromfacility, OH.custid, in_orderitem);
  fetch curItemFacility into ITF;
  close curItemFacility;
  if ITF.item is null then
    out_errorno := -303;
    out_msg := 'No allocation rule is defined for facility/item: ' ||
               OH.fromfacility || '/' || in_orderitem;
    return;
  end if;

  AR := null;
  for ARD in
  (select priority,
          uom,
          nvl(qtymin,1) as qtymin,
          nvl(qtymax,9999999) as qtymax,
          nvl(wholeunitsonly,'N') as wholeunitsonly
     from allocrulesdtl
    where facility = OH.fromfacility
      and allocrule = ITF.allocrule
      and ( (invstatus is null) or
            (invstatus = LP.invstatus) )
      and ( (inventoryclass is null) or
             inventoryclass = nvl(LP.inventoryclass,'RG') )
   order by priority)
  loop
	  zbut.translate_uom(OH.custid,OD.item,ARD.qtyMin,ar.uom,LP.unitofmeasure,AR.qtyMin,l_msg);
	  if substr(l_msg,1,4) != 'OKAY' then
	    goto continue_ar_loop;
	  end if;
	  zbut.translate_uom(OH.custid,OD.item,ARD.qtyMax,ar.uom,LP.unitofmeasure,AR.qtyMax,l_msg);
	  if substr(out_msg,1,4) != 'OKAY' then
	    goto continue_ar_loop;
	  end if;
	  if (in_topick_qty >= AR.qtyMin) and
	     (in_topick_qty <= AR.qtyMax) then
	    AR.uom := ARD.uom;
	    AR.wholeunitsonly := ARD.wholeunitsonly;
	    exit;
	  end if;
	<< continue_ar_loop >>
	  AR := null;
  end loop;

  if AR.uom is null then
    AR.uom := LP.unitofmeasure;
    AR.wholeunitsonly := 'N';
  end if;

  WV := null;
  if nvl(OH.wave,0) = 0 then
	  zwv.get_next_wave(OH.wave,l_msg);
	  insert into waves
	   (wave, descr, wavestatus, facility, lastuser, lastupdate, taskpriority)
	   values
	   (OH.wave, 'Manual Allocation', '1', OH.fromfacility, in_userid, sysdate, '9');
	  update orderhdr
	     set wave = OH.wave
	   where orderid = in_orderid
	     and shipid = in_shipid;
	else
    open curWave(OH.wave);
    fetch curWave into WV;
    close curWave;
  end if;

  begin
	  insert into commitments
	    (facility, custid, item, inventoryclass,
	     invstatus, status, lotnumber, uom,
	     qty, orderid, shipid, orderitem, orderlot,
	     priority, lastuser, lastupdate)
	    values
	    (OH.fromfacility, OH.custid, in_orderitem, LP.inventoryclass,
	     LP.invstatus, 'CM', in_orderlot, LP.unitofmeasure,
	     in_topick_qty, in_orderid, in_shipid, in_orderitem, in_orderlot,
	     OH.priority, in_userid, sysdate);
  exception when dup_val_on_index then
    update commitments
       set qty = qty + in_topick_qty,
           priority = OH.priority,
           lastuser = in_userid,
           lastupdate = sysdate
     where facility = OH.fromfacility
       and custid = OH.custid
       and item = in_orderitem
       and inventoryclass = LP.inventoryclass
       and invstatus = LP.invstatus
       and status = 'CM'
       and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
       and orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_orderitem
       and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
  end;

  TK := null;
  ST := null;
  TK.pickuom := AR.uom;
  if cu.pick_by_line_number_yn = 'Y' then
    ST.labeluom := OD.uomentered;
    TK.picktotype := 'LBL';
  elsif AR.wholeunitsonly = 'Y' then
    ST.labeluom := TK.pickuom;
  end if;
  TK.picktotype := zci.picktotype(OH.custid,in_orderitem,AR.uom);
  if TK.picktotype in ('PAL','FULL') then
	  l_singleonly := zwv.single_shipping_units_only(in_orderid,in_shipid);
	  if l_singleonly = 'Y' then
	    TK.picktotype := 'LBL';
	  end if;
	end if;
	if TK.picktotype = 'LBL' then
	  if zwv.pick_to_label_okay(in_orderid,in_shipid) = 'N' then
	    TK.picktotype := 'PAL';
	  end if;
	end if;
  TK.cartontype := zci.cartontype(OH.custid,in_orderitem,AR.uom);

  if(WV.picktype = 'ORDR') then
    l_picktype := 'ORDR';
    TK.tasktype := 'OP';
  else
    l_picktype := 'LINE';
    TK.tasktype := 'PK';
  end if;

  ztsk.get_next_taskid(TK.taskid,l_msg);

  if in_topick_qty = LP.quantity then
    SP.type := 'F';
  else
    SP.type := 'P';
  end if;

  FRLOC := null;
  open curLocation(LP.facility,LP.location);
  fetch curLocation into FRLOC;
  close curLocation;
  TOLOC := null;
  open curLocation(LP.facility,OH.stageloc);
  fetch curLocation into TOLOC;
  close curLocation;

  if TK.pickuom = LP.unitofmeasure then
    TK.pickqty := in_topick_qty;
  else
    zbut.translate_uom(OH.custid,LP.item,in_topick_qty,
                       LP.unitofmeasure,TK.pickuom,l_pickqty,l_msg);
    if substr(l_msg,1,4) = 'OKAY' then
      if mod(l_pickqty,1) < .000001 then
        l_pickqty := floor(l_pickqty);
      end if;
      if l_pickqty != 0 then
        TK.pickqty := l_pickqty;
      else
        TK.pickqty := in_topick_qty;
        TK.pickuom := lp.unitofmeasure;
      end if;
    else
      TK.pickqty := in_topick_qty;
      TK.pickuom := LP.unitofmeasure;
    end if;

  end if;

  if (l_picktype = 'ORDR') then
    ct := null;
    open curTasks;
    fetch curTasks into ct;
    close curTasks;

    if (ct.taskid is null) then
      insert into tasks
          (taskid, tasktype, facility, fromsection, fromloc,
           fromprofile,tosection,toloc,toprofile,touserid,
           custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
           orderid,shipid,orderitem,orderlot,priority,
           prevpriority,curruserid,lastuser,lastupdate,
           pickuom, pickqty, picktotype, wave,
           pickingzone, cartontype, weight, cube, staffhrs)
      values
          (TK.taskid, TK.tasktype, OH.fromfacility, FRLOC.section,LP.location,
           FRLOC.equipprof,TOLOC.section,OH.stageloc,
           TOLOC.equipprof,null,OH.custid,LP.item,LP.lpid,
           LP.unitofmeasure,in_topick_qty,FRLOC.pickingseq,OH.loadno,OH.stopno,
           OH.shipno,in_orderid,in_shipid,in_orderitem,in_orderlot,
           '9','9',null,in_userid,sysdate,
           TK.pickuom,TK.pickqty,TK.picktotype,OH.wave,
           FRLOC.pickingzone,TK.cartontype,
           zcwt.lp_item_weight(LP.lpid,OH.custid,LP.item,TK.pickuom) * TK.pickqty,
           zci.item_cube(OH.custid,LP.item,TK.pickuom) * TK.pickqty,
           zlb.staff_hours(OH.fromfacility,OH.custid,LP.item,TK.tasktype,
           FRLOC.pickingzone,TK.pickuom,TK.pickqty));
    else
      TK.taskid := ct.taskid;

      update tasks
         set qty = qty + in_topick_qty,
             pickqty = pickqty + TK.pickqty,
             weight = weight + (zcwt.lp_item_weight(LP.lpid,OH.custid,LP.item,TK.pickuom) * TK.pickqty),
             cube = cube + (zci.item_cube(OH.custid,LP.item,TK.pickuom) * TK.pickqty)
       where rowid = ct.rowid;
    end if;
  else
    insert into tasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs)
      values
      (TK.taskid, TK.tasktype, OH.fromfacility, FRLOC.section,LP.location,
       FRLOC.equipprof,TOLOC.section,OH.stageloc,
       TOLOC.equipprof,null,OH.custid,LP.item,LP.lpid,
       LP.unitofmeasure,in_topick_qty,FRLOC.pickingseq,OH.loadno,OH.stopno,
       OH.shipno,in_orderid,in_shipid,in_orderitem,in_orderlot,
       '9','9',null,in_userid,sysdate,
       TK.pickuom,TK.pickqty,TK.picktotype,OH.wave,
       FRLOC.pickingzone,TK.cartontype,
       zcwt.lp_item_weight(LP.lpid,OH.custid,LP.item,TK.pickuom) * TK.pickqty,
       zci.item_cube(OH.custid,LP.item,TK.pickuom) * TK.pickqty,
       zlb.staff_hours(OH.fromfacility,OH.custid,LP.item,TK.tasktype,
       FRLOC.pickingzone,TK.pickuom,TK.pickqty));
  end if;

  zsp.get_next_shippinglpid(SP.lpid,l_msg);
  insert into shippingplate
    (lpid, item, custid, facility, location, status, holdreason,
    unitofmeasure, quantity, type, fromlpid, serialnumber,
    lotnumber, parentlpid, useritem1, useritem2, useritem3,
    lastuser, lastupdate, invstatus, qtyentered, orderitem,
    uomentered, inventoryclass, loadno, stopno, shipno,
    orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
    pickuom, pickqty, cartonseq)
    values
    (SP.lpid, LP.item, OH.custid, OH.fromfacility, LP.location,
     'U', LP.holdreason, LP.unitofmeasure, in_topick_qty,
     SP.type, LP.lpid, LP.serialnumber, LP.lotnumber, null,
     LP.useritem1, LP.useritem2, LP.useritem3,
     in_userid, sysdate, LP.invstatus, OD.qtyentered,
     in_orderitem, OD.uomentered, LP.inventoryclass,
     OH.loadno, OH.stopno, OH.shipno, in_orderid,
     in_shipid, zcwt.lp_item_weight(LP.lpid,OH.custid,LP.item,TK.pickuom) * in_topick_qty,
     null, null, TK.taskid, in_orderlot,
     TK.pickuom, TK.pickqty, TK.cartonseq);

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
    (TK.taskid,TK.tasktype,OH.fromfacility,
     FRLOC.section,lp.location,FRLOC.equipprof,TOLOC.section,
     OH.stageloc,TOLOC.equipprof,null,OH.custid,LP.item,LP.lpid,
     LP.unitofmeasure,in_topick_qty,FRLOC.pickingseq,OH.loadno,
     OH.stopno,OH.shipno,in_orderid,in_shipid,in_orderitem,
     in_orderlot,'9','9',null,in_userid,
     sysdate,TK.pickuom,TK.pickqty,TK.picktotype,OH.wave,
     FRLOC.pickingzone,TK.cartontype,
     zcwt.lp_item_weight(LP.lpid,OH.custid,LP.item,TK.pickuom) * TK.pickqty,
     zci.item_cube(OH.custid,LP.item,TK.pickuom) * TK.pickqty,
     zlb.staff_hours(OH.fromfacility,OH.custid,LP.item,TK.tasktype,
     FRLOC.pickingzone,TK.pickuom,TK.pickqty),TK.cartonseq,
     SP.lpid, SP.type,
     zwv.cartontype_group(TK.cartontype), ST.labeluom);

  update plate
     set qtytasked = nvl(qtytasked,0) + in_topick_qty,
         lastuser = in_userid,
         lastupdate = sysdate
   where lpid = LP.lpid;

exception when OTHERS then
  out_msg := 'zglgmp ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end gen_manual_pick;

procedure get_manual_pick_select_qty
(in_orderid           in number
,in_shipid            in number
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,out_select_qty       in out number)
is

l_cmd varchar2(1000);

begin

out_select_qty := 0;

l_cmd := 'select sum(qty) from subtasks where orderid = ' || in_orderid ||
         ' and shipid = ' || in_shipid;
if rtrim(in_orderitem) is not null then
  l_cmd := l_cmd || ' and orderitem = ''' || in_orderitem || '''' ||
           ' and nvl(orderlot,''(none)'') = nvl(' || in_orderlot ||
           ',''(none)'')';
end if;

execute immediate l_cmd into out_select_qty;

exception when others then
  out_select_qty := 0;
end;

procedure delete_manual_picks
(in_orderid           in number
,in_shipid            in number
,in_userid            in varchar2
,in_orderitem         in varchar2
,in_orderlot          in varchar2
,in_lpid              in varchar2
,in_delete_order_rows in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)

is

cursor curSubTasksLpid is
  select st.rowid,
         st.taskid,
         st.custid,
         st.facility,
         st.lpid,
         st.orderitem,
         st.orderlot,
         st.item,
         sp.invstatus,
         sp.inventoryclass,
         st.qty
    from subtasks st, shippingplate sp
   where st.orderid = in_orderid
     and st.shipid = in_shipid
     and st.orderitem = in_orderitem
     and nvl(st.orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and st.lpid = in_lpid
     and st.shippinglpid = sp.lpid (+)
     and not exists
       (select * from tasks tk
         where st.taskid = tk.taskid
           and tk.priority = '0');

cursor curSubTasksItem is
  select st.rowid,
         st.taskid,
         st.custid,
         st.facility,
         st.lpid,
         st.orderitem,
         st.orderlot,
         st.item,
         sp.invstatus,
         sp.inventoryclass,
         st.qty
    from subtasks st, shippingplate sp
   where st.orderid = in_orderid
     and st.shipid = in_shipid
     and st.orderitem = in_orderitem
     and nvl(st.orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and st.shippinglpid = sp.lpid (+)
     and not exists
       (select * from tasks tk
         where st.taskid = tk.taskid
           and tk.priority = '0');

cursor curSubTasksOrder is
  select st.rowid,
         st.taskid,
         st.custid,
         st.facility,
         st.lpid,
         st.orderitem,
         st.orderlot,
         st.item,
         sp.invstatus,
         sp.inventoryclass,
         st.qty
    from subtasks st, shippingplate sp
   where st.orderid = in_orderid
     and st.shipid = in_shipid
     and st.shippinglpid = sp.lpid (+)
     and not exists
       (select * from tasks tk
         where st.taskid = tk.taskid
           and tk.priority = '0');

l_msg varchar2(255);

procedure delete_commitments(in_orderitem varchar2, in_orderlot varchar2,
          in_item varchar2, in_invstatus varchar2, in_inventoryclass varchar2,
          in_qty number)
is

l_qty commitments.qty%type;

begin

  l_qty := 0;
  update commitments
     set qty = qty - in_qty
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and inventoryclass = in_inventoryclass
     and invstatus = in_invstatus
   returning qty into l_qty;
  if l_qty <= 0 then
    delete from commitments
     where orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_orderitem
       and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
       and item = in_item
       and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
       and inventoryclass = in_inventoryclass
       and invstatus = in_invstatus;
  end if;
end;

begin

out_errorno := 0;
out_msg := 'OKAY';

if rtrim(in_lpid) is not null then
  for st in curSubTasksLpid
  loop
    ztk.subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
      in_userid, 'N', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_autonomous_msg('ORDERENTRY', st.facility, st.custid,
         out_msg, 'E', in_userid, l_msg);
    end if;
    delete_commitments(st.orderitem, st.orderlot, st.item, st.invstatus,
      st.inventoryclass, st.qty);
  end loop;
elsif rtrim(in_orderitem) is not null then
  for st in curSubTasksItem
  loop
    ztk.subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
      in_userid, 'N', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_autonomous_msg('ORDERENTRY', st.facility, st.custid,
         out_msg, 'E', in_userid, l_msg);
    end if;
    delete_commitments(st.orderitem, st.orderlot, st.item, st.invstatus,
      st.inventoryclass, st.qty);
  end loop;
  if in_delete_order_rows = 'Y' then
    delete from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid
       and item = in_orderitem
       and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
  end if;
else
  for st in curSubTasksOrder
  loop
    ztk.subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
      in_userid, 'N', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_autonomous_msg('ORDERENTRY', st.facility, st.custid,
         out_msg, 'E', in_userid, l_msg);
    end if;
    delete_commitments(st.orderitem, st.orderlot, st.item, st.invstatus,
      st.inventoryclass, st.qty);
  end loop;
  if in_delete_order_rows = 'Y' then
    delete from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid;
    delete from orderhdr
     where orderid = in_orderid
       and shipid = in_shipid;
  end if;
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1,80);
end;

procedure gen_order_picks
(in_orderid           in number
,in_shipid            in number
,in_picktype          in varchar2
,in_userid            in varchar2
,out_errorno          in out number
,out_msg              in out varchar2)

is

l_picktype zone.picktype%type;
l_facility facility.facility%type;
l_wave waves.wave%type;
l_custid customer.custid%type;
l_cnt pls_integer;
l_dtlcnt pls_integer;
l_msg appmsgs.msgtext%type;

begin

out_errorno := 0;
out_msg := '';

if in_picktype = 'Line' then
  return;
end if;

l_cnt := 0;

for TK in (select rowid,taskid,facility,fromloc,wave,custid,orderitem,orderlot,lpid
             from tasks
            where orderid = in_orderid
              and shipid = in_shipid
              and priority = '9'
            order by taskid)
loop

  l_cnt := l_cnt + 1;
  if l_cnt = 1 then
    l_wave := TK.wave;
    l_facility := TK.facility;
    l_custid := TK.custid;
  end if;

  l_dtlcnt := 0;
  select count(1)
    into l_dtlcnt
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = TK.orderitem
     and nvl(lotnumber,'(none)') = nvl(TK.orderlot,'(none)');

  if (l_dtlcnt = 0) then
    delete_manual_picks(in_orderid, in_shipid, in_userid, TK.orderitem,
                        TK.orderlot, TK.lpid, 'N', out_errorno, out_msg);

    if (out_msg != 'OKAY') then
      out_msg := 'Unable to delete invalid manual task';
      return;
    end if;

    goto continue_tasks;
  end if;

  if in_picktype = 'Default' then
    l_picktype := zwv.default_picktype(TK.facility,TK.fromloc);
    if l_picktype = 'LINE' then
      goto continue_tasks;
    end if;
  end if;

  delete from tasks
   where rowid = TK.rowid;

  update subtasks
     set facility = null,
         taskid = 0,
         tasktype = 'OP'
   where taskid = TK.taskid;

<< continue_tasks >>
  null;
end loop;
update waves
   set picktype = decode(in_picktype,'Order','ORDR','Line','LINE',picktype)
 where wave = l_wave;

zwv.complete_pick_tasks(l_wave,l_facility,in_orderid,in_shipid,'3',
  '3', null, in_userid, null, null, 'N',
	'N', out_errorno, out_msg);

if out_errorno <> 0 then
  zms.log_autonomous_msg('GENORDPCK', l_facility, l_custid,
     out_msg, 'E', in_userid, l_msg);
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1,80);
end gen_order_picks;

end genlinepicks;
/
show error package body genlinepicks;
exit;
