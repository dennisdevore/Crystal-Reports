create or replace trigger parceltracking_bi
--
-- $Id: parceltracking_trigger.sql 1613 2007-02-19 15:55:43Z jeff $
--
before insert
on parceltracking
for each row
declare
tCharCost varchar2(12);
tCost number(10,2);
begin
   tCharCost := :new.charcost;
   if tCharCost is not null then
      tCost := to_number(tCharCost,'99999999.99');
      :new.cost := tCost;
   end if;
end;
/
show errors trigger parceltracking_bi
exit;
