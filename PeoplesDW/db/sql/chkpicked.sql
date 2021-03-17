--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
select *
  from plate
 where status = 'P'
   and exists
   (select *
      from shippingplate
     where plate.lpid = shippingplate.fromlpid
       and shippingplate.status = 'SH'
       and (exists
       (select *
          from loads
         where shippingplate.loadno = loads.loadno
           and loads.loadstatus = '9')
        or  exists
                  (select *
                          from orderhdr
                          where shippingplate.orderid = orderhdr.orderid
                                 and shippingplate.shipid = orderhdr.shipid
                                 and orderhdr.orderstatus = '9')))
   and not exists
   (select *
      from shippingplate
     where plate.lpid = shippingplate.fromlpid
       and shippingplate.status != 'SH');

cursor curSelectMultis is
  select *
    from plate p1
   where type = 'MP'
     and status = 'P'
     and not exists
         (select * from plate p2
           where p2.parentlpid = p1.lpid)
     and lastupdate < sysdate - 1;

cursor curSelectChildren is
  select *
    from plate p1
   where type = 'PA'
     and status = 'P'
     and parentlpid is not null
     and exists
         (select * from deletedplate dp
           where dp.lpid = p1.parentlpid)
     and not exists
         (select * from plate p2
           where p2.lpid = p1.parentlpid);

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
parentqty plate.quantity%type;

begin

updflag := upper('&1');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

for sl in curSelect
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.quantity;

  zut.prt('processing ' || sl.lpid || ' ' ||
         substr(dt(sl.lastupdate),1,17));

  out_msg := null;
  if updflag = 'Y' then
    zlp.plate_to_deletedplate(sl.lpid,'ZDEL','AJ',out_msg);
    if out_msg is not null then
      zut.prt(out_msg);
    end if;
  end if;

  if out_msg is null then
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

zut.prt('begin multi scan. . .');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

for sl in curSelectMultis
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.quantity;

  zut.prt('processing ' || sl.lpid || ' ' ||
         substr(dt(sl.lastupdate),1,17));

  out_msg := null;
  if updflag = 'Y' then
    zlp.plate_to_deletedplate(sl.lpid,'ZDEL','AJ',out_msg);
    if out_msg is not null then
      zut.prt(out_msg);
    end if;
  end if;

  if out_msg is null then
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

zut.prt('begin children scan. . .');

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

for sl in curSelectChildren
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.quantity;

  zut.prt('processing ' || sl.lpid || ' ' ||
         substr(dt(sl.lastupdate),1,17));

  out_msg := null;
  if updflag = 'Y' then
    zlp.plate_to_deletedplate(sl.lpid,'ZDEL','AJ',out_msg);
    if out_msg is not null then
      zut.prt(out_msg);
    end if;
  end if;

  if out_msg is null then
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
  zut.prt(sqlerrm);
end;
/
exit;

