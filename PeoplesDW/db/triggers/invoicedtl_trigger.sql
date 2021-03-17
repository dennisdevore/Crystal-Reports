create or replace trigger invoicedtl_biu
--
-- $Id$
--
before insert or update
on invoicedtl
for each row
begin
  if INSERTING then
     if :new.invoicedtlkey is null then 
       :new.invoicedtlkey := invoicedtlseq.nextval;
     end if;
  
     if :new.invoice is null then
        :new.invoice := 0;
     end if;
     :new.billedqty := :new.calcedqty;
     :new.billedrate := :new.calcedrate;
     :new.billedamt := :new.calcedamt;
  else
     if nvl(:old.calcedqty,-100000) != nvl(:new.calcedqty,-100000) then
        :new.billedqty := :new.calcedqty;
     end if;
     if nvl(:old.calcedrate,-100000) != nvl(:new.calcedrate,-100000) then
        :new.billedrate := :new.calcedrate;
     end if;
     if nvl(:old.calcedamt,-100000) != nvl(:new.calcedamt,-100000) then
        :new.billedamt := :new.calcedamt;
     end if;
  end if;
  :new.lastupdate := sysdate;
end;
/


create or replace trigger invoicedtl_au
--
-- $Id$
--
after update
on invoicedtl
for each row
declare
begin
   if nvl(:old.billstatus,'x') = '1' and nvl(:new.billstatus,'x') = '2' then
      zoo.addrevenue(:new.facility, :new.custid, :new.invtype, :new.billedamt);
   elsif nvl(:old.billstatus,'x') = '2' and nvl(:new.billstatus,'x') in ('0','1') then
      zoo.addrevenue(:new.facility, :new.custid, :new.invtype, -:new.billedamt);
   end if;
end;
/


show error trigger invoicedtl_biu;
show error trigger invoicedtl_au;
exit;
