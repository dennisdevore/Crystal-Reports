--
-- $Id$
--
drop index custconsignee_unique;

create unique index custconsignee_unique
on custconsignee(custid,consignee);

exit;
