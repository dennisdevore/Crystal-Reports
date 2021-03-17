--
-- $Id$
--
drop index labelprofileline_unique;

create unique index labelprofileline_unique on labelprofileline
   (profid, businessevent, uom, seq);

exit;
