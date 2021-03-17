--
-- $Id$
--
set serveroutput on;

declare
cursor curSelect is
  select orderid,
         shipid,
         qtyorder
    from orderhdr
   where fromfacility = 'HPL'
     and custid = 'HP'
     and ordertype = 'O'
     and hdrpassthruchar07 != 'F11'
     and orderstatus < '9'
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

  zut.prt('processing ' || sl.orderid || ' ' || sl.shipid);

  update orderhdr
     set priority = '0'
   where orderid = sl.orderid
     and shipid = sl.shipid
	  and priority != 'E';

  update tasks
     set priority = '2'
   where priority not in ('0','1','2','9')
     and (orderid = sl.orderid and
          shipid = sl.shipid);
  cntRows := sql%rowcount;
/*
  select count(1)
    into cntRows
    from tasks
   where priority != '0'
     and (orderid = sl.orderid and
          shipid = sl.shipid);
*/
  if cntRows != 0 then
    cntOky := cntOky + 1;
    qtyOky := qtyOky + cntRows;
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
