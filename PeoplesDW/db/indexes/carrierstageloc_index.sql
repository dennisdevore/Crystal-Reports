--
-- $Id$
--
drop index carrierstageloc_unique;
create unique index carrierstageloc_unique
   on carrierstageloc(carrier,facility,shiptype);
exit;