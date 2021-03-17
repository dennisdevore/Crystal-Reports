--
-- $Id$
--
create index shippingplate_statusitem_idx
   on shippingplate(status,facility,custid,item);
exit;
