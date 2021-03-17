--
-- $Id$
--
drop index shipdays_unique;
create unique index shipdays_unique
on shipdays(facility,postalkey);
exit;