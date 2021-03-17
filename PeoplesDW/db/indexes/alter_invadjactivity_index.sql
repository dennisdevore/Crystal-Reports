--
-- $Id$
--
drop index invadjactivity_lpid_idx;
create index invadjactivity_lpid_idx
       on invadjactivity(lpid);
exit;
