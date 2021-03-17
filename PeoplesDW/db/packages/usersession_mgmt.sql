create or replace procedure usersession_mgmt
as
	v_status number;
	v_queuename varchar2(7) := 'license';
	l_msg varchar2(256);
   begin
   l_msg := 'REPORT' || chr(9);
   v_status := zqm.send(v_queuename,'MSG',l_msg,1,'LICENSE');
   commit;
end usersession_mgmt;
/

show errors procedure usersession_mgmt
exit;
