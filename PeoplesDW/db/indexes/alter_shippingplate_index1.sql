--
-- $Id$
--
create index shippingplate_invstatus_idx
   on shippingplate(facility,invstatus);
create index shippingplate_invclass_idx
   on shippingplate(facility,inventoryclass);
exit;
