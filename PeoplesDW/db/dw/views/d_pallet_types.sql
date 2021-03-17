create or replace view d_pallet_types as
select
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      a.lastupdate Modification_Time,
      a.CODE   Pallet_Type,
      a.DESCR  Pallet_Type_Descr,
      a.ABBREV Pallet_Type_Abbrev,
      a.DTLUPDATE Detail_Update_YN,
      a.LASTUSER   Last_Update_User,
      a.LASTUPDATE Last_Update_Time
from  alps.pallettypes a;