set serveroutput on;

declare

cursor curExpiredPlates is
  select lpid,
         custid,
         item,
         nvl(inventoryclass,'RG') as inventoryclass,
         invstatus,
         lotnumber,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         location,
         expirationdate,
         manufacturedate,
         anvdate,
         unitofmeasure,
         quantity as qty,
         facility,
         nvl(loadno,0) as loadno,
         nvl(stopno,0) as stopno,
         nvl(shipno,0) as shipno,
         orderid,
         shipid,
         type,
         parentlpid,
         weight,
         controlnumber,
         adjreason
    from plate
   where trunc(expirationdate) < trunc(sysdate)
     and type = 'PA'
     and invstatus = 'AV';

out_msg varchar2(255);
out_errorno integer;
out_adjrowid1 varchar2(255);
out_adjrowid2 varchar2(255);
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

for pl in curExpiredPlates
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + pl.qty;

  zia.inventory_adjustment
  (pl.lpid
  ,pl.custid
  ,pl.item
  ,pl.inventoryclass
  ,'EX'
  ,pl.lotnumber
  ,pl.serialnumber
  ,pl.useritem1
  ,pl.useritem2
  ,pl.useritem3
  ,pl.location
  ,pl.expirationdate
  ,pl.qty
  ,pl.custid
  ,pl.item
  ,pl.inventoryclass
  ,pl.invstatus
  ,pl.lotnumber
  ,pl.serialnumber
  ,pl.useritem1
  ,pl.useritem2
  ,pl.useritem3
  ,pl.location
  ,pl.expirationdate
  ,pl.qty
  ,pl.facility
  ,'EX'
  ,'EXPRUN'
  ,'EP'
  ,pl.weight
  ,pl.weight
  ,pl.manufacturedate
  ,pl.manufacturedate
  ,pl.anvdate
  ,pl.anvdate
  ,out_adjrowid1
  ,out_adjrowid2
  ,out_errorno
  ,out_msg);

  if out_errorno != 0 then
    rollback;
    cntErr := cntErr + 1;
    qtyErr := qtyErr + pl.qty;
    zut.prt(out_msg);
  else
    commit;
    cntOky := cntOky + 1;
    qtyOky := qtyOky + pl.qty;
    if out_adjrowid1 is not null then
       zim6.check_for_adj_interface(out_adjrowid1,out_errorno,out_msg);
    end if;
    if out_adjrowid2 is not null then
       zim6.check_for_adj_interface(out_adjrowid2,out_errorno,out_msg);
    end if;
  end if;

end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;
/
spool expiration_update.log

set pagesize 63
ttitle left 'Expired Merchandise Report' right curdate skip 2
column dtfmt format a8 NEW_VALUE curdate NOPRINT
column CUSTOMER format a14 truncated
break on CUSTOMER skip 2
select
customer.name "CUSTOMER",
plate.item "ITEM",
plate.lpid "LP#",
plate.quantity "QTY",
plate.unitofmeasure "UNITOFMEASURE",
TO_CHAR (sysdate, 'DD-MON-YY') dtfmt
 from customer, plate
where plate.custid = customer.custid(+)
  and trunc(plate.lastupdate) = trunc(sysdate)
  and plate.invstatus = 'EX'
order by customer.name;
spool out;
quit;


