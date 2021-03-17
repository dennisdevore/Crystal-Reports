--
-- $Id$
--
drop index sectionsearch_unique;

create unique index sectionsearch_unique on sectionsearch
   (facility, sectionid);

exit;
