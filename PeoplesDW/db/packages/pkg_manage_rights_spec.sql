--
-- $Id$
--
create or replace package pkg_manage_rights is

procedure usp_insert_user_rights(
  users_id VARCHAR2,
  rights_id NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

procedure usp_delete_user_rights(
  users_id VARCHAR2,
  label_type NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

procedure usp_update_user_type(
  name_id VARCHAR2,
  type_id NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

procedure usp_get_user_type(
  users_id VARCHAR2,
  type_id OUT NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

end pkg_manage_rights;
/
exit;