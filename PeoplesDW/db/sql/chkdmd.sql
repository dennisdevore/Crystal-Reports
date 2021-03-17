--
-- $Id$
--
set serveroutput on;

declare

out_msg varchar2(255);
out_errorno integer;
out_destlocation varchar2(12);

begin

out_msg := '';
out_errorno := 0;

zid.check_for_active_itemdemand
('888777666555001' -- lpid
,out_destlocation
,out_errorno
,out_msg
);

zut.prt('out_destlocation ' || out_destlocation);
zut.prt('out_errorno ' || out_errorno);
zut.prt('out_msg ' || out_msg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
