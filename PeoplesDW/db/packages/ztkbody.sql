create or replace PACKAGE BODY alps.ztasks
IS
--
-- $Id$
--

function active_tasks_for_order
(in_orderid number
,in_shipid number
) return boolean
is
l_cnt pls_integer;
begin

select count(1)
  into l_cnt
  from tasks
 where orderid = in_orderid
   and shipid = in_shipid
   and priority = '0';
if l_cnt != 0 then
  return true;
end if;

select count(1)
  into l_cnt
  from subtasks
 where orderid = in_orderid
   and shipid = in_shipid
   and priority = '0';
if l_cnt != 0 then
  return true;
end if;

for bt in (select distinct taskid
             from batchtasks
			where orderid = in_orderid
			  and shipid = in_shipid)
loop

	select count(1)
	  into l_cnt
	  from tasks
	 where taskid = bt.taskid
	   and priority = '0';
	if l_cnt != 0 then
	  return true;
	end if;
	
	select count(1)
	  into l_cnt
	  from subtasks
	 where taskid = bt.taskid
	   and priority = '0';
	if l_cnt != 0 then
	  return true;
	end if;
	
	select count(1)
	  into l_cnt
	  from tasks
	 where taskid = bt.taskid
	   and priority = '0';
	if l_cnt != 0 then
	  return true;
	end if;
	
end loop;

return false;

exception when others then
  return false;
end;

function active_tasks_for_orderdtl
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
) return boolean
is
l_cnt pls_integer;
begin
select count(1)
  into l_cnt
  from tasks a
 where priority = '0'
  and exists (
    select 1 
    from subtasks
    where taskid = a.taskid
      and orderid = in_orderid and shipid = in_shipid
      and orderitem = in_item and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)'));
if l_cnt != 0 then
  return true;
end if;
select count(1)
  into l_cnt
  from subtasks
 where orderid = in_orderid
   and shipid = in_shipid
   and orderitem = in_item and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
   and priority = '0';
if l_cnt != 0 then
  return true;
end if;
for bt in (select distinct taskid
             from batchtasks
			where orderid = in_orderid
			  and shipid = in_shipid
        and orderitem = in_item and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)'))
loop
	select count(1)
	  into l_cnt
	  from tasks
	 where taskid = bt.taskid
	   and priority = '0';
	if l_cnt != 0 then
	  return true;
	end if;
	select count(1)
	  into l_cnt
	  from subtasks
	 where taskid = bt.taskid
	   and priority = '0';
	if l_cnt != 0 then
	  return true;
	end if;
end loop;
return false;
exception when others then
  return false;
end;

function passed_tasks_for_order
(in_orderid number
,in_shipid number
) return boolean
is
l_cnt pls_integer;
begin

select count(1)
  into l_cnt
  from tasks
 where orderid = in_orderid
   and shipid = in_shipid
   and priority in ('7','8');
if l_cnt != 0 then
  return true;
end if;

select count(1)
  into l_cnt
  from subtasks
 where orderid = in_orderid
   and shipid = in_shipid
   and priority in ('7','8');
if l_cnt != 0 then
  return true;
end if;

return false;

exception when others then
  return false;
end passed_tasks_for_order;

PROCEDURE task_delete
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curTask is
  select taskid, tasktype, priority, lpid
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;

cursor curSubTasks is
  select rowid, custid, lpid
    from subtasks
   where taskid = in_taskid;

begin

out_msg := '';

tk := null;
open curTask;
fetch curTask into tk;
close curTask;
if tk.taskid is null then
  out_msg := 'Task not found: ' || in_taskid;
  return;
end if;

if tk.tasktype not in ('RP','CC','MV','PA','SP') then
  out_msg := 'Invalid task type for deletion: ' || tk.tasktype;
  return;
end if;

if tk.priority = '0' then
  out_msg := 'Active tasks cannot be deleted';
  return;
end if;

if tk.tasktype in ('MV','PA','SP') then
   update plate
     set destfacility = null,
          destlocation = null
      where lpid in (select lpid from plate
                        start with lpid = tk.lpid
                        connect by prior lpid = parentlpid);
