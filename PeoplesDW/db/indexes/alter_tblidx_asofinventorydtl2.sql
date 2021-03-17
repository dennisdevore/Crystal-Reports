--
-- $Id$
--
create index asofinventorydtl_item_idx
   on asofinventorydtl(facility,custid,item,effdate);
exit;
