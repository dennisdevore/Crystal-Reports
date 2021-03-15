--create or replace view d_sections as
select
  sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
  a.lastupdate Modification_Time,
  a.facility Unique_Key1,
  a.sectionid Unique_Key2,
  facility,
  sectionid as section_id,
  sectionn as section_north,
  sectionne as section_northeast,
  sectione as section_east,
  sectionse as section_southeast,
  sections as section_south,
  sectionsw as section_southwest,
  sectionw as section_west,
  sectionnw as section_northwest,
  a.lastuser as last_update_user,
  a.lastupdate as last_update_time
from alps.section a;