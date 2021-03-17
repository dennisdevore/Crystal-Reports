--
-- $Id$
--
set serveroutput on;

declare
out_setting varchar2(255);

begin


zus.get_setting(
'BRIANB',
'SUPER',
'PlateForm',
'HPL',
out_setting);

zut.prt(out_setting);

exception when others then
  zut.prt('others....');
  zut.prt(sqlerrm);
end;
/

exit;