end if;

for sb in curSubTasks loop
  subtask_no_pick(sb.rowid,
    in_facility,
    sb.custid,
    in_taskid,
    sb.lpid,
    in_userid,
    'Y', -- delete commitments
    out_msg);
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tktd ' || substr(sqlerrm,1,80);
end task_delete;

PROCEDURE subtask_no_pick
(in_rowid rowid
,in_facility varchar2
,in_custid varchar2
,in_taskid number
,in_lpid varchar2
,in_userid varchar2
,in_delete_commitments_yn varchar2
,out_msg IN OUT varchar2
) is

cursor curTask is
  select taskid,
         tasktype,
         priority
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;
cursor c_cus(p_custid varchar2) is
   select nvl(paperbased, 'N') paperbased
      from customer
      where custid = p_custid;
cus c_cus%rowtype;
cursor c_oh(p_orderid number, p_shipid number) is
   select nvl(ordertype, 'x') ordertype
      from orderhdr
      where orderid = p_orderid
        and shipid = p_shipid;
oh c_oh%rowtype;
cntRows integer;
st subtasks%rowtype;
sh shippingplate%rowtype;
pl plate%rowtype;
cm commitments%rowtype;

begin

out_msg := '';

st := null;
tk := null;
st.orderid := 0;

open curTask;
fetch curTask into tk;
close curTask;
if tk.taskid is null then
  out_msg := 'Task not found: ' || in_taskid;
  return;
end if;

if tk.priority = '0' then
  out_msg := 'Active tasks cannot be deleted';
  return;
end if;

delete
  from subtasks
 where rowid = in_rowid
 returning tasktype, qty, shippinglpid,
           nvl(orderid,0), shipid, orderitem, orderlot,
           item, custid, lpid
      into st.TaskType, st.qty, st.shippinglpid,
           st.orderid, st.shipid, st.orderitem, st.orderlot,
           st.item, st.custid, st.lpid;

delete
  from shippingplate
 where lpid = st.shippinglpid
   and status = 'U'
 returning inventoryclass, lotnumber, invstatus
      into sh.inventoryclass, sh.lotnumber, sh.invstatus;

delete
  from batchtasks
 where taskid = in_taskid
   and custid = st.custid
   and nvl(orderitem,'(none)') = nvl(st.orderitem,'(none)')
   and nvl(orderlot,'(none)') = nvl(st.orderlot,'(none)')
   and item = st.item
   and nvl(lpid,'(none)') = nvl(st.lpid,'(none)');

select count(1)
  into cntRows
  from subtasks
 where taskid = in_taskid;

if cntRows = 0 then
  delete from tasks
   where taskid = in_taskid;
else
  update tasks
     set qty = qty - st.qty
   where taskid = in_taskid
     and qty > st.qty;
end if;

if in_lpid is not null then
   open c_cus(st.custid);
   fetch c_cus into cus;
   close c_cus;

   open c_oh(st.orderid, st.shipid);
   fetch c_oh into oh;
   close c_oh;

   if (cus.paperbased = 'Y') and (oh.ordertype = 'O') then
      zsod.deplete_shippinglpid_qtytasked(st.shippinglpid, out_msg);
      if out_msg is not null then
         return;
      end if;
   else
      pl.qtytasked := 0;
      begin
         select nvl(qtytasked,0), orderid, location
            into pl.qtytasked, pl.orderid, pl.location
            from plate
            where lpid = in_lpid;
      exception when others then
         null;
      end;
      if pl.qtytasked >=  st.qty then
         pl.qtytasked := pl.qtytasked - st.qty;
      else
         pl.qtytasked := null;
      end if;
      update plate
         set qtytasked = pl.qtytasked
         where lpid = in_lpid;
   end if;
end if;

