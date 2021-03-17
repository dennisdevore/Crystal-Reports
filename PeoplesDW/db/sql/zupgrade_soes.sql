--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
  select orderid,
         shipid,
         hdrpassthruchar07 as oldcode,
         qtyorder
    from orderhdr
   where fromfacility = 'HPL'
     and custid = 'HP'
     and ordertype = 'O'
     and hdrpassthruchar07 in ('F06','F09','F11')
     and orderstatus < '9'
     and entrydate < to_date('200008082130', 'yyyymmddhh24mi')
   order by orderid, shipid;

out_msg varchar2(255);
out_errorno integer;
cntTot integer;
cntErr integer;
cntOky integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;
cntRows integer;
newcode varchar2(3);

begin

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

zut.prt('order upgrade. . .');

for sl in curSelect
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.qtyorder;

  if sl.oldcode = 'F11' then
    newcode := 'F06';
  else
    newcode := 'F01';
  end if;

  zut.prt('upgrading ' || sl.orderid || ' ' || sl.shipid ||
    ' from ' || sl.oldcode || ' to ' || newcode);

  update orderhdr
     set priority = '0',
         hdrpassthruchar07 = newcode,
         hdrpassthruchar13 = sl.oldcode || 'to' || newcode,
         lastuser = 'UPGRADE',
         lastupdate = sysdate
   where orderid = sl.orderid
     and shipid = sl.shipid;

  update multishiphdr
     set carriercode = newcode
   where orderid = sl.orderid
     and shipid = sl.shipid;

  update tasks
     set priority = '2'
   where priority != '0'
     and orderid = sl.orderid
     and shipid = sl.shipid;
     
  cntRows := 1;
  if cntRows != 0 then
    cntOky := cntOky + 1;
    qtyOky := qtyOky + sl.qtyOrder;
    commit;
    zut.prt('committed');
  else
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.qtyOrder;
  end if;

end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

zut.prt('end upgrade . . .');

exception when others then
  zut.prt('when others');
end;
/
exit;

