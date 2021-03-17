--
-- $Id$
--
set serveroutput on;

declare

cursor curselect is
  select lpid,
         nvl(quantity,0) as qty,
         'P' as fromtable
    from plate p
    where custid = 'HP'
      and type = 'PA'
      and ( (lasttask in ('IA','SC')) or
            (exists (select *
                       from platehistory h
                      where p.lpid = h.lpid
                        and h.lasttask in ('IA','SC'))) )
    union
  select lpid,
         nvl(quantity,0) as qty,
         'D' as fromtable
    from deletedplate p
    where custid = 'HP'
      and type = 'PA'
      and ( (lasttask in ('IA','SC')) or
            (exists (select *
                       from platehistory h
                      where p.lpid = h.lpid
                        and h.lasttask in ('IA','SC'))) );


cursor curPlate(in_lpid varchar2) is
  select lastupdate as whenoccurred,
         lastuser,
         lasttask,
         item,
         lotnumber,
         invstatus,
         inventoryclass,
         unitofmeasure as uom,
         nvl(quantity,0) as qty,
         custid,
         facility,
         adjreason
    from plate
   where lpid = in_lpid;

cursor curPlateHistory(in_lpid varchar2) is
  select whenoccurred,
         lastuser,
         lasttask,
         item,
         lotnumber,
         invstatus,
         inventoryclass,
         unitofmeasure as uom,
         nvl(quantity,0) as qty,
         custid,
         facility,
         adjreason
    from platehistory
   where lpid = in_lpid
   order by whenoccurred desc;
prv curPlateHistory%rowtype;

out_msg varchar2(255);
out_errorno integer;
cntTot integer;
cntErr integer;
cntOky integer;
cntRows integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;

begin

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

zut.prt('begin loop. . .');

for sel in curSelect
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sel.qty;

  zut.prt('processing ' || sel.lpid);

  if sel.fromtable = 'P' then
    open curPlate(sel.lpid);
    fetch curPlate into prv;
    close curPlate;
  else
    prv.whenoccurred := null;
  end if;

  for plh in curPlateHistory(sel.lpid)
  loop

    if prv.whenoccurred is null then
     goto continue_plh_loop;
    end if;

    if nvl(prv.lasttask,'x') not in ('IA','SC') then
      goto continue_plh_loop;
    end if;

    if prv.custid is null or
       prv.item is null or
       prv.invstatus is null or
       prv.inventoryclass is null then
      goto continue_plh_loop;
    end if;

    zut.prt('adjustment for ' || sel.lpid);

    if prv.custid = plh.custid and
       prv.item = plh.item and
       nvl(prv.lotnumber,'(none)') = nvl(plh.lotnumber,'(none)') and
       prv.invstatus = plh.invstatus and
       prv.inventoryclass = plh.inventoryclass then
      if prv.qty != plh.qty then
        insert into invadjactivity
         (whenoccurred, lpid, facility, custid, item, lotnumber,
          inventoryclass, invstatus, uom, adjqty, adjreason,
          tasktype, adjuser, lastuser, lastupdate)
          values
         (prv.whenoccurred, sel.lpid, prv.facility, prv.custid, prv.item, prv.lotnumber,
          prv.inventoryclass, prv.invstatus, prv.uom, plh.qty - prv.qty, prv.adjreason,
          prv.lasttask, prv.lastuser, 'CONVERT', sysdate);
      else
        zut.prt('all info the same ' || dt(prv.whenoccurred));
      end if;
    elsif prv.custid != plh.custid or
          prv.item != plh.item or
          nvl(prv.lotnumber,'(none)') != nvl(plh.lotnumber,'(none)') or
          prv.invstatus != plh.invstatus or
          prv.inventoryclass != plh.inventoryclass then
      insert into invadjactivity
       (whenoccurred, lpid, facility, custid, item, lotnumber,
        inventoryclass, invstatus, uom, adjqty, adjreason,
        tasktype, adjuser, lastuser, lastupdate)
        values
       (prv.whenoccurred, sel.lpid, plh.facility, plh.custid, plh.item, plh.lotnumber,
        plh.inventoryclass, plh.invstatus, plh.uom, - plh.qty, prv.adjreason,
        prv.lasttask, prv.lastuser, 'CONVERT', sysdate);
      insert into invadjactivity
       (whenoccurred, lpid, facility, custid, item, lotnumber,
        inventoryclass, invstatus, uom, adjqty, adjreason,
        tasktype, adjuser, lastuser, lastupdate)
        values
       (prv.whenoccurred, sel.lpid, prv.facility, prv.custid, prv.item, prv.lotnumber,
        prv.inventoryclass, prv.invstatus, prv.uom, prv.qty, prv.adjreason,
        prv.lasttask, prv.lastuser, 'CONVERT', sysdate);
    end if;

    cntOky := cntOky + 1;
    qtyOky := qtyOky + prv.qty;

  <<continue_plh_loop>>
    prv := plh;
  end loop;

end loop;

zut.prt('total count: ' || cntTot || ' total qty: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error qty: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  qty: ' || qtyOky);

zut.prt('end loop . . .');

exception when others then
  zut.prt('when others');
end;
/
--exit;

