create or replace view f_pallet_inventory as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  sysdate Modification_Time,
  a.facility,
  a.custid as customer,
  a.pallettype as pallet_type,
  b.abbrev as pallet_type_desc,
  a.cnt as quantity
from alps.palletinventory a, alps.pallettypes b
where a.pallettype = b.code(+);