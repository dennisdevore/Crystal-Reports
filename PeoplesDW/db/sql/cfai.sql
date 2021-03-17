--
-- $Id$
--
set serveroutput on;

declare

cursor curInvAdj is
  select rowid,invadjactivity.*
    from invadjactivity
   where custid = 'HP'
     and lpid in ('000000000016203','000000000016206')
   order by whenoccurred desc;

out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);
in_adjrowid varchar2(18);

begin

out_msg := '';
out_errorno := 0;
out_movement_code := '';

for aj in curInvAdj
loop
  zmi3.validate_interface(aj.rowid,out_movement_code,out_errorno,out_msg);
  zut.prt('out_movement_code:  [' || out_movement_code || ']');
  zut.prt('out_errorno:  [' || out_errorno || ']');
  zut.prt('out_msg:  [' || out_msg || ']');
  if out_errorno = 0 then
    zim6.check_for_adj_interface(aj.rowid,out_errorno,out_msg);
    zut.prt('out_errorno:  [' || out_errorno || ']');
    zut.prt('out_msg:  [' || out_msg || ']');
  end if;
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
