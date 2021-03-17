--
-- $Id$
--
drop index shippingplate_custitem;

create index shippingplate_custitem on shippingplate(facility, custid, item, lotnumber);

exit;
