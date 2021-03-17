--
-- $Id$
--
create index deletedplate_controlno_idx
on deletedplate(controlnumber);
create index deletedplate_customer_idx
on deletedplate(facility,custid,item,lotnumber);
create index deletedplate_destination_idx
on deletedplate(destfacility,destlocation);
create index deletedplate_fromshiplip_idx
on deletedplate(fromshippinglpid);
create index deletedplate_loadno_idx
on deletedplate(loadno);
create index deletedplate_location_idx
on deletedplate(facility,location);
create index deletedplate_parentlpid_idx
on deletedplate(parentlpid);
create index deletedplate_invstatus_idx
   on deletedplate(facility,invstatus);
create index deletedplate_invclass_idx
   on deletedplate(facility,inventoryclass);
exit;
