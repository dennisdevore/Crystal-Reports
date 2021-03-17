--
-- $Id$
--
set serveroutput on;
declare
out_msg varchar2(255);
out_errorno integer;

begin
out_msg := '';
out_errorno  := 0;
zut.prt('calling begin ship sum...');
zimp.begin_ship_sum
('HP'
,'19990701000000'
,'20000709120000'
,out_errorno
,out_msg
);
zut.prt(out_errorno);
zut.prt(out_msg);

end;
/
--exit;

