--create or replace view d_unit_of_storage as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.unitofstorage Unique_Key1,
  unitofstorage as unit_of_storage,
  description,
  abbrev as abbreviation,
  depth,
  width,
  height,
  weightlimit as weight_limit,
  stdpallets as standard_pallets,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.unitofstorage a;