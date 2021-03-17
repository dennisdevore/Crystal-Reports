create or replace view d_unit_of_measure as
select
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      a.lastupdate Modification_Time,
      a.code   Unit_Of_Measure,
      a.descr  Unit_Of_Measure_Desc,
      a.abbrev Unit_Of_Measure_Abbrev,
      a.dtlupdate Detail_Update_YN,
      a.lastuser as last_update_user,
      a.lastupdate as last_update_time
from alps.unitsofmeasure a;