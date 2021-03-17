--
-- $Id$
--
set serveroutput on;

declare

cursor curAggInvTasks is
  select ai.*, ai.rowid
    from agginvtasks ai
  where exists
    (select 1
       from shippingplate sp, orderhdr oh
      where sp.lpid=ai.shippinglpid
        and oh.orderid=sp.orderid
        and oh.shipid=sp.shipid
        and (oh.orderstatus in('9','X')
         or  sp.status='SH'));

cursor curSelectParents is
  select *
    from plate
   where type in ('MP','PA')
     and parentlpid is null
     and status = 'A'
     and parentfacility is not null
     and nvl(qtytasked,0) != 0
     and exists (select *
                   from location
                  where plate.facility = location.facility
                    and plate.location = location.locid
                    and location.loctype = 'STO');

cursor curSubTaskSum(in_lpid varchar2) is
  select sum(ST.qty-nvl(ST.qtypicked,0)) as qty
    from subtasks ST, customer CU
   where ST.lpid = in_lpid
     and ST.tasktype in ('RP','PK','OP','BP','SO')
     and CU.custid = ST.custid
     and nvl(CU.paperbased,'N') = 'N';
ts curSubTaskSum%rowtype;

cursor curAggTaskSum(in_lpid varchar2) is
  select sum(qty) as qty
    from agginvtasks
   where lpid = in_lpid;
ta curAggTaskSum%rowtype;

cursor curSelectTaskByLip is
  select ST.lpid,
         sum(ST.qty-nvl(ST.qtypicked,0)) as qty
    from subtasks ST, customer CU
   where ST.tasktype in ('RP','PK','OP','BP','SO')
     and CU.custid = ST.custid
     and nvl(CU.paperbased,'N') = 'N'
   group by lpid;

cursor curGetPlate(in_lpid varchar2) is
  select *
    from plate
   where lpid = in_lpid
     and exists (select *
                   from location
                  where plate.facility = location.facility
                    and plate.location = location.locid
                    and location.loctype = 'STO');
pl curGetPlate%rowtype;

cursor curSelectAggTaskByLip is
  select lpid,
         sum(qty) as qty
    from agginvtasks
   group by lpid;

out_msg varchar2(255);
out_errorno integer;
cntRows integer;
cntTot integer;
cntErr integer;
cntOky integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;
cntLip integer;
qtyLip integer;
cntQty integer;
qtyQty integer;
lotrequired varchar2(1);
hazardous varchar2(1);
out_item varchar2(255);
updflag char(1);

begin

updflag := upper('&1');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
cntQty := 0;
qtyQty := 0;

zut.prt('checking for agginvtasks of shipped shipping plates or orders . . .');

for ai in curAggInvTasks
loop

  zut.prt(ai.shippinglpid || ' shipped plate/order ' || ai.qty);
  cntErr := cntErr + 1;
  qtyErr := qtyErr + ai.qty;
  if updflag = 'Y' then
    delete
      from agginvtasks
     where rowid = ai.rowid;
    commit;
  end if;

<<continue_parent_loop>>
  null;
end loop;

zut.prt('err count: ' || cntErr || ' err quantity: ' || qtyErr);

zut.prt('comparing plates to subtask/agginvtask (lp/st/at) . . .');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
cntQty := 0;
qtyQty := 0;

for mp in curSelectParents
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + mp.qtytasked;

  ts := null;
  open curSubTaskSum(mp.lpid);
  fetch curSubTaskSum into ts;
  close curSubTaskSum;
  ts.qty := nvl(ts.qty,0);

  ta := null;
  open curAggTaskSum(mp.lpid);
  fetch curAggTaskSum into ta;
  close curAggTaskSum;
  ta.qty := nvl(ta.qty,0);

  if nvl(mp.qtytasked,0) != (ts.qty + ta.qty) then
    zut.prt(mp.lpid || ' plate/task mismatch ' ||
      mp.qtytasked || '/' || ts.qty || '/' || ta.qty);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + mp.qtytasked;
    if updflag = 'Y' then
      update plate
         set qtytasked = ts.qty + ta.qty
       where lpid = mp.lpid;
      commit;
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + mp.qtytasked;
  end if;

