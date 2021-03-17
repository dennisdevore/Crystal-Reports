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
         d.qtyrcvd as qtyrcvd,
         d.custid as custid
    from orderdtl d,orderhdr h
    where h.orderid = d.orderid
      and h.shipid = d.shipid
      and h.orderstatus = 'R'
      and h.ordertype in ('R','Q','C')
      and h.statusupdate < sysdate - 30
      and h.statusupdate > to_date('20010201','yyyymmdd')
    order by h.orderid,h.shipid,d.item,d.lotnumber;

cursor curOrderDtlRcpt(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2) is
  select sum(qtyrcvd) as quantity
    from orderdtlrcpt
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)');
rc curOrderDtlRcpt%rowtype;

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
  qtyTot := qtyTot + sl.qtyrcvd;

  rc := null;
  open curOrderDtlRcpt(sl.orderid,sl.shipid,sl.item,sl.lotnumber);
  fetch curOrderDtlRcpt into rc;
  close curOrderDtlRcpt;

  if sl.qtyrcvd != nvl(rc.quantity,0) then
    zut.prt(sl.custid || ' ' || sl.orderid || '-' || sl.shipid || ' ' ||
            sl.item || ' ' || sl.lotnumber || ' ' ||
            sl.qtyrcvd || ' ' || nvl(rc.quantity,0) );
    cntErr := cntErr + 1;
    qtyErr := qtyErr + sl.qtyrcvd;
/*
    if updflag = 'Y' then
           update shippingplate
                   set status = 'SH'
       where orderid = sl.orderid
                   and shipid = sl.shipid
                   and status != 'SH';
    end if;
*/
  else
    cntOky := cntOky + 1;
    qtyOky := qtyOky + sl.qtyrcvd;
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
--exit;
