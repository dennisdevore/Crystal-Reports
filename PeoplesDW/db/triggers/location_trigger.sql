create or replace trigger location_bu
--
-- $Id$
--
before update
on location
for each row
begin
   if (updating('lpcount')) then
      if (:new.lpcount = 0 and :new.status = 'I') then
         :new.status := 'E';
         :new.lastpickedfrom := null;
         :new.lastputawayto := null;
      elsif (:new.lpcount > 0 and :new.status = 'E') then
         :new.status := 'I';
      end if;
   end if;
   if (:old.unitofstorage != :new.unitofstorage) then
    :new.used_uos := null;
  end if;
end;
/

create or replace trigger location_aiud
--
-- $Id$
--
after insert or update or delete
on location
for each row
declare
currcount integer;
msg varchar2(80);
begin

  if ( (inserting) and (:new.loctype = 'DOR') ) or
     ( (updating)  and (:new.loctype = 'DOR' and :old.loctype != 'DOR') ) then
    select count(1)
      into currcount
      from door
     where facility = :new.facility
       and doorloc = :new.locid;
    if currcount = 0 then
      insert into door (facility, doorloc, lastuser, lastupdate)
                values (:new.facility, :new.locid, :new.lastuser, sysdate);
    end if;
  end if;

  if ( (deleting) and (:old.loctype = 'DOR') ) or
     ( (updating)  and (:old.loctype = 'DOR' and :new.loctype != 'DOR') ) then
    delete from door
     where facility = :old.facility
       and doorloc = :old.locid
       and nvl(loadno,0) = 0;
  end if;

  if ( (updating) and (:old.loctype = 'FPF') and
       (nvl(:old.flex_pick_front_wave,0) != nvl(:new.flex_pick_front_wave,0)) and
       (nvl(:new.flex_pick_front_wave,0) = 0) ) then
    for crec in (select lpid from plate where facility=:old.facility and location=:old.locid)
    loop
      zput.putaway_lp_delay('TANR', crec.lpid, :old.facility, :old.locid, :new.lastuser,
        'Y', msg);
    end loop;

    for crec2 in (select taskid from tasks where facility=:old.facility and toloc=:old.locid and tasktype='RP')
    loop
      ztk.task_delete(:old.facility, crec2.taskid, :new.lastuser, msg);
    end loop;
  end if;

end;
/
show error trigger location_bu;
show error trigger location_aiud;
exit;
