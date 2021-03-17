--
-- $Id$
--
set serveroutput on;

declare

out_rma varchar2(255);

begin

zmi3.get_lips_rma('000000000000100',out_rma);
zut.prt('rma is >' || out_rma  || '<');

zmi3.get_lips_rma('000000000000010',out_rma);
zut.prt('rma is >' || out_rma  || '<');


exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
