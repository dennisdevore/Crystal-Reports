--
-- $Id$
--
set serveroutput on;

declare

in_taskid number(15);

cursor curTask is
  select tasktype,
         priority
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;

cursor curSubTasks is
  select rowid, facility, custid, lpid
    from subtasks
   where taskid = in_taskid;

out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);
out_special_stock varchar2(255);
begin

out_msg := '';

in_taskid := &taskid;

open curTask;
fetch curTask into tk;
if curTask%notfound then
  close curTask;
  zut.prt('Task not found: ' || in_taskid);
  return;
end if;
close curTask;

if tk.priority = '0' then
  zut.prt('Active tasks cannot be deleted');
  return;
end if;

for sb in curSubTasks loop
  ztk.subtask_no_pick(sb.rowid,
    sb.facility,
    sb.custid,
    in_taskid,
    sb.lpid,
    'SYNAPSE',
    'Y',
    out_msg);
end loop;

zut.prt('out_msg:  ' || out_msg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
