--
-- $Id$
--
set serveroutput on;
declare
cursor curOrderLabor is
  select orderid,
         shipid,
         item,
         category,
         zoneid,
         uom,
         qty,
         rowid
    from orderlabor
   where custid is null;

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select nvl(fromfacility,tofacility) as facility,
         custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

totcount integer;
updcount integer;

begin

totcount := 0;
updcount := 0;

for x in curOrderLabor
loop
  totcount := totcount + 1;
  open curOrderHdr(x.orderid, x.shipid);
  fetch curOrderHdr into oh;
  if curOrderHdr%notfound then
    zut.prt('Order not found: ' || x.orderid || ' ' || x.shipid);
    close curOrderHdr;
    goto continue_loop;
  end if;
  close curOrderHdr;
  update orderlabor
     set custid = oh.custid,
         facility = oh.facility,
         staffhrs = zlb.staff_hours(oh.facility,oh.custid,
                    x.item,x.category,x.zoneid,x.uom,x.qty)
   where rowid = x.rowid;
  updcount := updcount + 1;
<<continue_loop>>
  if mod(updcount,1000) = 0 then
    zut.prt('committing . . . ' || updcount);
    commit;
  end if;
end loop;

commit;

zut.prt('total processed: ' || totcount);
zut.prt('total updated:   ' || updcount);

end;
/
--exit;