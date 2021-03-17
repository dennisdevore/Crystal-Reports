--
-- $Id$
--
drop index plate_unique;
create unique index plate_unique on plate
   (lpid);

drop index plate_location;
create index plate_location on plate
   (facility, location);

drop index plate_destination;
create index plate_destination on plate
   (destfacility, destlocation);

drop index plate_customer;
create index plate_customer on plate
   (facility,custid,item,lotnumber,invstatus,inventoryclass);

drop index plate_order_item_idx;
create index plate_order_item_idx on plate
   (orderid,shipid,item,lotnumber);

drop index plate_controlnumber_idx;
create index plate_controlnumber_idx on plate
   (controlnumber);

exit;
