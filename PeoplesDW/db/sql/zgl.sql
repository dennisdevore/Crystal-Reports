--
-- $Id$
--
set serveroutput on;
declare
	l_err number := 0;
	l_msg varchar2(255) := null;
begin
	zgl.gen_line_item_pick('001', 2433, 2, 'K1', '(none)', 0, '(none)', '(none)', 'SUP', 'Y',
   		l_err, l_msg);
	dbms_output.put_line('err <'||l_err||'>');
	dbms_output.put_line('msg <'||l_msg||'>');
end;
/
exit;
