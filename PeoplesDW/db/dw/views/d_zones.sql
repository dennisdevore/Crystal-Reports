create or replace view d_zones as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  facility,
  zoneid as zone,
  description,
  abbrev as abbreviation,
  panddlocation as pick_n_drop_location,
  pickdirection as pick_direction,
  pickconfirmlocation as confirm_location_yn,
  pickconfirmitem as confirm_item_yn,
  pickconfirmcontainer as confirm_container_yn,
  count_after_pick,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.zone a;