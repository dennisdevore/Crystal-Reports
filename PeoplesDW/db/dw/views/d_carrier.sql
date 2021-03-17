create or replace view d_carrier as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.carrier,
  a.name,
  a.scac,
  a.carrierstatus as carrier_status,
  b.abbrev as carrier_status_desc,
  a.addr1 as address_1,
  a.addr2 as address_2,
  a.city,
  a.state,
  a.postalcode as zip_code,
  a.countrycode as country,
  a.phone,
  a.fax,
  a.email,
  nvl(a.multiship,'N') as multiship_yn,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.carrier a, alps.carrierstatus b
where a.carrierstatus = b.code(+);