cm := null;
if in_delete_commitments_yn = 'Y' then
  update commitments
     set qty = qty - st.qty
   where orderid = st.orderid
     and shipid = st.shipid
     and orderitem = st.orderitem
     and nvl(orderlot,'(none)') = nvl(st.orderlot,'(none)')
     and item = st.item
     and nvl(nvl(lotnumber,sh.lotnumber),'(none)') = nvl(sh.lotnumber,'(none)')
     and inventoryclass = sh.inventoryclass
     and invstatus = sh.invstatus
   returning qty into cm.qty;
  if cm.qty <= 0 then
    delete from commitments
     where orderid = st.orderid
       and shipid = st.shipid
       and orderitem = st.orderitem
       and nvl(orderlot,'(none)') = nvl(st.orderlot,'(none)')
       and item = st.item
       and nvl(nvl(lotnumber,sh.lotnumber),'(none)') = nvl(sh.lotnumber,'(none)')
       and inventoryclass = sh.inventoryclass
       and invstatus = sh.invstatus;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tksnp ' || substr(sqlerrm,1,80);
end subtask_no_pick;

PROCEDURE delete_subtasks_by_loadno
(in_loadno number
,in_userid varchar2
,in_facility varchar2
,out_msg IN OUT varchar2
) is

cursor curSubTasks is
  select rowid,
         taskid,
         custid,
         facility,
         lpid
    from subtasks
   where loadno = in_loadno
     and facility = in_facility
     and not exists
       (select * from tasks
         where subtasks.taskid = tasks.taskid
           and priority = '0');

strMsg appmsgs.msgtext%type;

begin

out_msg := '';

for st in curSubTasks
loop
  subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
    in_userid, 'Y', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('DeleteTask', st.facility, st.custid,
       out_msg, 'E', in_userid, strmsg);
  end if;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tkdbl ' || substr(sqlerrm,1,80);
end delete_subtasks_by_loadno;

