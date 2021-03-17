create or replace view d_facility as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  facility,
  name,
  facilitystatus as status,
  b.abbrev as status_desc,
  manager,
  campus,
  addr1 as address_1,
  addr2 as address_2,
  city,
  state,
  postalcode as zip_code,
  countrycode as country,
  phone,
  fax,
  email,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.facility a, alps.facilitystatus b
where a.facilitystatus = b.code(+);