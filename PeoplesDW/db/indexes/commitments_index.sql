--
-- $Id$
--
drop index commitments_facility_idx;

drop index commitments_custid_idx;

drop index commitments_order_idx;

create index commitments_facility_idx
   on commitments(facility,custid,item,
                  inventoryclass,invstatus,status,
                  lotnumber);

create index commitments_custid_idx
   on commitments(custid,item,
                  inventoryclass,invstatus,status,
                  lotnumber,facility);

create unique index commitments_order_idx
  on commitments(orderid,shipid,orderitem,orderlot,item,lotnumber,
    inventoryclass,invstatus,status);
   
exit;
