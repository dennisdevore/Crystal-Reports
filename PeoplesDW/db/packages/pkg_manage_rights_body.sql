create or replace package body pkg_manage_rights as
--
-- $Id$
--

procedure usp_insert_user_rights(
  users_id VARCHAR2,
  rights_id NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is 

begin
  
  insert into tbl_user_permissions(nameid, action, domain) values(users_id, rights_id, '*');
  return_status := 1;
  return_msg := 'OKAY';
    
  exception WHEN OTHERS THEN
    return_status := 0;
    return_msg := sqlerrm;
  
end  usp_insert_user_rights;

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

procedure usp_delete_user_rights(
  users_id VARCHAR2,  
  label_type NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is
begin
     delete from tbl_user_permissions 
            where nameid = users_id and action in (select action_id from tbl_lkup_permissions where tbl_lkup_permissions.action_label_id 
                         in  (select tbl_global_label_repository.label_id from tbl_global_label_repository where label_type_id = label_type));          
                   
   --delete from tbl_user_permissions where nameid = users_id;
    return_status := 1;
    return_msg := 'OKAY';
    
    exception WHEN OTHERS THEN
      return_status := 0;
      return_msg := sqlerrm;
      
end usp_delete_user_rights;

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

procedure usp_update_user_type(
  name_id VARCHAR2,
  type_id NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2

) is 
begin

  update TBL_USER_PROFILE set user_type = type_id where nameid= name_id;
 
  return_status := 1;
  return_msg := 'Done';  

  exception WHEN OTHERS THEN
      return_status := 0;
      return_msg := sqlerrm;
      
end usp_update_user_type;
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

procedure usp_get_user_type(
  users_id VARCHAR2,
  type_id OUT NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
) is
begin

  select Rights.rights_id into type_id from tbl_rights_access Rights 
    where Rights.users_id = users_id and Rights.rights_id 
      in (select Labels.label_id from tbl_global_label_repository Labels where Labels.label_type_id = 10);

    return_status := 1;
    return_msg := 'OKAY';  

  exception WHEN OTHERS THEN
      return_status := 0;
      return_msg := sqlerrm;
      
end usp_get_user_type;

end pkg_manage_rights;
/
exit;

