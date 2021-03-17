--
-- $Id$
--
declare
   l_errno number;
begin
	dbms_output.enable(1000000);
	l_errno := dbms_lock.request(1234, 2, dbms_lock.maxwait, true);
   dbms_output.put_line('l_errno: '||l_errno);
end;
/   
