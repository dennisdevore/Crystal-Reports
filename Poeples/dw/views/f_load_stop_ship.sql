--create or replace view f_load_stop_ship as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.loadno Unique_Key1,
  a.stopno Unique_Key2,
  a.shipno Unique_Key3,
  a.loadno as load_number,
  a.stopno as load_stop_number,
  a.shipno as load_stop_ship_number,
  a.entrydate as entry_date,
  a.qtyorder as qty_order,
  a.weightorder as weight_order,
  a.qtyship as qty_shipped,
  a.weightship as weight_shipped,
  a.qtyrcvd as qty_received,
  a.weightrcvd as weight_received,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.loadstopship a;