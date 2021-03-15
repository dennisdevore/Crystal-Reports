--create or replace view f_order_history as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.chgdate Modification_Time,
  orderid,
  shipid,
  userid,
  action,
  lpid,
  item,
  lot,
  msg
from alps.orderhistory a;
