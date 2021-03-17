--
-- $Id$
--
drop index shippingplate_unique;
create unique index shippingplate_unique on shippingplate
   (lpid);

drop index shippingplate_location;
create index shippingplate_location on shippingplate
   (facility, location);

drop index shippingplate_order;
create index shippingplate_order on shippingplate
  (orderid,shipid,orderitem,orderlot);

drop index shippingplate_load;
create index shippingplate_load on shippingplate
  (loadno,stopno,shipno);

drop index shippingplate_subtask;
create index shippingplate_subtask on shippingplate
  (taskid,orderid,shipid,orderitem,orderlot);

drop index shippingplate_fromlpid;
create index shippingplate_fromlpid on shippingplate
  (fromlpid);

drop index shippingplate_parentlpid;
create index shippingplate_parentlpid on shippingplate
  (parentlpid);

exit;
