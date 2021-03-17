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

zcu.pack_list_format(&orderid,&shipid,out_msg);
zut.prt('out_msg:  [' || out_msg || ']');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/

--exit;
