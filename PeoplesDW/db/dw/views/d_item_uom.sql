create or replace view d_item_uom as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.custid as customer,
  a.item,
  a.sequence,
  a.fromuom as from_unit_of_measure,
  a.touom as to_unit_of_measure,
  a.qty as quantity,
  a.velocity,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.custitemuom a;