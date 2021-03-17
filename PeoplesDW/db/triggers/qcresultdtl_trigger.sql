create or replace trigger qcresultdtl_aiud
--
-- $Id$
--
after insert or update or delete
on qcresultdtl
for each row
declare
Begin

if (inserting) then
   update qcresult
      set qtypassed = nvl(qtypassed,0) + nvl(:new.qtypassed,0),
          qtyfailed = nvl(qtyfailed,0) + nvl(:new.qtyfailed,0)
    where id = :new.id
      and orderid = :new.orderid
      and shipid = :new.shipid
      and item = :new.item
      and nvl(lotnumber,'(none)') = nvl(:new.lotnumber,'(none)');
end if;
if (Updating) then
   update qcresult
      set qtypassed = nvl(qtypassed,0) + nvl(:new.qtypassed,0)
                      - nvl(:old.qtypassed,0),
          qtyfailed = nvl(qtyfailed,0) + nvl(:new.qtyfailed,0)
                      - nvl(:old.qtyfailed,0)
    where id = :new.id
      and orderid = :new.orderid
      and shipid = :new.shipid
      and item = :new.item
      and nvl(lotnumber,'(none)') = nvl(:new.lotnumber,'(none)');
end if;

if (deleting) then
   update qcresult
      set qtypassed = nvl(qtypassed,0) - nvl(:old.qtypassed,0),
          qtyfailed = nvl(qtyfailed,0) - nvl(:old.qtyfailed,0)
    where id = :new.id
      and orderid = :new.orderid
      and shipid = :new.shipid
      and item = :new.item
      and nvl(lotnumber,'(none)') = nvl(:new.lotnumber,'(none)');
end if;


end qcresultdtl_aiud;

/

show error trigger qcresultdtl_aiud;

-- exit;



