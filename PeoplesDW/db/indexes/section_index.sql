--
-- $Id$
--
drop index section_unique;

create unique index section_unique
   on section(facility,sectionid);

exit;
