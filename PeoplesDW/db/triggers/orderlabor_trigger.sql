create or replace trigger orderlabor_biud
--
-- $Id$
--
before insert or update or delete
on orderlabor
for each row

begin
   if (updating) and
      ( (nvl(:old.orderid,0) = nvl(:new.orderid,0)) and
        (nvl(:old.shipid,0) = nvl(:new.shipid,0)) and
        (nvl(:old.item,'x') = nvl(:new.item,'x')) and
        (nvl(:old.lotnumber,'(none)') = nvl(:new.lotnumber,'(none)')) ) then
      update orderdtl
         set staffhrs = nvl(staffhrs,0) - nvl(:old.staffhrs,0) + nvl(:new.staffhrs,0)
       where orderid = :old.orderid
         and shipid = :old.shipid
         and item = :old.item
         and nvl(lotnumber,'(none)') = nvl(:old.lotnumber,'(none)');
   end if;

   if (deleting) or
      ( (updating) and
        ((nvl(:old.orderid,0) != nvl(:new.orderid,0)) or
         (nvl(:old.shipid,0) != nvl(:new.shipid,0)) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)'))) ) then
      update orderdtl
         set staffhrs = nvl(staffhrs,0) - nvl(:old.staffhrs,0)
       where orderid = :old.orderid
         and shipid = :old.shipid
         and item = :old.item
         and nvl(lotnumber,'(none)') = nvl(:old.lotnumber,'(none)');
   end if;

   if (inserting) or
      ( (updating) and
        ((nvl(:old.orderid,0) != nvl(:new.orderid,0)) or
         (nvl(:old.shipid,0) != nvl(:new.shipid,0)) or
         (nvl(:old.item,'x') != nvl(:new.item,'x')) or
         (nvl(:old.lotnumber,'(none)') != nvl(:new.lotnumber,'(none)'))) ) then
      update orderdtl
         set staffhrs = nvl(staffhrs,0) + nvl(:new.staffhrs,0)
       where orderid = :new.orderid
         and shipid = :new.shipid
         and item = :new.item
         and nvl(lotnumber,'(none)') = nvl(:new.lotnumber,'(none)');
   end if;


end;
/
show error trigger orderlabor_biud;
exit;
