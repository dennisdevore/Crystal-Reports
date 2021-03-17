create or replace trigger loadstopship_biud
--
-- $Id$
--
before insert or update or delete
on loadstopship
for each row
begin
  if (inserting) then
    update loadstop
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
     where loadno = :new.loadno
       and stopno = :new.stopno;
  end if;
  if (updating('qtyorder') or updating('weightorder') or updating('cubeorder') or
      updating('amtorder') or updating('qtyship') or updating('weightship') or
      updating('cubeship') or updating('amtship') or updating('qtyrcvd') or
      updating('weightrcvd') or updating('cubercvd') or updating('amtrcvd') or
      updating('weightrcvd_kgs') or updating('weightship_kgs') or
      updating('weight_entered_lbs') or updating('weight_entered_kgs')) then
    update loadstop
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
     where loadno = :new.loadno
       and stopno = :new.stopno;
  end if;
  if (deleting) then
    update loadstop
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
           weight_entered_kgs = nvl(weight_entered_kgs,0) - nvl(:old.weight_entered_kgs,0)
     where loadno = :old.loadno
       and stopno = :old.stopno;
  end if;
end;
/

exit;
