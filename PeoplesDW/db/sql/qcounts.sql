set serveroutput on;

declare
cntQTot integer;
cntRowTot integer;
cntRow integer;
cmdSql varchar2(4000);

begin

cntQTot := 0;
cntRowTot := 0;

for q in (select name, queue_table from user_queues
           where queue_type = 'NORMAL_QUEUE' order by name)
loop
  cntQTot := cntQTot + 1;
  cmdSql := 'select count(1) from ' || q.queue_table;
  execute immediate cmdSql into cntRow;
  zut.prt(q.name || ': ' || cntRow || ' (' || q.queue_table || ')');
  cntRowTot := cntRowTot + cntRow;
end loop;

zut.prt('Number of Queues: ' || cntQTot || 
       ' Total messages: ' || cntRowTot);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
