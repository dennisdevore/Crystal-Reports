--
-- $Id$
--
set serveroutput on;

declare

cursor curSelect is
  select d.orderid as orderid,
         d.shipid as shipid,
         d.item as item,
         d.lotnumber as lotnumber,
         d.qtyorder as qtyorder,
         d.qtyship as qtyship,
                        d.custid as custid
    from orderdtl d,orderhdr h
    where h.orderid = d.orderid
      and h.shipid = d.shipid
      and h.orderstatus = '9'
      and h.ordertype = 'O'
                and h.statusupdate < sysdate - 30
    order by h.orderid,h.shipid,d.item,d.lotnumber;

cursor curShippingPlate(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2) is
  select sum(quantity) as quantity
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
     and type in ('F','P')
     and status in ('SH');
sp curShippingPlate%rowtype;

cursor curStaged(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2) is
  select sum(quantity) as quantity
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
     and type in ('F','P','FA')
     and status in ('S','L');
stg curShippingPlate%rowtype;

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

updflag := upper('&1');

zut.prt('begin loop. . .');

for sl in curSelect
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sl.qtyship;

  sp := null;
  open curShippingPlate(sl.orderid,sl.shipid,sl.item,sl.lotnumber);
  fetch curShippingPlate into sp;
  close curShippingPlate;

  stg := null;
  open curStaged(sl.orderid,sl.shipid,sl.item,sl.lotnumber);
  fetch curStaged into stg;
  close curStaged;

  if sl.qtyship != nvl(sp.quantity,0) then
    zut.prt(sl.custid || ' ' || sl.orderid || '-' || sl.shipid || ' ' ||
            sl.item || ' ' || sl.lotnumber || ' ' ||
            sl.qtyship || ' ' || nvl(sp.quantity,0) || ' ' ||
                                nvl(stg.quantity,0));
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.qtyship;
    if updflag = 'Y' then
           update shippingplate
                   set status = 'SH'
       where orderid = sl.orderid
                   and shipid = sl.shipid
                   and status != 'SH';
    end if;
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + sl.qtyship;
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
