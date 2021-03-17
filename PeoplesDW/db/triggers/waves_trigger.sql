create or replace trigger waves_bu
--
-- $Id$
--
before update
on waves
for each row

declare
procedure remove_job is
begin
  :new.job := null;
  dbms_job.remove(:old.job);
exception when others then
  null;
end;

begin
  if (:new.wavestatus < '4') then
    :new.openfacility := :new.facility;
  else
    :new.openfacility := null;
  end if;
  if (:new.wavestatus in ('1','2')) then
    if (:new.schedrelease is not null) and
       (:new.schedrelease > sysdate) then
      if :old.job is not null then
        if :new.schedrelease <> :old.schedrelease then
          begin
            dbms_job.change(:old.job,null,:new.schedrelease,null);
          exception when others then
            null;
          end;
        end if;
      else
        begin
          dbms_job.submit(:new.job,'zwv.submit_autowave_request(' ||
            :new.wave || ', ''N'', ''SYSTEM'');',
            :new.schedrelease,null,null);
        exception when others then
          null;
        end;
      end if;
    else
      if :old.job is not null then
        remove_job;
      end if;
    end if;
  elsif (:new.wavestatus > '2') and
    (:old.job is not null) then
    remove_job;
  end if;
end;
/
show error trigger waves_bu;
exit;
