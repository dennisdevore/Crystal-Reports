create or replace package body pkg_manage_facilities as
--
-- $Id$
--

procedure usp_insert_user_facilities(
  username VARCHAR2,
  facility VARCHAR2,
  last_user VARCHAR2,  
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

)is

begin

  insert into tbl_user_facilities(nameid, facility_id, last_user, last_update)
  values(username, facility, last_user, sysdate);
  
  return_status := 1;
  return_msg := 'OK';
  
  exception when others then
    return_status := 0;
    return_msg := sqlerrm;
    
end usp_insert_user_facilities;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------

procedure usp_delete_user_facilities(
  username VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

)is

begin

  delete from tbl_user_facilities where upper(nameid) = upper(username);

  return_status := 1;
  return_msg := 'OK';
  
  exception when others then
    return_status := 0;
    return_msg := sqlerrm;

end usp_delete_user_facilities;

end pkg_manage_facilities;
/
exit;
