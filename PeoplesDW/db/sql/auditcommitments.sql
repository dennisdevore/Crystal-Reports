--
-- $Id$
--
set serveroutput on;
spool auditcommitments.out

declare
notfound boolean;
totcount integer;
qtycount integer;
dtlcount integer;
ntfcount integer;
okycount integer;
zrocount integer;
updflag varchar2(1);
out_msg varchar2(255);

cursor curCommitmentsAll is
  select nvl(custid,'x') as custid,
         nvl(orderid,0) as orderid,
         nvl(shipid,0) as shipid,
         nvl(orderitem,'x') as orderitem,
         nvl(orderlot,'(none)') as orderlot,
         nvl(sum(qty),0) as qty
    from commitments
   group by custid, orderid, shipid, orderitem, orderlot
   order by custid, orderid, shipid, orderitem, orderlot;

cursor curOrderDtlOne
  (in_orderid number
  ,in_shipid number
  ,in_orderitem varchar2
  ,in_orderlot varchar2) is
  select orderid,
         shipid,
         item,
         nvl(lotnumber,'(none)') as lotnumber,
         nvl(qtycommit,0) as qty
    from orderdtl od
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = in_orderlot
     and linestatus != 'X'
     and exists
         (select *
            from orderhdr oh
           where od.orderid = oh.orderid
             and od.shipid = oh.shipid
             and oh.orderstatus <= '8'
             and oh.orderstatus >= '2');
c1 curOrderDtlOne%rowtype;

cursor curItem(in_custid varchar2, in_item varchar2) is
  select nvl(weight,0) as weight,
         nvl(cube,0) as cube,
         nvl(useramt1,0) as useramt1
    from custitem
   where custid = in_custid
     and item = in_item;
ci curItem%rowtype;

cursor curOrderDtlAll is
  select custid,
         orderid,
         shipid,
         item as orderitem,
         nvl(lotnumber,'(none)') as orderlot,
         nvl(qtycommit,0) as qty
    from orderdtl od
   where qtycommit != 0
     and linestatus != 'X'
     and exists
         (select *
            from orderhdr oh
           where od.orderid = oh.orderid
             and od.shipid = oh.shipid
             and oh.orderstatus <= '8'
             and oh.orderstatus >= '2')
   order by custid, orderid, shipid, item, lotnumber;

cursor curCommitmentsSumOne
  (in_orderid number
  ,in_shipid number
  ,in_orderitem varchar2
  ,in_orderlot varchar2) is
  select nvl(orderid,0) as orderid,
         nvl(shipid,0) as shipid,
         nvl(orderitem,'x') as item,
         nvl(orderlot,'(none)') as orderlot,
         nvl(sum(qty),0) as qty
    from commitments
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = in_orderlot
   group by orderid, shipid, orderitem, orderlot;
p1 curCommitmentsSumOne%rowtype;

begin

updflag := '&&1';

totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;
zrocount := 0;

