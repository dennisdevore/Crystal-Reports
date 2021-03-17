--
-- $Id$
--
drop index asofinventorydtl_index;
create index asofinventorydtl_index 
       on asofinventorydtl(facility,custid,item,lotnumber,uom,effdate,
          inventoryclass, invstatus);
exit;
