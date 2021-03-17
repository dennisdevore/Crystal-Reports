CREATE OR REPLACE TRIGGER pallethistory_rai
--
-- $Id$
--
after insert on pallethistory
for each row
declare

begin

begin
  update palletinventory
     set cnt = cnt + (nvl(:new.inpallets,0) - nvl(:new.outpallets,0))
   where custid = :new.custid
     and facility = :new.facility
     and pallettype = :new.pallettype;
  if sql%rowcount = 0 then
    insert into palletinventory
      (custid,facility,pallettype,cnt)
      values
      (:new.custid,:new.facility,:new.pallettype,:new.inpallets - :new.outpallets);
  end if;
  
  update pallethistory_sum_cust
     set inpallets = nvl(inpallets,0) + nvl(:new.inpallets,0),
         outpallets = nvl(outpallets,0) + nvl(:new.outpallets,0)
   where custid = :new.custid
     and facility = :new.facility
     and pallettype = :new.pallettype
     and trunc_lastupdate = trunc(:new.lastupdate);
  if sql%rowcount = 0 then
    insert into pallethistory_sum_cust
     (custid,facility,pallettype,trunc_lastupdate,inpallets,outpallets)
     values
     (:new.custid,:new.facility,:new.pallettype,trunc(:new.lastupdate),
      nvl(:new.inpallets,0),nvl(:new.outpallets,0));
  end if;
  
end;

end;
/
CREATE OR REPLACE TRIGGER pallethistory_rau
--
-- $Id$
--
after update on pallethistory
for each row
declare
l_inpallets pls_integer;
l_outpallets pls_integer;

begin

if :old.custid != :new.custid or
   :old.facility != :new.facility or
   :old.pallettype != :new.pallettype or
   nvl(:old.inpallets,0) != nvl(:new.inpallets,0) or
   nvl(:old.outpallets,0) != nvl(:new.outpallets,0) then
  update palletinventory
     set cnt = cnt - (nvl(:old.inpallets,0) - nvl(:old.outpallets,0))
     where custid = :old.custid
       and facility = :old.facility
       and pallettype = :old.pallettype;

  update palletinventory
     set cnt = cnt + (nvl(:new.inpallets,0) - nvl(:new.outpallets,0))
   where custid = :new.custid
     and facility = :new.facility
     and pallettype = :new.pallettype;
  if sql%rowcount = 0 then
    insert into palletinventory
      (custid,facility,pallettype,cnt)
      values
      (:new.custid,:new.facility,:new.pallettype,nvl(:new.inpallets,0) - nvl(:new.outpallets,0));
  end if;

  update pallethistory_sum_cust
     set inpallets = nvl(inpallets,0) - nvl(:old.inpallets,0),
         outpallets = nvl(outpallets,0) - nvl(:old.outpallets,0)
   where custid = :old.custid
     and facility = :old.facility
     and pallettype = :old.pallettype
     and trunc_lastupdate = trunc(:old.lastupdate)
   returning inpallets, outpallets
    into l_inpallets, l_outpallets;
  if nvl(l_inpallets,0) = 0 and
     nvl(l_outpallets,0) = 0 then
    delete
      from pallethistory_sum_cust
     where custid = :old.custid
       and facility = :old.facility
       and pallettype = :old.pallettype
       and trunc_lastupdate = trunc(:old.lastupdate);
  end if;
  
  update pallethistory_sum_cust
     set inpallets = nvl(inpallets,0) + nvl(:new.inpallets,0),
         outpallets = nvl(outpallets,0) + nvl(:new.outpallets,0)
   where custid = :new.custid
     and facility = :new.facility
     and pallettype = :new.pallettype
     and trunc_lastupdate = trunc(:new.lastupdate);
  if sql%rowcount = 0 then
    insert into pallethistory_sum_cust
     (custid,facility,pallettype,trunc_lastupdate,inpallets,outpallets)
     values
     (:new.custid,:new.facility,:new.pallettype,trunc(:new.lastupdate),
      nvl(:new.inpallets,0),nvl(:new.outpallets,0));
  end if;
  
end if;

end;
/
CREATE OR REPLACE TRIGGER pallethistory_rad
--
-- $Id$
--
after delete on pallethistory
for each row
declare
l_inpallets pls_integer;
l_outpallets pls_integer;

begin

update palletinventory
   set cnt = cnt - (nvl(:old.inpallets,0) - nvl(:old.outpallets,0))
   where custid = :old.custid
     and facility = :old.facility
     and pallettype = :old.pallettype;

update pallethistory_sum_cust
   set inpallets = nvl(inpallets,0) - nvl(:old.inpallets,0),
       outpallets = nvl(outpallets,0) - nvl(:old.outpallets,0)
 where custid = :old.custid
   and facility = :old.facility
   and pallettype = :old.pallettype
   and trunc_lastupdate = trunc(:old.lastupdate)
 returning inpallets, outpallets
  into l_inpallets, l_outpallets;
if nvl(l_inpallets,0) = 0 and
   nvl(l_outpallets,0) = 0 then
  delete
    from pallethistory_sum_cust
   where custid = :old.custid
     and facility = :old.facility
     and pallettype = :old.pallettype
     and trunc_lastupdate = trunc(:old.lastupdate);
end if;

end;
/
show errors trigger pallethistory_rai;
show errors trigger pallethistory_rau;
show errors trigger pallethistory_rad;
--exit;