PROCEDURE delete_subtasks_by_order
(in_orderid number
,in_shipid number
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curSubTasks is
  select rowid,
         taskid,
         custid,
         facility,
         lpid
    from subtasks
   where orderid = in_orderid and shipid = in_shipid
     and not exists
       (select * from tasks
         where subtasks.taskid = tasks.taskid
           and priority = '0');

strMsg appmsgs.msgtext%type;

begin

out_msg := '';

for st in curSubTasks
loop
  subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
    in_userid, 'Y', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('DeleteTask', st.facility, st.custid,
       out_msg, 'E', in_userid, strmsg);
  end if;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tkdbl ' || substr(sqlerrm,1,80);
end delete_subtasks_by_order;

PROCEDURE delete_subtasks_by_orderitem
(in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_orderlot varchar2
,in_userid varchar2
,in_reqtype varchar2
,out_msg IN OUT varchar2
) is

cursor curSubTasks(p_orderid number, p_shipid number) is
  select rowid,
         taskid,
         custid,
         facility,
         lpid
    from subtasks
   where orderid = p_orderid
     and shipid = p_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and not exists
       (select * from tasks
         where subtasks.taskid = tasks.taskid
           and tasks.priority = '0');

strMsg appmsgs.msgtext%type;
delete_commitments_yn varchar2(1);
cntSubTasks integer;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;

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

cntSubTasks := 0;

for st in curSubTasks(l_orderid, l_shipid)
loop
  cntSubTasks := cntSubTasks + 1;
  subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
    in_userid, delete_commitments_yn, out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('DeleteTask', st.facility, st.custid,
       out_msg, 'E', in_userid, strMsg);
  end if;
end loop;

if (l_shipid = 0) then
  for st in curSubTasks(in_orderid, in_shipid)
  loop
    cntSubTasks := cntSubTasks + 1;
    subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
      in_userid, delete_commitments_yn, out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('DeleteTask', st.facility, st.custid,
         out_msg, 'E', in_userid, strMsg);
    end if;
  end loop;
end if;

if (cntSubTasks = 0) and
   (delete_commitments_yn = 'Y') then
  begin
    select count(1)
      into cntSubTasks
      from SubTasks
     where orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_orderitem
       and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
  exception when others then
    cntSubTasks := 0;
  end;
  if cntSubTasks = 0 then
    begin
      select count(1)
        into cntSubTasks
        from BatchTasks
       where orderid = in_orderid
         and shipid = in_shipid
         and orderitem = in_orderitem
         and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
    exception when others then
      cntSubTasks := 0;
    end;
  end if;
  if cntSubTasks = 0 then
    delete from commitments
     where orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_orderitem
       and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tkdbo ' || substr(sqlerrm,1,80);
end delete_subtasks_by_orderitem;

function upgrade_priority
(in_current_priority varchar2
) return varchar2 is
out_priority char(1);
begin

if in_current_priority = '4' then
  out_priority := '3';
elsif in_current_priority = '3' then
  out_priority := '2';
elsif in_current_priority = '2' then
  out_priority := '1';
else
  out_priority := in_current_priority;
end if;

return out_priority;

exception when others then
  return in_current_priority;
end upgrade_priority;

PROCEDURE task_change_priority
(in_facility varchar2
,in_taskid number
,in_priority varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curTask is
  select tasktype,
         priority,
         lpid,
         fromloc,
         facility
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;

cntXdock integer;
strLocType location.loctype%type;

begin

out_msg := '';

if in_priority in ('0','5','7','8') then
  out_msg := 'Priority ' || in_priority || ' is reserved for system use: ' || in_taskid;
  return;
end if;

open curTask;
fetch curTask into tk;
if curTask%notfound then
  close curTask;
  out_msg := 'Task not found: ' || in_taskid;
  return;
end if;
close curTask;

if tk.priority = '0' then
  out_msg := 'Active tasks cannot be updated: ' || in_taskid;
  return;
end if;

if tk.priority = '5' then
  out_msg := 'Suspended tasks cannot be updated: ' || in_taskid;
  return;
end if;

if tk.priority in ('7', '8') then
  out_msg := 'Passed tasks cannot be updated: ' || in_taskid;
  return;
end if;

if tk.priority = '9' then
  cntXdock := 0;
  begin
    select loctype
      into strLocType
      from location
     where facility = tk.facility
       and locid = tk.fromloc;
  exception when others then
    strloctype := '?';
  end;
  if strloctype = 'CD' then
    begin
      select count(1)
        into cntXdock
        from tasks
       where lpid = tk.lpid
         and toloc = tk.fromloc;
    exception when others then
      cntXdock := 0;
    end;
    if cntXdock <> 0 then
      out_msg := 'Pending Cross Dock Picks cannot be unheld: ' || in_taskid;
      return;
    end if;
  end if;
end if;

update tasks
   set prevpriority = priority,
       priority = rtrim(in_priority),
       lastuser = rtrim(in_userid),
       lastupdate = sysdate
 where taskid = in_taskid;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tkcp ' || substr(sqlerrm,1,80);
end task_change_priority;

PROCEDURE task_preassign
(in_facility varchar2
,in_taskid number
,in_touserid varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curTask is
  select tasktype,
         priority
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;

begin

out_msg := '';

open curTask;
fetch curTask into tk;
if curTask%notfound then
  close curTask;
  out_msg := 'Task not found: ' || in_taskid;
  return;
end if;
close curTask;

if tk.priority = '0' then
  out_msg := 'Active tasks cannot be updated: ' || in_taskid;
  return;
end if;

if tk.priority in ('7', '8') then
  out_msg := 'Passed tasks cannot be updated: ' || in_taskid;
  return;
end if;

update tasks
   set touserid = rtrim(in_touserid),
       lastuser = rtrim(in_userid),
       lastupdate = sysdate
 where taskid = in_taskid;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tkpa ' || substr(sqlerrm,1,80);
end task_preassign;

PROCEDURE task_to_pick_list
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curTask is
  select tasktype,
         priority
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;

begin

out_msg := '';

open curTask;
fetch curTask into tk;
if curTask%notfound then
  close curTask;
  out_msg := 'Task not found: ' || in_taskid;
  return;
end if;
close curTask;

if tk.priority = '0' then
  out_msg := 'Active tasks cannot be updated: ' || in_taskid;
  return;
end if;

if tk.priority in ('7', '8') then
  out_msg := 'Passed tasks cannot be updated: ' || in_taskid;
  return;
end if;

if tk.tasktype not in ('OP') then
  out_msg := 'Invalid task type for paper pick: ' || tk.tasktype;
  return;
end if;

update tasks
   set prevpriority = priority,
       priority = '0',
       curruserid = 'PAPER',
       lastuser = in_userid,
       lastupdate = sysdate
 where taskid = in_taskid;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tktpl ' || substr(sqlerrm,1,80);
end task_to_pick_list;

PROCEDURE task_reverse_pick_list
(in_facility varchar2
,in_taskid number
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curTask is
  select tasktype,
         priority
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;

begin

out_msg := '';

open curTask;
fetch curTask into tk;
if curTask%notfound then
  close curTask;
  out_msg := 'Task not found: ' || in_taskid;
  return;
end if;
close curTask;

if tk.priority != '0' then
  out_msg := 'Inactive tasks cannot be updated: ' || in_taskid;
  return;
end if;

if tk.tasktype not in ('OP') then
  out_msg := 'Invalid task type for paper pick reversal: ' || tk.tasktype;
  return;
end if;

update tasks
   set priority = prevpriority,
       curruserid = '',
       lastuser = in_userid,
       lastupdate = sysdate
 where taskid = in_taskid;

out_msg := 'OKAY';

exception when others then
  out_msg := 'tktrpl ' || substr(sqlerrm,1,80);
end task_reverse_pick_list;


procedure task_to_labels
   (in_facility in varchar2,
    in_taskid   in number,
    in_userid   in varchar2,
    in_prtid    in varchar2,
    in_profid   in varchar2,
    out_msg     in out varchar2)
is
   cursor c_tk is
      select tasktype, priority, orderid, shipid
         from tasks
         where taskid = in_taskid;
   tk c_tk%rowtype;
   cursor c_sub is
      select shippinglpid, pickuom
         from subtasks
         where taskid = in_taskid
         order by locseq;
   cursor c_prof is
      select rowid, uom
         from labelprofileline
         where profid = in_profid
           and businessevent = 'LBPK'
           and print = 'Y'
           and nvl(viewkeyorigin,'?') = 'S'
           and zlbl.is_order_satisfied(tk.orderid, tk.shipid, passthrufield, passthruvalue) = 'Y'
         order by seq;
   rowfound boolean;
   printed boolean;
   msg varchar2(80);
begin
   out_msg := null;

   open c_tk;
   fetch c_tk into tk;
   rowfound := c_tk%found;
   close c_tk;

   if not rowfound then
      out_msg := 'Task not found: ' || in_taskid;
      return;
   end if;

   if tk.priority = '0' then
      out_msg := 'Active tasks cannot be updated: ' || in_taskid;
      return;
   end if;

   if tk.priority in ('7', '8') then
      out_msg := 'Passed tasks cannot be updated: ' || in_taskid;
      return;
   end if;

   if tk.tasktype not in ('OP') then
      out_msg := 'Invalid task type for label pick: ' || tk.tasktype;
      return;
   end if;

   for s in c_sub loop
      printed := false;
      for p in c_prof loop
         if (nvl(p.uom, s.pickuom) = s.pickuom) then
            zlbl.print_a_plate(s.shippinglpid, rowidtochar(p.rowid), in_prtid,
                  in_facility, in_userid, msg, 'A');
            if (msg is not null) then
               out_msg := 'print_a_plate err: ' || msg;
               return;
            end if;
            printed := true;
            exit;
         end if;
      end loop;
      if not printed then
         out_msg := 'Nothing to print for Shipping LiP: ' || s.shippinglpid;
         return;
      end if;
   end loop;

   update tasks
      set prevpriority = priority,
          priority = '0',
          curruserid = 'LABEL',
          lastuser = in_userid,
          lastupdate = sysdate
      where taskid = in_taskid;

   out_msg := 'OKAY';

exception when others then
   out_msg := 'tktlb ' || substr(sqlerrm,1,80);
end task_to_labels;


procedure task_reverse_labels
   (in_facility in varchar2,
    in_taskid   in number,
    in_userid   in varchar2,
    out_msg     in out varchar2)
is
   cursor c_tk is
      select tasktype, priority
         from tasks
         where taskid = in_taskid;
   tk c_tk%rowtype;
   rowfound boolean;
begin
   out_msg := null;

   open c_tk;
   fetch c_tk into tk;
   rowfound := c_tk%found;
   close c_tk;

   if not rowfound then
      out_msg := 'Task not found: ' || in_taskid;
      return;
   end if;

   if tk.priority != '0' then
      out_msg := 'Inactive tasks cannot be updated: ' || in_taskid;
      return;
   end if;

   if tk.tasktype not in ('OP') then
      out_msg := 'Invalid task type for label pick reversal: ' || tk.tasktype;
      return;
   end if;

   update tasks
      set priority = prevpriority,
          curruserid = null,
          lastuser = in_userid,
          lastupdate = sysdate
      where taskid = in_taskid;

   out_msg := 'OKAY';

exception when others then
   out_msg := 'tktrlb ' || substr(sqlerrm,1,80);
end task_reverse_labels;

procedure picked_plate_count
  (in_taskid in  number,
   out_count out number,
   out_msg   out varchar2)
is
  task_count integer;
begin
   out_msg := 'OKAY';
   out_count := 0;

   task_count := 0;
   for sp in (select status from shippingplate where taskid = in_taskid and
      parentlpid is null)
   loop
     if sp.status = 'P' then
       task_count := task_count + 1;
     end if;
   end loop;

   if task_count = 0 then
     select count(1) into task_count
     from plate
     where taskid = in_taskid and type = 'TO';
   end if;

   out_count := task_count;
exception when others then
   out_msg := 'tkppc ' || substr(sqlerrm,1,80);
end picked_plate_count;

function task_crush_factor
(in_taskid number
,in_tasktype varchar2
,in_custid varchar2
,in_item varchar2
) return number
is
   cursor c_it is
      select nvl(decode(crush_factor,0,10000,crush_factor),10000) crush_factor
        from custitem
       where custid = in_custid
         and item = in_item;
   cit c_it%rowtype;

   cursor c_tk is
      select nvl(decode(cit.crush_factor,0,10000,cit.crush_factor),10000) crush_factor
        from subtasks st, custitem cit
       where st.taskid = in_taskid
         and cit.custid = st.custid
         and cit.item = st.item
       order by nvl(decode(cit.crush_factor,0,10000,cit.crush_factor),10000);
   ctk c_tk%rowtype;

   l_crush_factor number;
begin
   l_crush_factor := 10000;
   
   if (in_tasktype in ('BP','OP','PK')) then
      if (nvl(trim(in_custid),'(none)') <> '(none)') and 
         (nvl(trim(in_item),'(none)') <> '(none)') then

         cit := null;
         open c_it;
         fetch c_it into cit;
         close c_it;
         
         if(cit.crush_factor is not null) then
            l_crush_factor := cit.crush_factor;
         end if;
      else
         ctk := null;
         open c_tk;
         fetch c_tk into ctk;
         close c_tk;
         
         if(ctk.crush_factor is not null) then
            l_crush_factor := ctk.crush_factor;
         end if;
      end if;
   end if;

   return l_crush_factor;
exception when others then
   return 10000;
end task_crush_factor;

function task_uom_pick_seq
(in_tasktype varchar2
,in_custid varchar2
,in_pickuom varchar2
) return number
is
   cursor c_cups is
      select sequence
        from custuompickseq
       where custid = in_custid
         and pickuom = in_pickuom;
   ccups c_cups%rowtype;

   l_uom_pick_seq number;
begin
   l_uom_pick_seq := 10000;
   
   if (in_tasktype in ('BP','OP','PK')) then
      if (nvl(trim(in_custid),'(none)') <> '(none)') and
         (nvl(trim(in_pickuom),'(none)') <> '(none)') then

         ccups := null;
         open c_cups;
         fetch c_cups into ccups;
         close c_cups;
         
         if(ccups.sequence is not null) then
            l_uom_pick_seq := ccups.sequence;
         end if;
      end if;
   end if;

   return l_uom_pick_seq;
exception when others then
   return 10000;
end task_uom_pick_seq;

end ztasks;
/
show error package body ztasks;
exit;
