--
-- $Id$
--
set serveroutput on;

declare
cntStatus integer;
cntAttempts integer;
strMsg varchar2(255);

begin


pkg_manage_users.usp_get_user_login_attempts
('CJO',cntAttempts,cntStatus,strMsg);

zut.prt('attempts ' || cntAttempts);
zut.prt('status ' || cntStatus);
zut.prt('msg ' || strMsg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
