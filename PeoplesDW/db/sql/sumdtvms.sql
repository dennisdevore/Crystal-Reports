--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
  select *
    from orderhdr
   where custid = '17131'
     and ordertype in ('V','O')
     and nvl(loadno,0) = 0
     and carrier = 'FEDX';

out_msg varchar2(255);
out_errorno integer;
cntRows integer;
cntTot integer;
cntErr integer;
cntOky integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;
qtyMax integer;
qtyMin integer;
qtyAvg integer;
cntOrder integer;
cntItems integer;
qty100 integer;
qty500 integer;
qty1000 integer;


begin

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;
qtyMax := 0;
qtyMin := 99999;
qtyAvg := 0;
cntOrder := 0;
cntItems := 0;
qty100 := 0;
qty500 := 0;
qty1000 := 0;

zut.prt('begin loop. . .');

for sl in curSelect
loop

  cntOrder := cntOrder + 1;
  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.qtyorder;

  begin
    select count(1)
      into cntRows
      from multishipdtl
     where orderid = sl.orderid
       and shipid = sl.shipid;
  exception when others then
    cntRows := 0;
  end;

  cntItems := cntItems + cntRows;
  if cntRows > qtyMax then
    qtyMax := cntRows;
  end if;
  if cntRows < qtyMin then
    qtyMin := cntRows;
  end if;
  if cntRows < 101 then
    qty100 := qty100 + 1;
  elsif cntRows < 501 then
    qty500 := qty500 + 1;
  else
    zut.prt(sl.orderid || '-' || sl.shipid || substr(dt(sl.lastupdate),1,17));
    qty1000 := qty1000 + 1;
  end if;
end loop;

zut.prt('order count: ' || cntOrder);
zut.prt('items count: ' || cntItems);
zut.prt('max:         ' || qtyMax);
zut.prt('min:         ' || qtyMin);
qtyAvg := cntItems / cntOrder;
zut.prt('avg:         ' || qtyAvg);
zut.prt('qty100 ' || qty100);
zut.prt('qty500 ' || qty500);
zut.prt('qty1000 ' || qty1000);
zut.prt('end loop . . .');

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;
/
--exit;
