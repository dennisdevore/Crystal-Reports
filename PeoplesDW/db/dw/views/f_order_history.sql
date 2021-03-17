create or replace view f_order_history as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.chgdate Modification_Time,
  a.orderid,
  a.shipid,
  a.userid User_Id,
  a.action,
  a.lpid,
  a.item,
  a.lot Lot_Number,
  a.msg
from alps.orderhistory a;
