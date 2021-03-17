--
-- $Id$
--
create index shippingplate_lotnumber_idx
on shippingplate(lotnumber);
create index shippingplate_useritem1_idx
on shippingplate(useritem1);
create index shippingplate_useritem2_idx
on shippingplate(useritem2);
create index shippingplate_useritem3_idx
on shippingplate(useritem3);
exit;

