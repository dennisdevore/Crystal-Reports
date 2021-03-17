--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
  select *
    from plate
    where facility = 'DTV'
      and custid = '17131'
      and type = 'PA'
      and item in ('DRD420RD','DS2122RD','DS5230RBC','NS2151ND')
      and length(serialnumber) = 9;

out_msg varchar2(255);
out_errorno integer;
cntRows integer;
cntTot integer;
cntErr integer;
cntOky integer;
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

  if sl.item = 'DRD420RD' then
    sl.serialnumber := '66231' || sl.serialnumber;
  elsif sl.item = 'DS2122RD' then
    sl.serialnumber := '65386' || sl.serialnumber;
  elsif sl.item = 'DS5230RBC' then
    sl.serialnumber := '65977' || sl.serialnumber;
  elsif sl.item = 'NS2151ND' then
    sl.serialnumber := '65984' || sl.serialnumber;
  else
    zut.prt('oh no ' || sl.item);
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.quantity;
    goto continue_loop;
  end if;

  zut.prt('processing ' || sl.parentlpid || ' ' || sl.lpid || ' '
          || sl.item || ' ' || sl.serialnumber);
/*
  update plate
     set serialnumber = sl.serialnumber,
         tasktype = 'SN',
         lastuser = 'SERIAL',
         lastupdate = sysdate
   where lpid = sl.lpid;
*/
  cntOky := cntOky + 1;
  qtyOky := qtyOky + sl.quantity;
  commit;
<< continue_loop >>
  null;
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

