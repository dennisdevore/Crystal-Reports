--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
select lpid, quantity
  from plate
 where status = 'P'
   and exists
   (select *
      from shippingplate
     where plate.lpid = shippingplate.fromlpid
       and shippingplate.status = 'SH'
       and exists
       (select *
          from loads
         where shippingplate.loadno = loads.loadno
           and loads.loadstatus = '9'))
 order by lpid;

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

for sl in curSelect
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.quantity;

  zut.prt('processing ' || sl.lpid);

  if sl.quantity != 0 then
    update plate
       set quantity = 0,
           lasttask = 'LC'
     where lpid = sl.lpid;
  end if;

  insert into deletedplate
    select *
      from plate
     where lpid = sl.lpid;

  delete from plate
   where lpid = sl.lpid;

  if sql%rowcount = 1 then
    cntOky := cntOky + 1;
    qtyOky := qtyOky + sl.quantity;
    commit;
    zut.prt('committed');
  else
    rollback;
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.quantity;
    zut.prt('rolledback-->' || out_msg);
  end if;

end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

zut.prt('end loop . . .');

exception when others then
  zut.prt('when others');
end;
/
--exit;

