create or replace view d_users as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  nameid as user_id,
  username as name,
  groupid as group_id,
  userstatus as status,
  decode(userstatus, 'A', 'Active', 'I', 'Inactive', '') as status_desc,
  equipment,
  b.abbrev as equipment_desc,
  opmode as rf_operator_mode,
  decode(opmode, 'T', 'Task Mode', 'S', 'System Mode', 'O', 'Operator Mode', '') as rf_operator_mode_desc,
  pickmode as rf_staging_mode,
  decode(pickmode, 'S', 'System Mode', 'O', 'Operator Mode', '') as rf_staging_mode_desc,
  facility as current_facility,
  chgfacility as change_facility,
  decode(chgfacility, 'A', 'All', 'S', 'Some', 'N', 'None', '') as change_facility_desc,
  custid as current_customer,
  allcusts as all_customers,
  decode(allcusts, 'A', 'All', 'S', 'Some', 'N', 'None', '') as all_customers_desc,
  lastlocation as last_location,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.userheader a, alps.equipmenttypes b
where usertype = 'U' and a.equipment = b.code(+);