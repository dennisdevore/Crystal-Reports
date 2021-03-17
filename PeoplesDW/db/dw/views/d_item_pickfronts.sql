create or replace view d_item_pickfronts as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.facility,
  a.custid as customer,
  a.item,
  a.inventoryclass as inventory_class,
  b.abbrev as inventory_class_desc,
  a.pickfront as location,
  a.pickuom as pick_uom,
  a.replenishuom as replenish_uom,
  a.maxqty as maximum_qty,
  a.maxuom as maximum_uom,
  a.topoffqty as topoff_qty,
  a.topoffuom as topoff_uom,
  a.lastpickeddate as last_picked_date,
  a.dynamic as dynamic_yn,
  a.use_existing_lps as use_existing_lps_yn,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.itempickfronts a, alps.inventoryclass b
where a.inventoryclass = b.code(+);