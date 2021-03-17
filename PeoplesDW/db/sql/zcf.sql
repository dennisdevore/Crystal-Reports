--
-- $Id$
--
set long 20000
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);
begin

zcf.create_func
('HP','CLASS_TO_COMPANY',out_errorno,out_msg);
zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || out_msg);
end;
/
exit;


