--
-- $Id$
--
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);

begin
out_errorno := 0;
out_msg := '';
zgp.pick_request('COMORD','001','USER1',10,2,null,null,0,
  out_errorno,out_msg);
zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || out_msg);
end;
/
exit;