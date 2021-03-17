create or replace trigger loadstop_biud
--
-- $Id$
--
before insert or update or delete
on loadstop
for each row
declare
   minstatus orderhdr.orderstatus%type;
   maxstatus orderhdr.orderstatus%type;
   newstatus loads.loadstatus%type;
begin
  if (inserting) then
    begin
      select facility
        into :new.facility
        from loads
       where loadno = :new.loadno;
    exception when others then
      null;
    end;
    update loads
       set qtyorder = nvl(qtyorder,0) + nvl(:new.qtyorder,0),
           weightorder = nvl(weightorder,0) + nvl(:new.weightorder,0),
           cubeorder = nvl(cubeorder,0) + nvl(:new.cubeorder,0),
           amtorder = nvl(amtorder,0) + nvl(:new.amtorder,0),
           qtyship = nvl(qtyship,0) + nvl(:new.qtyship,0),
           weightship = nvl(weightship,0) + nvl(:new.weightship,0),
           weightship_kgs = nvl(weightship_kgs,0) + nvl(:new.weightship_kgs,0),
           cubeship = nvl(cubeship,0) + nvl(:new.cubeship,0),
           amtship = nvl(amtship,0) + nvl(:new.amtship,0),
           qtyrcvd = nvl(qtyrcvd,0) + nvl(:new.qtyrcvd,0),
           weightrcvd = nvl(weightrcvd,0) + nvl(:new.weightrcvd,0),
           weightrcvd_kgs = nvl(weightrcvd_kgs,0) + nvl(:new.weightrcvd_kgs,0),
           cubercvd = nvl(cubercvd,0) + nvl(:new.cubercvd,0),
           amtrcvd = nvl(amtrcvd,0) + nvl(:new.amtrcvd,0),
           weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(:new.weight_entered_lbs,0),
           weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(:new.weight_entered_kgs,0)
     where loadno = :new.loadno;
  end if;
  if (updating('qtyorder') or updating('weightorder') or updating('cubeorder') or
      updating('amtorder') or updating('qtyship') or updating('weightship') or
      updating('cubeship') or updating('amtship') or updating('qtyrcvd') or
      updating('weightrcvd') or updating('cubercvd') or updating('amtrcvd') or
      updating('weightrcvd_kgs') or updating('weightship_kgs') or
      updating('weight_entered_lbs') or updating('weight_entered_kgs')) then
    update loads
       set qtyorder = nvl(qtyorder,0) + nvl(:new.qtyorder,0) - nvl(:old.qtyorder,0),
           weightorder = nvl(weightorder,0) + nvl(:new.weightorder,0) - nvl(:old.weightorder,0),
           cubeorder = nvl(cubeorder,0) + nvl(:new.cubeorder,0) - nvl(:old.cubeorder,0),
           amtorder = nvl(amtorder,0) + nvl(:new.amtorder,0) - nvl(:old.amtorder,0),
           qtyship = nvl(qtyship,0) + nvl(:new.qtyship,0) - nvl(:old.qtyship,0),
           weightship = nvl(weightship,0) + nvl(:new.weightship,0) - nvl(:old.weightship,0),
           weightship_kgs = nvl(weightship_kgs,0) + nvl(:new.weightship_kgs,0) - nvl(:old.weightship_kgs,0),
           cubeship = nvl(cubeship,0) + nvl(:new.cubeship,0) - nvl(:old.cubeship,0),
           amtship = nvl(amtship,0) + nvl(:new.amtship,0) - nvl(:old.amtship,0),
           qtyrcvd = nvl(qtyrcvd,0) + nvl(:new.qtyrcvd,0) - nvl(:old.qtyrcvd,0),
           weightrcvd = nvl(weightrcvd,0) + nvl(:new.weightrcvd,0) - nvl(:old.weightrcvd,0),
           weightrcvd_kgs = nvl(weightrcvd_kgs,0) + nvl(:new.weightrcvd_kgs,0) - nvl(:old.weightrcvd_kgs,0),
           cubercvd = nvl(cubercvd,0) + nvl(:new.cubercvd,0) - nvl(:old.cubercvd,0),
           amtrcvd = nvl(amtrcvd,0) + nvl(:new.amtrcvd,0) - nvl(:old.amtrcvd,0),
           weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(:new.weight_entered_lbs,0) - nvl(:old.weight_entered_lbs,0),
           weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(:new.weight_entered_kgs,0) - nvl(:old.weight_entered_kgs,0)
     where loadno = :new.loadno;
  end if;
  if (updating) and
     (:old.loadstopstatus != :new.loadstopstatus) then
    :new.statususer := :new.lastuser;
    :new.statusupdate := sysdate;
  end if;
  if (deleting) then

      select min(orderstatus), max(orderstatus)
         into minstatus, maxstatus
         from orderhdr
      	where loadno = :old.loadno
           and stopno != :old.stopno
           and orderstatus != 'X';

      if (minstatus is null) then
         newstatus := '1';
      elsif (minstatus = maxstatus) then
         if (minstatus = '2') then
            newstatus := '1';
         elsif (minstatus = '3') then
            newstatus := '2';
         else
            newstatus := minstatus;
         end if;
      else
         if (maxstatus = '8') then
            newstatus := '7';
         elsif (maxstatus = '6') then
        	   newstatus := '5';
         else
        	   newstatus := maxstatus;
         end if;
      end if;

    update loads
       set qtyorder = nvl(qtyorder,0) - nvl(:old.qtyorder,0),
           weightorder = nvl(weightorder,0) - nvl(:old.weightorder,0),
           cubeorder = nvl(cubeorder,0) - nvl(:old.cubeorder,0),
           amtorder = nvl(amtorder,0) - nvl(:old.amtorder,0),
           qtyship = nvl(qtyship,0) - nvl(:old.qtyship,0),
           weightship = nvl(weightship,0) - nvl(:old.weightship,0),
           weightship_kgs = nvl(weightship_kgs,0) - nvl(:old.weightship_kgs,0),
           cubeship = nvl(cubeship,0) - nvl(:old.cubeship,0),
           amtship = nvl(amtship,0) - nvl(:old.amtship,0),
           qtyrcvd = nvl(qtyrcvd,0) - nvl(:old.qtyrcvd,0),
           weightrcvd = nvl(weightrcvd,0) - nvl(:old.weightrcvd,0),
           weightrcvd_kgs = nvl(weightrcvd_kgs,0) - nvl(:old.weightrcvd_kgs,0),
           cubercvd = nvl(cubercvd,0) - nvl(:old.cubercvd,0),
           amtrcvd = nvl(amtrcvd,0) - nvl(:old.amtrcvd,0),
           weight_entered_lbs = nvl(weight_entered_lbs,0) - nvl(:old.weight_entered_lbs,0),
           weight_entered_kgs = nvl(weight_entered_kgs,0) - nvl(:old.weight_entered_kgs,0),
           loadstatus = newstatus
     where loadno = :old.loadno;

  end if;
end;
/


show errors trigger loadstop_biud;
exit;
