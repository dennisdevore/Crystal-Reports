--
-- $Id$
--
drop index shippingplate_subtask;
create index shippingplate_subtask on shippingplate
  (taskid,orderid,shipid,orderitem,orderlot);

exit;
