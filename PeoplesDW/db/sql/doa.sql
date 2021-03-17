--
-- $Id$
--
set serveroutput on;

declare
out_doa_yn varchar2(255);

begin

zim5.damaged_on_arrival('DM,AV','000000000000001',out_doa_yn);

zut.prt('out_doa_yn is >' || out_doa_yn || '<');

exception when others then
  zut.prt('others...');
  zut.prt(sqlerrm);
end;
/
--exit;
