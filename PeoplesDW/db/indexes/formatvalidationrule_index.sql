--
-- $Id$
--
drop index formatvalidationrule_unique;

create unique index formatvalidationrule_unique on formatvalidationrule
   (ruleid);

exit;
