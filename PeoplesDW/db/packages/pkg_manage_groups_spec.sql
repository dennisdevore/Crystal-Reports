--
-- $Id$
--
create or replace package pkg_manage_groups is

procedure usp_insert_groups(
  group_name VARCHAR2,
  company_id NUMBER,
  status NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

procedure usp_delete_group(
  groupid NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

);

procedure usp_update_group(
  groupid NUMBER,
  groupname VARCHAR2,
  companyid NUMBER,
  statusid NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
);

end pkg_manage_groups;
/
exit;