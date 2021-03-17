create or replace trigger custrate_ad
--
-- $Id$
--
after delete
on custrate
for each row
begin
  delete from custratewhen
   where custid = :old.custid
     and rategroup = :old.rategroup
     and effdate = :old.effdate
     and activity = :old.activity
     and billmethod = :old.billmethod;
  delete from custratebreak
   where custid = :old.custid
     and rategroup = :old.rategroup
     and effdate = :old.effdate
     and activity = :old.activity
     and billmethod = :old.billmethod;
  delete from custpalletrate
   where custid = :old.custid
     and rategroup = :old.rategroup
     and effdate = :old.effdate
     and activity = :old.activity
     and billmethod = :old.billmethod;
  delete from custratecarrierdiscount
    where custid = :old.custid
     and rategroup = :old.rategroup
     and effdate = :old.effdate
     and activity = :old.activity
     and billmethod = :old.billmethod;
end;
/

exit;
