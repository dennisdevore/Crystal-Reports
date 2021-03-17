create or replace trigger multishipdtl_bu
--
-- $Id$
--
before update
on multishipdtl
for each row
begin
   if updating('datetimeshipped') then
      :new.shipdatetime := to_char(:new.datetimeshipped,'YYYYMMDDHH24MISS');
   end if;
   if updating('status') then
      if :old.status = 'HOLD' and :new.status = 'SHIPPED' then
        raise_application_error(-20001, 'Credit Hold cannot ship');
      end if;
   end if;
end;
/


create or replace trigger multishipdtl_au
--
-- $Id$
--
after update
on multishipdtl
for each row
declare
   errmsg varchar2(100);
begin
   if :new.status != :old.status
   and :new.status = 'SHIPPED' then
      zmn.send_shipped_msg(:new.cartonid, errmsg);
   end if;

end;
/

show error trigger multishipdtl_bu;
show error trigger multishipdtl_au;
exit;
