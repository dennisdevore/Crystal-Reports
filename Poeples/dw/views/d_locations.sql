--create or replace view d_locations as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.facility Unique_Key1,
  a.locid Unique_Key2,
  a.facility,
  a.locid as location,
  a.descr as description,
  a.custid as customer,
  a.loctype as location_type,
  b.abbrev as location_type_desc,
  a.storagetype as storage_type,
  c.abbrev as storage_type_desc,
  status,
  d.abbrev as status_desc,
  checkdigit as check_digit,
  pickingseq as picking_sequence,
  pickingzone as picking_zone,
  putawayseq as putaway_sequence,
  putawayzone as putaway_zone,
  equipprof as equipment_profile,
  velocity,
  mixeditemsok as mixed_items_yn,
  mixedlotsok as mixed_lots_yn,
  mixeduomok as mixed_uom_yn,
  lastcounted as last_counted,
  unitofstorage as unit_of_storage,
  aisle,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.location a, alps.locationtypes b, alps.storagetypes c, alps.locationstatus d
where a.loctype = b.code(+)
  and a.storagetype = c.code(+)
  and a.status = d.code(+);