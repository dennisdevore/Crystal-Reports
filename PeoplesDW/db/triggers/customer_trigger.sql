create or replace trigger customer_au
--
-- $Id: custrate_trigger.sql 1 2005-05-26 12:20:03Z ed $
--
after update
on customer
for each row
begin
    if updating('credithold') then
        if :old.credithold in ('N','W') and :new.credithold = 'Y' then
            update multishipdtl
               set status = 'HOLD'
             where rowid in (
                    select D.rowid
                      from multishiphdr H, multishipdtl D
                     where D.status = 'READY'
                       and H.orderid = D.orderid
                       and H.shipid = D.shipid
                       and H.custid = :new.custid);
        end if;
        if :old.credithold = 'Y' and :new.credithold in ('N','W') then
            update multishipdtl
               set status = 'READY'
             where rowid in (
                    select D.rowid
                      from multishiphdr H, multishipdtl D
                     where D.status = 'HOLD'
                       and H.orderid = D.orderid
                       and H.shipid = D.shipid
                       and H.custid = :new.custid);
        end if;
    end if;
end;
/

exit;
