--
-- $Id$
--
drop index shipper_unique;

create unique index shipper_unique
on shipper(shipper);

exit;
