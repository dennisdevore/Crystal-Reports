--
-- $Id$
--
drop index plate_custitem_idx;

create index plate_custitem_idx on plate(custid, item, facility, serialnumber, location);

exit;