<<continue_parent_loop>>
  null;
end loop;

zut.prt('tot count: ' || cntTot || ' tot quantity: ' || qtyTot);
zut.prt('err count: ' || cntErr || ' err quantity: ' || qtyErr);
zut.prt('oky count: ' || cntOky || ' oky quantity: ' || qtyOky);
zut.prt('qty count: ' || cntQty || ' qty quantity: ' || qtyQty);

zut.prt('comparing subtask to plates (st/at/lp) . . .');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
cntQty := 0;
qtyQty := 0;

for mp in curSelectTaskByLip
loop

  cntTot := cntTot + 1;

  pl := null;
  open curGetPlate(mp.lpid);
  fetch curGetPlate into pl;
  close curGetPlate;
  pl.quantity := nvl(pl.quantity,0);

  ta := null;
  open curAggTaskSum(mp.lpid);
  fetch curAggTaskSum into ta;
  close curAggTaskSum;
  ta.qty := nvl(ta.qty,0);

  qtyTot := qtyTot + mp.qty + ta.qty;

  if (pl.parentfacility is not null) and
     ((mp.qty + ta.qty) != nvl(pl.qtytasked,0)) then
    zut.prt(mp.lpid || ' task/plate mismatch ' ||
      mp.qty || '/' || ta.qty || '/' || pl.qtytasked);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + mp.qty + ta.qty;
    if pl.lpid is null then
      zut.prt('parent is missing ' || mp.lpid);
    end if;
    if updflag = 'Y' then
      if pl.lpid is not null then
        update plate
           set qtytasked = mp.qty + ta.qty
         where lpid = mp.lpid;
        commit;
      end if;
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + mp.qty + ta.qty;
  end if;

<<continue_parent_loop>>
  null;
end loop;

zut.prt('tot count: ' || cntTot || ' tot quantity: ' || qtyTot);
zut.prt('err count: ' || cntErr || ' err quantity: ' || qtyErr);
zut.prt('oky count: ' || cntOky || ' oky quantity: ' || qtyOky);
zut.prt('qty count: ' || cntQty || ' qty quantity: ' || qtyQty);

zut.prt('comparing agginvtask to plates (at/st/lp) . . .');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
cntQty := 0;
qtyQty := 0;

for mp in curSelectAggTaskByLip
loop

  cntTot := cntTot + 1;

  pl := null;
  open curGetPlate(mp.lpid);
  fetch curGetPlate into pl;
  close curGetPlate;
  pl.quantity := nvl(pl.quantity,0);

  ts := null;
  open curSubTaskSum(mp.lpid);
  fetch curSubTaskSum into ts;
  close curSubTaskSum;
  ts.qty := nvl(ts.qty,0);

  qtyTot := qtyTot + mp.qty + ts.qty;

  if (pl.parentfacility is not null) and
     ((mp.qty + ts.qty) != nvl(pl.qtytasked,0)) then
    zut.prt(mp.lpid || ' task/plate mismatch ' ||
      mp.qty || '/' || ts.qty || '/' || pl.qtytasked);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + mp.qty + ts.qty;
    if pl.lpid is null then
      zut.prt('parent is missing ' || mp.lpid);
    end if;
    if updflag = 'Y' then
      if pl.lpid is not null then
        update plate
           set qtytasked = mp.qty + ts.qty
         where lpid = mp.lpid;
        commit;
      end if;
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + mp.qty + ts.qty;
  end if;

<<continue_parent_loop>>
  null;
end loop;

zut.prt('tot count: ' || cntTot || ' tot quantity: ' || qtyTot);
zut.prt('err count: ' || cntErr || ' err quantity: ' || qtyErr);
zut.prt('oky count: ' || cntOky || ' oky quantity: ' || qtyOky);
zut.prt('qty count: ' || cntQty || ' qty quantity: ' || qtyQty);

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;
/
exit;
