--
-- $Id$
--
set serveroutput on;
declare

cursor curSubLips is
  select parentlpid,
         lpid,
			custid,
         item,
         inventoryclass,
         invstatus,
         lotnumber,
         location,
         quantity,
         facility
    from plate
   where facility = 'HPL'
     and custid = 'HP'
     and invstatus = 'AV'
     and inventoryclass = 'RG'
     and location = 'SR001'
     and status = 'A'
   order by item;

out_msg varchar2(255);
out_errorno integer;
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

zut.prt('begin lip adjustment to IP inventoryclass. . .');

for ia in curSubLips
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + ia.quantity;

  zut.prt('processing lip ' || ia.lpid || ' ' || ia.item
    || ' ' || ia.quantity);

  zia.inventory_adjustment(
    ia.lpid,
    ia.custid,
    ia.item,
    'IP',
    ia.invstatus,
    ia.lotnumber,
    ia.location,
    ia.quantity,
    ia.custid,
    ia.item,
    ia.inventoryclass,
    ia.invstatus,
    ia.lotnumber,
    ia.location,
    ia.quantity,
    ia.facility,
    'OI', -- adjustment code
    'ZADJ1',
    'IA',   -- tasktype
    out_errorno,
    out_msg);

  zut.prt('out_msg: ' || out_msg);
  zut.prt('out_errorno: ' || out_errorno);
  if substr(out_msg,1,4) = 'OKAY' then
    cntOky := cntOky + 1;
    qtyOky := qtyOky + ia.quantity;
    commit;
    zut.prt('committed');
  else
    cntErr := cntErr + 1;
    qtyErr := qtyErr + ia.quantity;
  end if;

end loop;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

zut.prt('end lip adjustment . . .');

exception when others then
  zut.prt('when others');
end;
/
exit;
