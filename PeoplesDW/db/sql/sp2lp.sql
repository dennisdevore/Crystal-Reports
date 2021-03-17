--
-- $Id$
--
set serveroutput on;

declare

in_orderid number(7);
in_shipid number(2);

cursor curShippingPlate is
  select *
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and type in ('P','F')
     and status != 'U';

cursor curPlate(in_lpid varchar2) is
  select *
    from plate
   where lpid = in_lpid;
pl curPlate%rowtype;

cursor curDeletedPlate(in_lpid varchar2) is
  select *
    from deletedplate
   where lpid = in_lpid;

cntTot integer;
cntOky integer;
cntErr integer;
qtyTot integer;
qtyOky integer;
qtyErr integer;
begin

in_orderid := &orderid;
in_shipid := &shipid;
cntTot := 0;
cntOky := 0;
cntErr := 0;
qtyTot := 0;
qtyOky := 0;
qtyErr := 0;

zut.prt('processing order ' || in_orderid || '-' || in_shipid);

for sp in curShippingPlate
loop

  cntTot := cntTot + 1;
  qtyTot := qtyTot + sp.quantity;

  zut.prt('processing shipping lip ' || sp.lpid || ' ' || sp.item || ' ' || sp.quantity
    || ' ' || sp.fromlpid);

  pl := null;
  open curPlate(sp.fromlpid);
  fetch curPlate into pl;
  close curPlate;
  if pl.lpid is null then
    open curDeletedPlate(sp.fromlpid);
    fetch curDeletedPlate into pl;
    close curDeletedPlate;
    if pl.lpid is null then
      cntErr := cntErr + 1;
      qtyErr := qtyErr + sp.quantity;
      zut.prt('Plate info not found: ' || sp.fromlpid);
      goto continue_sp_loop;
    end if;
    insert into plate
      select * from deletedplate
       where lpid = pl.lpid;
    delete from deletedplate
     where lpid = pl.lpid;
  end if;

  update plate
     set status = 'A',
         location = 'LANE 3',
         destfacility = null,
         destlocation = null,
         lastuser = 'ZADJ',
         lastupdate = sysdate
   where lpid = pl.lpid;

  delete from shippingplate
   where lpid = sp.lpid;

  if pl.parentlpid is not null then
    update plate
       set status = 'A',
           location = 'LANE 3',
           destfacility = null,
           destlocation = null,
           lastuser = 'ZADJ',
           lastupdate = sysdate
     where lpid = pl.parentlpid;
    if sql%rowcount = 0 then
      zut.prt('parent not found ' || pl.parentlpid);
    end if;
  end if;

  cntOky := cntOky + 1;
  qtyOky := qtyOky + sp.quantity;
<< continue_sp_loop >>
  null;
end loop;

zut.prt('Tot count: ' || cntTot || ' quantity: ' || qtyTot);
zut.prt('Oky count: ' || cntOky || ' quantity: ' || qtyOky);
zut.prt('Err count: ' || cntErr || ' quantity: ' || qtyErr);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
