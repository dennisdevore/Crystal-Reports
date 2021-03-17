create or replace view f_cycle_count_activity as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.whenoccurred Modification_Time,
  a.facility,
  a.custid as customer,
  a.entcustid as entered_customer,
  a.location,
  a.entlocation as entered_location,
  a.lpid,
  a.item,
  a.entitem as entered_item,
  a.lotnumber as lot_number,
  a.entlotnumber as entered_lot_number,
  a.uom as unit_of_measure,
  a.quantity,
  a.entquantity as entered_quantity,
  a.entmfgdate as entered_manufacture_date,
  a.entexpdate as entered_expiration_date,
  a.taskid as task_id,
  a.adjustmenttype as adjustment_type,
  b.abbrev as adjustment_type_desc,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.cyclecountactivity a, alps.cyclecountadjustmenttypes b
where a.adjustmenttype = b.code(+);