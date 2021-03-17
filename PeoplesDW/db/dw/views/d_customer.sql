create or replace view d_customer as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  custid as customer,
  name,
  status,
  addr1 as address_1,
  addr2 as address_2,
  city,
  state,
  postalcode as zip_code,
  countrycode as country,
  phone,
  fax,
  email,
  rategroup as rate_group,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.customer a;