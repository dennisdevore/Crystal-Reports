CREATE OR REPLACE package body pkg_manage_groups as
--
-- $Id$
--

procedure usp_insert_groups(
  group_name VARCHAR2,
  company_id NUMBER,
  status NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

)is

new_id NUMBER;

begin

  begin
    select nvl(max(group_id),0) + 1 into new_id from tbl_groups;
    exception when others then
      return_status := 0;
      return_msg := sqlerrm;
      return;
  end;

  insert into tbl_groups(group_id, group_name, company_id, status)
         values(new_id, group_name, company_id, status);

  return_status := new_id;
  return_msg := 'OK';

exception when others then
  return_status := 0;
  return_msg := sqlerrm;

end usp_insert_groups;

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

procedure usp_delete_group(
  groupid NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

) is

userCnt number;

begin

  select count(1) into userCnt from tbl_user_profile
  		 where group_id = groupid;

  if userCnt = 0 then

	   	delete from tbl_groups
			   where group_id = groupid;

		return_status := 1;
		return_msg := 'OKAY';

	else
		return_status := 2;
   		return_msg := 'INUSE';
   end if;


exception when others then
  return_status := 0;
  return_msg := sqlerrm;

end usp_delete_group;

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

procedure usp_update_group(
  groupid NUMBER,
  groupname VARCHAR2,
  companyid NUMBER,
  statusid NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
)is

begin

  update tbl_groups set group_name = groupname, company_id = companyid, status = statusid where group_id = groupid;

  return_status := 1;
  return_msg := 'OK';

exception when others then
  return_status := 0;
  return_msg := sqlerrm;

end usp_update_group;

end pkg_manage_groups;
/
exit;
