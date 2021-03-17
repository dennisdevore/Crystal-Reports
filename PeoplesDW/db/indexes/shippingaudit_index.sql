--
-- $Id$
--
drop index shippingaudit_lpid;

create index shippingaudit_lpid on shippingaudit
   (lpid);

drop index shippingaudit_toplpid;

create index shippingaudit_toplpid on shippingaudit
   (toplpid);

exit;
