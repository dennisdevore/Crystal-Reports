--
-- $Id$
--
set serveroutput on;

declare

out_msg varchar2(255);
cartonid varchar2(15);

begin

cartonid := &&cartonid;

zut.prt('stage carton ' || cartonid || ' . . .');

zmn.stage_carton(cartonid,out_msg);

zut.prt('out_msg: ' || out_msg);

zut.prt('end carton stage . . .');

exception when others then
  zut.prt('when others');
end;
/
commit;
exit;
