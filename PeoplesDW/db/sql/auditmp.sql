--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
select lpid,
       status,
       invstatus,
       quantity,
       weight
  from plate
 where type = 'MP'
 order by lpid;

cursor curChildLips(in_lpid varchar2) is
select count(1) as count,
       sum(nvl(quantity,0)) as quantity,
       sum(nvl(weight,0)) as weight
  from plate
 where parentlpid = in_lpid;
cl curChildLips%rowtype;

out_msg varchar2(255);
out_errorno integer;
cntTot integer;
cntErr integer;
cntOky integer;
cntRows integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;
updflag varchar2(1);

begin

updflag := Upper('N');

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

  cl.count := 0;
  cl.quantity := 0;
  cl.weight := 0;
  open curChildLiPs(sl.lpid);
  fetch curChildLips into cl;
  close curChildLips;

  if cl.count = 0 then
    zut.prt('processing ' || sl.lpid || ' ' || sl.status || ' ' ||
      sl.invstatus || ' ' || sl.quantity || ' ' || sl.weight);
    zut.prt('no children ' || cl.count || ' ' || cl.quantity || ' ' ||
     cl.weight);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.quantity;
    if updflag = 'Y' then

      if sl.quantity != 0 then
        update plate
           set quantity = 0,
               lasttask = 'AJ',
               lastuser = 'ADJUST'
         where lpid = sl.lpid;
      end if;

      insert into deletedplate
        select *
          from plate
         where lpid = sl.lpid;

      delete from plate
       where lpid = sl.lpid;

      commit;

    end if;
    goto continue_loop;
  end if;

  if (cl.quantity = sl.quantity) and
     (cl.weight = sl.weight) then
    cntOky := cntOky + 1;
    qtyOky := qtyOky + sl.quantity;
    goto continue_loop;
  end if;
  if cl.weight != sl.weight then
    zut.prt('processing ' || sl.lpid || ' ' || sl.status || ' ' ||
      sl.invstatus || ' ' || sl.quantity || ' ' || sl.weight);
    zut.prt('weight ' || cl.count || ' ' || cl.quantity || ' ' ||
     cl.weight);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.quantity;
    goto continue_loop;
  end if;
  if cl.quantity != sl.quantity then
    zut.prt('processing ' || sl.lpid || ' ' || sl.status || ' ' ||
      sl.invstatus || ' ' || sl.quantity || ' ' || sl.weight);
    zut.prt('quantity ' || cl.count || ' ' || cl.quantity || ' ' ||
     cl.weight);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.quantity;
  end if;

<<continue_loop>>
  null;
end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

zut.prt('end loop . . .');

exception when others then
  zut.prt('when others');
end;
/
exit;

