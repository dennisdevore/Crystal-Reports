--
-- $Id$
--
drop index pk_printer;
drop index printer_unique;

create unique index printer_unique
on printer(prtid);
exit;
