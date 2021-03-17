set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
spool audit_tasks.out

declare
l_tot pls_integer := 0;
l_oky pls_integer := 0;
l_err pls_integer := 0;
l_sub_qty pls_integer := 0;
l_sub_pickqty pls_integer := 0;
l_sub_qtypicked pls_integer := 0;
l_sub_weight number(17,8);
l_upd_flag char(1) := 'N';

begin

for stsk in (select *
               from subtasks
              where not exists
                (select 1
                   from tasks
                  where subtasks.taskid = tasks.taskid)
                    and tasktype not in ('PI')) -- probably more types need to be added to this list
loop

  zut.prt('no task row for subtask ' || stsk.taskid ||
          ' stsk ' || stsk.tasktype ||
          ' lpid ' || stsk.lpid ||
          ' sqty ' || stsk.qty ||
          ' ' || to_char(stsk.lastupdate, 'mm/dd/yy hh24:mi:ss') ||
          ' ' || stsk.shippinglpid || 
          ' ptt ' || stsk.picktotype ||
          ' ct ' || stsk.cartontype);

  if l_upd_flag = 'Y' then
    delete from subtasks
          where taskid = stsk.taskid;
  end if;  
  
end loop;

for btsk in (select *
               from batchtasks
              where not exists
                (select 1
                   from tasks
                  where tasks.taskid = batchtasks.taskid))
loop

  zut.prt('no subtask row for batchtask ' || btsk.taskid ||
          ' btsk ' || btsk.tasktype ||
          ' lpid ' || btsk.lpid ||
          ' sqty ' || btsk.qty ||
          ' ' || to_char(btsk.lastupdate, 'mm/dd/yy hh24:mi:ss') ||
          ' ' || btsk.shippinglpid || 
          ' ptt ' || btsk.picktotype ||
          ' ct ' || btsk.cartontype);
          
  if l_upd_flag = 'Y' then
    delete from batchtasks
          where taskid = btsk.taskid;
  end if;  
  
end loop;

for tsk in (select *
              from tasks
             order by taskid)
loop

  l_sub_qty := 0;  
  l_sub_pickqty := 0;  
  l_sub_qtypicked := 0;
  l_sub_weight := 0;  

  for stsk in (select *
                 from subtasks
                where taskid = tsk.taskid)
  loop
    l_sub_qty := l_sub_qty + nvl(stsk.qty,0);
    l_sub_pickqty := l_sub_pickqty + nvl(stsk.pickqty,0);
    l_sub_qtypicked := l_sub_qtypicked + nvl(stsk.qtypicked,0);
    l_sub_weight := l_sub_weight + nvl(stsk.weight,0);
  end loop;
  
  if ((nvl(tsk.qty,0) != l_sub_qty) or
     (nvl(tsk.pickqty,0) != l_sub_pickqty) or
     (nvl(tsk.weight,0) != l_sub_weight)) then
    zut.prt(tsk.taskid ||
            ' task ' || tsk.tasktype ||
            ' wave ' || tsk.wave ||
            ' tqty ' || tsk.qty ||
            ' sqty ' || l_sub_qty ||
            ' tpqty ' || tsk.pickqty ||
            ' spqty ' || l_sub_pickqty ||
            ' twt ' || tsk.weight ||
            ' swt ' || l_sub_weight || 
            ' pckd  ' || l_sub_qtypicked ||
            ' lpid ' || tsk.lpid ||
            ' ' || to_char(tsk.lastupdate, 'mm/dd/yy hh24:mi:ss'));
            
    if l_upd_flag = 'Y' then
      update tasks
         set qty = l_sub_qty,
             pickqty = l_sub_pickqty,
             weight = l_sub_weight
       where taskid = tsk.taskid;
    end if;
    
    for stsk in (select *
                   from subtasks
                  where taskid = tsk.taskid)
    loop
      zut.prt(tsk.taskid ||
              ' stsk ' || tsk.tasktype ||
              ' lpid ' || stsk.lpid ||
              ' sqty ' || stsk.qty ||
              ' spqty ' || stsk.pickqty ||
              ' sweight ' || stsk.weight ||
              ' pckd ' || stsk.qtypicked ||
              ' ' || to_char(stsk.lastupdate, 'mm/dd/yy hh24:mi:ss') ||
              ' ' || stsk.shippinglpid || 
              ' ptt ' || stsk.picktotype ||
              ' ct ' || stsk.cartontype);
      if tsk.tasktype = 'BP' then
        for btsk in (select *
                       from batchtasks
                      where taskid = tsk.taskid
                        and custid = stsk.custid
                        and nvl(orderitem,'(none)') = nvl(stsk.orderitem,'(none)')
                        and nvl(orderlot,'(none)') = nvl(stsk.orderlot,'(none)')
                        and item = stsk.item
                        and nvl(lpid,'(none)') = nvl(stsk.lpid,'(none)'))
        loop
          zut.prt(tsk.taskid ||
                  ' btsk ' || tsk.tasktype ||
                  ' lpid ' || btsk.lpid ||
                  ' bqty ' || btsk.qty ||
                  ' bpqty ' || btsk.pickqty ||
                  ' bweight ' || btsk.weight ||
                  ' ' || to_char(btsk.lastupdate, 'mm/dd/yy hh24:mi:ss') ||
                  ' ' || btsk.shippinglpid ||
                  ' ' || btsk.orderid ||
                  '-' || btsk.shipid ||
                  ' ptt ' || btsk.picktotype ||
                  ' ct ' || btsk.cartontype);
        end loop;
      end if;
    end loop;
  end if;    
  
end loop;

end;
/
spool off;
exit;
