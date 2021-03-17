--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
  select rowid,commitments.*
    from commitments
    where orderlot is null
      and lotnumber is not null;

out_msg varchar2(255);
out_errorno integer;
cntRows integer;
cntTot integer;
cntErr integer;
cntOky integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;
updflag char(1);

begin

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

zut.prt('begin loop. . .');

for sl in curSelect
loop

  updflag := Upper('&&1');

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.qty;

  zut.prt('processing ' || sl.orderid || '-' || sl.shipid ||
    ' ' || sl.item || ' ' || sl.orderlot || ' ' || sl.lotnumber);
  begin
    select count(1)
      into cntRows
      from commitments
     where orderid = sl.orderid
       and shipid = sl.shipid
       and orderitem = sl.orderitem
       and nvl(orderlot,'(none)') = nvl(sl.orderlot,'(none)')
       and item = sl.item
       and lotnumber is null
       and inventoryclass =  sl.inventoryclass
       and invstatus = sl.invstatus
       and status = sl.status;
    if cntRows = 0 then
      zut.prt('update only');
      if updflag = 'Y' then
        update commitments
           set lotnumber = null
         where rowid = sl.rowid;
        cntOky := cntOky + 1;
        qtyOky := qtyOky + sl.qty;
        commit;
      end if;
    else
      zut.prt('update and delete');
      if updflag = 'Y' then
        update commitments
           set qty = qty + sl.qty
         where orderid = sl.orderid
           and shipid = sl.shipid
           and orderitem = sl.orderitem
           and nvl(orderlot,'(none)') = nvl(sl.orderlot,'(none)')
           and item = sl.item
           and lotnumber is null
           and inventoryclass =  sl.inventoryclass
           and invstatus = sl.invstatus
           and status = sl.status;
        if sql%rowcount = 1 then
          delete from commitments
           where rowid = sl.rowid;
        else
          zut.prt('rolledback');
          rollback;
          cntErr := cntErr + 1;
          qtyErr := qtyErr + sl.qty;
        end if;
      end if;
    end if;
  end;

end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

zut.prt('end loop . . .');

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;
/
exit;

