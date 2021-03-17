create or replace trigger worldshipdtl_ai
--
-- $Id$
--
after insert
on worldshipdtl
for each row
declare
   strShipDateTime varchar2(14);
   strPackListShipDateTime varchar2(14);
   workdate date;
   errmsg varchar2(100);

begin

  begin
    workdate := to_date(:new.shipdatetime, 'yyyymmddhh24miss');
    strShipDateTime := :new.shipdatetime;
  exception when others then
    strShipDateTime := to_char(sysdate, 'yyyymmddhh24miss');
  end;

  begin
    workdate := to_date(:new.packlistshipdatetime, 'yyyymmddhh24miss');
    strPackListShipDateTime := :new.packlistshipdatetime;
  exception when others then
    strPackListShipDateTime := to_char(sysdate, 'yyyymmddhh24miss');
  end;

  update multishipdtl
     set actweight = :new.actweight,
         trackid = :new.trackid,
         status = 'SHIPPED',
         shipdatetime = strShipDateTime,
         carrierused = :new.carrierused,
         reason = :new.reason,
         cost = decode(nvl(:new.charcost, 'X'), 'X', :new.cost,to_number(:new.charcost,'99999999.99')),
         termid = nvl(:new.termid,'UPS1'),
         satdeliveryused = :new.satdeliveryused,
         packlistshipdatetime = strPackListShipDateTime,
         rmatrackingno = :new.rmatrackingno,
         actualcarrier = :new.actualcarrier
   where cartonid = :new.cartonid;

end;
/

--exit;