zut.prt('Comparing commitments to orderdtl...');
for p in curCommitmentsAll
loop
  totcount := totcount + 1;
  open curOrderDtlOne(p.orderid,p.shipid,p.orderitem,p.orderlot);
  fetch curOrderDtlOne into c1;
  if curOrderDtlOne%notfound then
    zut.prt('Orderdtl not found: ');
    zut.prt(p.orderid || ' ' ||
      p.shipid || ' ' ||
      p.orderitem || ' ' ||
      p.orderlot || ' ' ||
      p.qty);
    ntfcount := ntfcount + 1;
    if updflag = 'Y' then
      delete from commitments
       where nvl(orderid,0) = p.orderid
         and nvl(shipid,0) = p.shipid
         and nvl(orderitem,'x') = p.orderitem
         and nvl(orderlot,'(none)') = p.orderlot;
      commit;
    end if;
  else
    if (p.qty = c1.qty) then
     okycount := okycount + 1;
    else
      zut.prt('Qty mismatch: ');
      zut.prt(p.orderid || ' ' ||
        p.shipid || ' ' ||
        p.orderitem || ' ' ||
        p.orderlot || ' ' ||
        ' commitments: ' || p.qty ||
        ' orderdtl: ' || c1.qty);
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        open curItem(p.custid,p.orderitem);
        fetch curItem into ci;
        if curItem%notfound then
          ci.weight := 0;
          ci.cube := 0;
          ci.useramt1 := 0;
        end if;
        close curItem;
        update orderdtl
           set qtycommit = p.qty,
               weightcommit = p.qty * ci.weight,
               cubecommit = p.qty * ci.cube,
               amtcommit = p.qty * zci.item_amt(custid,orderid,shipid,item,lotnumber),
               lastuser = 'Audit',
               lastupdate = sysdate
         where orderid = p.orderid
           and shipid = p.shipid
           and item = p.orderitem
           and nvl(lotnumber,'(none)') = p.orderlot;
        commit;
      end if;
    end if;
    if p.qty = 0 then
      zut.prt('Zero qty on commitments record:');
      zut.prt(p.orderid || ' ' ||
        p.shipid || ' ' ||
        p.orderitem || ' ' ||
        p.orderlot || ' ' ||
        ' commitments: ' || p.qty ||
        ' orderdtl: ' || c1.qty);
      zrocount := zrocount + 1;
      if updflag = 'Y' then
        delete from commitments
         where nvl(orderid,0) = p.orderid
           and nvl(shipid,0) = p.shipid
           and nvl(orderitem,'x') = p.orderitem
           and nvl(orderlot,'(none)') = p.orderlot;
        commit;
      end if;
    end if;
  end if;

  close curOrderDtlOne;

end loop;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('zrocount: ' || zrocount);

totcount := 0;
okycount := 0;
ntfcount := 0;
qtycount := 0;
dtlcount := 0;
zrocount := 0;

zut.prt('Comparing orderdtl to commitments...');
for p in curOrderDtlAll
loop
  totcount := totcount + 1;
  open curCommitmentsSumOne(p.orderid,p.shipid,p.orderitem,p.orderlot);
  fetch curCommitmentsSumOne into p1;
  if curCommitmentsSumOne%notfound then
    zut.prt('Commitment not found: ');
    zut.prt(p.orderid || ' ' ||
      p.shipid || ' ' ||
      p.orderitem || ' ' ||
      p.orderlot || ' ' ||
      p.qty);
    ntfcount := ntfcount + 1;
    if updflag = 'Y' then
      update orderdtl
         set qtycommit = 0,
             weightcommit = 0,
             cubecommit = 0,
             amtcommit = 0,
             lastuser = 'Audit',
             lastupdate = sysdate
       where orderid = p.orderid
         and shipid = p.shipid
         and item = p.orderitem
         and nvl(lotnumber,'(none)') = p.orderlot;
      commit;
    end if;
  else
    if (p.qty = p1.qty) then
     okycount := okycount + 1;
    else
      zut.prt('Qty mismatch: ');
      zut.prt(p.orderid || ' ' ||
        p.shipid || ' ' ||
        p.orderitem || ' ' ||
        p.orderlot || ' ' ||
        ' orderdtl: ' || p.qty ||
        ' commitments: ' || p1.qty);
      qtycount := qtycount + 1;
      if updflag = 'Y' then
        open curItem(p.custid,p.orderitem);
        fetch curItem into ci;
        if curItem%notfound then
          ci.weight := 0;
          ci.cube := 0;
          ci.useramt1 := 0;
        end if;
        close curItem;
        update orderdtl
           set qtycommit = p1.qty,
               weightcommit = p1.qty * ci.weight,
               cubecommit = p1.qty * ci.cube,
               amtcommit = p1.qty * zci.item_amt(custid,orderid,shipid,item,lotnumber),
               lastuser = 'Audit',
               lastupdate = sysdate
         where orderid = p.orderid
           and shipid = p.shipid
           and item = p.orderitem
           and nvl(lotnumber,'(none)') = p.orderlot;
        commit;
      end if;
    end if;
  end if;

  close curCommitmentsSumOne;

end loop;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('ntfcount: ' || ntfcount);
zut.prt('qtycount: ' || qtycount);
zut.prt('zrocount: ' || zrocount);

zut.prt('end of commitments/orderdtl audit');

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;
