--
-- $Id$
--
drop index chemicalcodes_unique;

create unique index chemicalcodes_unique
   on chemicalcodes(chemcode);


exit;
