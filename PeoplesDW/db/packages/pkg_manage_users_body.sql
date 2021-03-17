CREATE OR REPLACE package body pkg_manage_users as
--
-- $Id$
--

procedure usp_get_user_login_attempts(
  nameid VARCHAR2,
  no_of_attempts OUT NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is

username VARCHAR2(12);

begin

  username := nameid;

  begin
    select nvl(login_attempts, 0) + 1 into no_of_attempts from tbl_user_profile
         where upper(nameid) = upper(username);

    if (no_of_attempts > 3) then
      update tbl_user_profile set user_status = 0
           where upper(nameid) = upper(username);
    end if;

    exception WHEN OTHERS THEN
      return_status := 0;
      return_msg := sqlerrm;
      no_of_attempts := -1;
      return;
  end;

  begin
    update tbl_user_profile set login_attempts = no_of_attempts
           where upper(nameid) = upper(username);

    exception WHEN OTHERS THEN
      return_status := 0;
      return_msg := sqlerrm;
      no_of_attempts := -1;
      return;
  end;

  return_msg := 'OKAY';
  return_status := 1;

  exception WHEN OTHERS THEN
    return_status := 0;
    return_msg := sqlerrm;
    no_of_attempts := -1;

end usp_get_user_login_attempts;

----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

procedure usp_update_reset_attempts(
  nameid VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is

username VARCHAR2(12);

begin

  username := nameid;

  update tbl_user_profile set login_attempts = 0, user_status = 1
         where upper(nameid) = upper(username);

  return_msg := 'OKAY';
  return_status := 1;

  exception WHEN OTHERS THEN
    return_status := 0;
    return_msg := sqlerrm;

end usp_update_reset_attempts;

procedure usp_delete_user(
	name_id varchar2,
	return_status out number,
	return_msg out varchar2
) is

begin

if name_id <> 'Sitemanager' then

	delete from tbl_user_facilities
		   where nameid = name_id;
	delete from tbl_user_permissions
		   where nameid = name_id;
	delete from tbl_user_preferences
		   where nameid = name_id; 
	delete from tbl_user_profile
		   where nameid = name_id;

    return_msg := 'OKAY';
  	return_status := 1;
else
	return_msg := 'Sitemanager Required';
  	return_status := 2;
end if;

	exception WHEN OTHERS THEN
    return_status := 0;
    return_msg := sqlerrm;


end usp_delete_user;

end pkg_manage_users;
/
exit;

