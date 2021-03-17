--
-- $Id$
--
create index asofinventory_item_idx
   on asofinventory(facility,custid,item,effdate);
exit;
