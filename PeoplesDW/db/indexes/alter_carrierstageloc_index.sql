--
-- $Id$
--
drop index carrierstageloc_unique;
create index carrierstageloc_unique
on carrierstageloc(carrier,facility,shiptype);
exit;

