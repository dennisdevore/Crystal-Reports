--
-- $Id$
--
drop index nixedputloc_lpid;
create index nixedputloc_lpid on nixedputloc
   (lpid, facility, location);

exit;
