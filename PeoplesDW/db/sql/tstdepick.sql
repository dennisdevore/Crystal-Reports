--
-- $Id$
--
set serveroutput on
declare
	err varchar2(2);
	msg varchar2(80);
begin

   dbms_output.enable(1000000);

	zdep.depick_item(1732, 0, '000000000022402', 'Y', 'ONE', '1', null,
   		7, 'EA', 'EA', null, null, null, null, 'A0202', '000000000000098',
         'SUP', err, msg);

	zut.prt('err: '||err);
   zut.prt('msg: '||msg);
   rollback;

end;

/
exit;
