create or replace trigger invoicehdr_biu
--
-- invoicehdr_trigger.sql
--
before insert or update
on invoicehdr
for each row
begin
  :new.lastupdate := sysdate;
end;
/
show error trigger invoicehdr_biu;
exit;
