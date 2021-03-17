--
-- $Id$
--
drop index invadjactivity_when_idx;
create index invadjactivity_when_idx
   on invadjactivity(whenoccurred);
exit;
