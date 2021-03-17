--
-- $Id$
--
drop index asofinventory_index;
create unique index asofinventory_index 
       on asofinventory(facility,custid,item,lotnumber,uom,effdate,
       inventoryclass, invstatus);
exit;
