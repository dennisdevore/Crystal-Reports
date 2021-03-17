--
-- $Id$
--
create or replace package pkg_manage_users is
                        
procedure usp_get_user_login_attempts(  
  nameid VARCHAR2,
  no_of_attempts OUT NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
);

procedure usp_update_reset_attempts(  
  nameid VARCHAR2,  
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
);

procedure usp_delete_user(
	name_id varchar2,
	return_status out number,
	return_msg out varchar2
);

end pkg_manage_users;
/
exit;
