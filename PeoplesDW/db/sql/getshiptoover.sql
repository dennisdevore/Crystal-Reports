--
-- $Id$
--
set serveroutput on;

declare

out_movement_code varchar2(255);
out_special_stock varchar2(255);
out_errorno integer;

begin

zmi3.check_for_shipto_override('HP','6548',
  out_movement_code,out_special_stock);
zut.prt('out_movement_code:  >' || out_movement_code || '<');
zut.prt('out_special_stock:  >' || out_special_stock || '<');

zmi3.check_for_shipto_override('HP','65481',
  out_movement_code,out_special_stock);
zut.prt('out_movement_code:  >' || out_movement_code || '<');
zut.prt('out_special_stock:  >' || out_special_stock || '<');

zmi3.check_for_shipto_override('XX','6548',
  out_movement_code,out_special_stock);
zut.prt('out_movement_code:  >' || out_movement_code || '<');
zut.prt('out_special_stock:  >' || out_special_stock || '<');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
