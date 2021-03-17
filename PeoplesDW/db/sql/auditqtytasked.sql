--
-- $Id$
--
set serveroutput on;
set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
spool auditqtytasked.out

declare

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
    from subtasks ST
   where lpid = in_lpid
     and tasktype in ('RP','PK','OP','BP','SO');
ts curSubTaskSum%rowtype;

cursor curSelectTaskByLip is
  select lpid,
         sum(ST.qty-nvl(ST.qtypicked,0)) as qty
    from subtasks ST
   where tasktype in ('RP','PK','OP','BP','SO')
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

zut.prt('comparing plates to subtask. . .');

for mp in curSelectParents
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + mp.quantity;

  ts := null;
  open curSubTaskSum(mp.lpid);
  fetch curSubTaskSum into ts;
  close curSubTaskSum;
  ts.qty := nvl(ts.qty,0);

  if nvl(mp.qtytasked,0) != ts.qty then
    zut.prt(mp.lpid || ' plate/task mismatch ' ||
      mp.qtytasked || '/' || ts.qty);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + mp.quantity;
    if updflag = 'Y' then
      update plate
         set qtytasked = ts.qty
       where lpid = mp.lpid;
      commit;
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + mp.quantity;
  end if;

<<continue_parent_loop>>
  null;
end loop;

zut.prt('tot count: ' || cntTot || ' tot quantity: ' || qtyTot);
zut.prt('err count: ' || cntErr || ' err quantity: ' || qtyErr);
zut.prt('oky count: ' || cntOky || ' oky quantity: ' || qtyOky);
zut.prt('qty count: ' || cntQty || ' qty quantity: ' || qtyQty);

zut.prt('comparing subtask to plates. . .');

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
  qtyTot := qtyTot + mp.qty;

  pl := null;
  open curGetPlate(mp.lpid);
  fetch curGetPlate into pl;
  close curGetPlate;
  pl.quantity := nvl(pl.quantity,0);

  if (pl.parentfacility is not null) and
     (mp.qty != nvl(pl.qtytasked,0)) then
    zut.prt(mp.lpid || ' task/plate mismatch ' ||
      mp.qty || '/' || pl.qtytasked);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + 1;
    if pl.lpid is null then
      zut.prt('parent is missing ' || mp.lpid);
    end if;
    if updflag = 'Y' then
      if pl.lpid is not null then
        update plate
           set qtytasked = mp.qty
         where lpid = mp.lpid;
        commit;
      end if;
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + mp.qty;
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

