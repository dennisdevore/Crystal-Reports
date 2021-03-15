--create or replace view d_equipment_profile as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.profid Unique_Key,
  a.profid as profile_id,
  c.abbrev as profile_desc,
  a.equipid as equipment_id,
  b.abbrev as equipment_desc,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.equipprofequip a, alps.equipmenttypes b, alps.equipmentprofiles c 
where a.profid = c.code(+) and a.equipid = b.code(+);