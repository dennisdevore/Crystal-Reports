create or replace trigger deletedplate_biu
--
-- deletedplate_trigger.sql
--
before insert or update
on deletedplate
for each row
begin
  :new.lastupdate := sysdate;
end;
/
show error trigger deletedplate_biu;
exit;
