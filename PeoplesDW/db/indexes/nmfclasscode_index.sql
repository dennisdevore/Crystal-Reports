--
-- $Id$
--
drop index nmfclasscodes_unique;

create unique index nmfclasscodes_unique
   on nmfclasscodes(nmfc);

exit;
