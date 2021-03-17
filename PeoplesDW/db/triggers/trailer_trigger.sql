create or replace trigger trailer_aiud
--
-- $Id: trailer_trigger.sql 3138 2008-10-24 13:51:02Z ed $
--

after insert or update or delete
on trailer
for each row
begin

if (inserting or updating) then
  insert into trailer_history
   (TRAILER_NUMBER,ACTIVITY_TIME,ACTIVITY_TYPE,TRAILER_LPID,FACILITY,LOCATION,CARRIER,
    CONTENTS_STATUS,TRAILER_STATUS,LOADNO,STYLE,TRAILER_TYPE,DISPOSITION,
    EXPECTED_TIME_IN,GATE_TIME_IN,EXPECTED_TIME_OUT,GATE_TIME_OUT,PUT_ON_WATER,
    ETA_TO_PORT,ARRIVED_AT_PORT,LAST_FREE_DATE,CARRIER_CONTACT_DATE,
    ARRIVED_IN_YARD,APPOINTMENT_DATE,DUE_BACK,RETURNED_TO_PORT,LASTUSER,
    LASTUPDATE)
   values
   (:new.TRAILER_NUMBER,systimestamp,:new.ACTIVITY_TYPE,:new.TRAILER_LPID,:new.FACILITY,:new.LOCATION,
    :new.CARRIER,:new.CONTENTS_STATUS,:new.TRAILER_STATUS,:new.LOADNO,:new.STYLE,:new.TRAILER_TYPE,
    :new.DISPOSITION,:new.EXPECTED_TIME_IN,:new.GATE_TIME_IN,:new.EXPECTED_TIME_OUT,
    :new.GATE_TIME_OUT,:new.PUT_ON_WATER,:new.ETA_TO_PORT,:new.ARRIVED_AT_PORT,
    :new.LAST_FREE_DATE,:new.CARRIER_CONTACT_DATE,:new.ARRIVED_IN_YARD,:new.APPOINTMENT_DATE,
    :new.DUE_BACK,:new.RETURNED_TO_PORT,:new.LASTUSER,:new.LASTUPDATE);
end if;

if (inserting) and
   (:new.facility is not null) and
   (:new.location is not null) then
  update location
     set lpcount = nvl(lpcount,0) + 1
   where facility = :new.facility
     and locid = :new.location;
end if;

if (updating) and
   ( nvl(:new.facility,'x') != nvl(:old.facility,'x') or
     nvl(:new.location,'x') != nvl(:old.location,'x') ) then
  if (:old.facility is not null) and
     (:old.location is not null) then
    update location
       set lpcount = nvl(lpcount,0) - 1
     where facility = :old.facility
       and locid = :old.location
       and lpcount > 0;
  end if;
  if (:new.facility is not null) and
     (:new.location is not null) then
    update location
       set lpcount = nvl(lpcount,0) + 1
     where facility = :new.facility
       and locid = :new.location;
  end if;
end if;

if (deleting) and
   (:old.facility is not null) and
   (:old.location is not null) then
  update location
     set lpcount = nvl(lpcount,0) - 1
   where facility = :old.facility
     and locid = :old.location
     and lpcount > 0;
end if;

end;
/

show error trigger trailer_aiud

exit;
