--
-- $Id$
--
set serveroutput on;

declare

cursor curInvAdj is
  select rowid,invadjactivity.*
    from invadjactivity
   where custid = 'HP'
     and lpid in ('000000000016281','000000000016282');
     
out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);
in_adjrowid varchar2(18);

begin

for aj in curInvAdj
loop
  in_adjrowid := aj.rowid;
  zmi3.validate_interface(in_adjrowid,out_movement_code,out_errorno,out_msg);
  zut.prt(aj.rowid || ' ' ||
          aj.lpid || ' ' ||
          aj.item || ' ' ||
          aj.invstatus || '/' ||
          aj.inventoryclass || ' ' ||
          aj.newinvstatus || '/' ||
          aj.newinventoryclass || ' ' ||
          aj.adjreason || ' ' ||
          aj.adjqty);
  zut.prt('out_movement_code:  [' || out_movement_code || ']');
  zut.prt('out_errorno:  [' || out_errorno || ']');
  zut.prt('out_msg:  [' || out_msg || ']');
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
