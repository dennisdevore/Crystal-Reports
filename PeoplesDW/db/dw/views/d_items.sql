create or replace view d_items as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.custid as customer,
  a.item,
  a.descr as description,
  a.baseuom as base_unit_of_measure,
  a.length,
  a.width,
  a.height,
  a.stackheight as stack_height,
  a.weight,
  a.cube,
  a.shelflife as shelf_life,
  a.productgroup as product_group,
  a.rategroup,
  nvl(a.iskit,'N') as kit_yn,
--  b.hts_code,
--  b.hts_descr as hts_desc,
  a.countryof as country_of,
  a.velocity,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.custitemview a, alps.custitem b 
where a.custid = b.custid and a.item = b.item;