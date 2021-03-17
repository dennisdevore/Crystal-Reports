--
-- $Id$
--
declare
   l_errno number;
begin
	dbms_output.enable(1000000);
	l_errno := dbms_lock.release(1234);
   dbms_output.put_line('l_errno: '||l_errno);
end;
/   
