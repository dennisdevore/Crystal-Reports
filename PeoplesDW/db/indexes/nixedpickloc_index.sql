--
-- $Id$
--
drop index nixedpickloc_lpid;
create index nixedpickloc_lpid on nixedpickloc
   (nameid, facility);

exit;
