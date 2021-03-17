--
-- $Id$
--
drop index deletedplate_unique;
create unique index deletedplate_unique on deletedplate
   (lpid);

exit;
