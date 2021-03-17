--
-- $Id$
--
drop index printer_unique;

create unique index printer_unique on
   printer (facility, prtid);
exit;
