--
-- $Id$
--
set serveroutput on;

declare

cursor curOrderTask is
  select taskid
    from tasks
   where orderid = &orderid
     and shipid = &shipid;

cursor curTask(in_taskid number) is
  select tasktype,
         priority
    from tasks
   where taskid = in_taskid;
tk curTask%rowtype;

cursor curSubTasks(in_taskid number) is
  select rowid, facility, custid, lpid
    from subtasks
   where taskid = in_taskid;

out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);
out_special_stock varchar2(255);
begin

out_msg := '';

for oh in curOrderTask
loop

  open curTask(oh.taskid);
  fetch curTask into tk;
  if curTask%notfound then
    close curTask;
    zut.prt('Task not found: ' || oh.taskid);
    return;
  end if;
  close curTask;

  if tk.priority = '0' then
    zut.prt('Active tasks cannot be deleted');
    return;
  end if;

  for sb in curSubTasks(oh.taskid)
  loop
    ztk.subtask_no_pick(sb.rowid,
      sb.facility,
      sb.custid,
      oh.taskid,
      sb.lpid,
      'ZADJ',
      out_msg);
  end loop;

end loop;

zut.prt('out_msg:  ' || out_msg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
