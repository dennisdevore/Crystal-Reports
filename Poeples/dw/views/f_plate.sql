--create or replace view f_plate as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.lpid Unique_Key1,
  'N' Deleted_Plate_YN,
  a.lpid,
  a.parentlpid as parent_lpid,
  a.fromlpid as from_lpid,
  a.facility,
  a.custid as customer,
  a.item,
  a.lotnumber as lot_number,
  a.location,
  a.status,
  b.abbrev as status_desc,
  a.inventoryclass as inventory_class,
  e.abbrev as inventory_class_desc,
  a.invstatus as inventory_status,
  f.abbrev as inventory_status_desc,
  a.type,
  c.abbrev as type_desc,
  a.quantity,
  a.qtyrcvd as quantity_received,
  a.unitofmeasure as unit_of_measure,
  a.serialnumber as serial_number,
  a.useritem1 as user_item_1,
  a.useritem2 as user_item_2,
  a.useritem3 as user_item_3,
  a.manufacturedate as manufacture_date,
  a.expirationdate as expiration_date,
  a.countryof as country_of,
  a.po,
  a.recmethod as handling_type,
  d.abbrev as handling_type_desc,
  a.loadno as load_number,
  a.stopno as load_stop_number,
  a.shipno as load_stop_ship_number,
  a.orderid,
  a.shipid,
  a.weight,
  a.length,
  a.width,
  a.height,
  a.pallet_weight,
  a.lastcountdate as last_count_date,
  a.fifodate as fifo_date,
  a.anvdate as anniversary_date,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.plate a, alps.licenseplatestatus b, alps.licenseplatetypes c,
  alps.handlingtypes d, alps.inventoryclass e, alps.inventorystatus f
where a.status = b.code(+) and a.type = c.code(+) and a.recmethod = d.code(+)
  and a.inventoryclass = e.code(+) and a.invstatus = f.code(+)
union all
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.lpid Unique_Key1,
  'Y' Deleted_Plate_YN,
  a.lpid,
  a.parentlpid as parent_lpid,
  a.fromlpid as from_lpid,
  a.facility,
  a.custid as customer,
  a.item,
  a.lotnumber as lot_number,
  a.location,
  a.status,
  b.abbrev as status_desc,
  a.inventoryclass as inventory_class,
  e.abbrev as inventory_class_desc,
  a.invstatus as inventory_status,
  f.abbrev as inventory_status_desc,
  a.type,
  c.abbrev as type_desc,
  a.quantity,
  a.qtyrcvd as quantity_received,
  a.unitofmeasure as unit_of_measure,
  a.serialnumber as serial_number,
  a.useritem1 as user_item_1,
  a.useritem2 as user_item_2,
  a.useritem3 as user_item_3,
  a.manufacturedate as manufacture_date,
  a.expirationdate as expiration_date,
  a.countryof as country_of,
  a.po,
  a.recmethod as handling_type,
  d.abbrev as handling_type_desc,
  a.loadno as load_number,
  a.stopno as load_stop_number,
  a.shipno as load_stop_ship_number,
  a.orderid,
  a.shipid,
  a.weight,
  a.length,
  a.width,
  a.height,
  a.pallet_weight,
  a.lastcountdate as last_count_date,
  a.fifodate as fifo_date,
  a.anvdate as anniversary_date,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.deletedplate a, alps.licenseplatestatus b, alps.licenseplatetypes c,
  alps.handlingtypes d, alps.inventoryclass e, alps.inventorystatus f
where a.status = b.code(+) and a.type = c.code(+) and a.recmethod = d.code(+)
  and a.inventoryclass = e.code(+) and a.invstatus = f.code(+);