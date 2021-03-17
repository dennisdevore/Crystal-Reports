--
-- $Id$
--
set serveroutput on
declare
	err number;
	msg varchar2(80);
begin
   dbms_output.enable(1000000);
	zcm.match_template_parms('Test wave', 2329, 1, err, msg);
	zut.prt('err: '||err);
   zut.prt('msg: '||msg);
end;
/
exit;
