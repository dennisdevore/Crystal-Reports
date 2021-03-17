--
-- $Id$
--
drop index custitemlabelprofiles_unique;

create unique index custitemlabelprofiles_unique
on custitemlabelprofiles(custid,item,consignee);

exit;

