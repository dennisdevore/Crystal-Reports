create or replace view d_supplier as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.shipper as supplier,
  a.name,
  a.shipperstatus as supplier_status,
  b.abbrev as supplier_status_desc,
  a.addr1 as address_1,
  a.addr2 as address_2,
  a.city,
  a.state,
  a.postalcode as zip_code,
  a.countrycode as country,
  a.phone,
  a.fax,
  a.email,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.shipper a, alps.shipperstatus b
where a.shipperstatus = b.code(+);