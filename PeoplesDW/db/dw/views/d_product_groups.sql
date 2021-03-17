create or replace view d_product_groups as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  b.lastupdate Modification_Time,
  a.custid as customer,
  a.productgroup as product_group,
  b.descr as description,
  b.abbrev as abbreviation,
  a.status,
  a.rategroup as rate_group,
  a.fifowindowdays as fifo_window_days,
  b.lastuser as last_update_user,
  b.lastupdate as last_update_time
from alps.custproductgroupview a, alps.custproductgroup b
where a.custid = b.custid and a.productgroup = b.productgroup;