--
-- $Id$
--
drop index aisle_unique;

create unique index aisle_unique on aisle
	(facility, aisleid);

exit;
