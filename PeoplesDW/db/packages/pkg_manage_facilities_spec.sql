--
-- $Id$
--
create or replace package pkg_manage_facilities is

procedure usp_insert_user_facilities(
  username VARCHAR2,
  facility VARCHAR2,
  last_user VARCHAR2, 
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

procedure usp_delete_user_facilities(
  username VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

end pkg_manage_facilities;
/
exit;