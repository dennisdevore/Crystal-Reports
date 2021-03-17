--
-- $Id$
--
drop index custitemtot_unique_facility;

drop index custitemtot_unique_custid;

create unique index custitemtot_unique_facility
   on custitemtot(facility,custid,item,
                  inventoryclass,invstatus,status,
                  lotnumber,uom);

create unique index custitemtot_unique_custid
   on custitemtot(custid,item,
                  inventoryclass,invstatus,status,
                  lotnumber,uom,facility);
   
exit;
