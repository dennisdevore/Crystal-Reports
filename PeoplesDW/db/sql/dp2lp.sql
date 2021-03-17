--
-- $Id$
--
set serveroutput on;

declare

in_orderid number(7);
in_shipid number(2);
in_parentlpid varchar2(15);

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

in_parentlpid := '&parentlpid';

cntTot := 0;
cntOky := 0;
cntErr := 0;
qtyTot := 0;
qtyOky := 0;
qtyErr := 0;

insert into plate
      select * from deletedplate
       where parentlpid = in_parentlpid;
delete from deletedplate
     where parentlpid = in_parentlpid;
update plate
   set status = 'A',
       location = 'LANE 3',
       destfacility = null,
       destlocation = null,
       lastuser = 'ZADJ',
       lastupdate = sysdate
 where parentlpid = in_parentlpid
   and type = 'PA';

    update plate
       set status = 'A',
           location = 'LANE 3',
           destfacility = null,
           destlocation = null,
           lastuser = 'ZADJ',
           lastupdate = sysdate
     where lpid = in_parentlpid;


zut.prt('Tot count: ' || cntTot || ' quantity: ' || qtyTot);
zut.prt('Oky count: ' || cntOky || ' quantity: ' || qtyOky);
zut.prt('Err count: ' || cntErr || ' quantity: ' || qtyErr);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
