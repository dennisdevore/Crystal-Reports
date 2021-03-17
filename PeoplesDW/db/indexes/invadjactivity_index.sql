--
-- $Id$
--
drop index invadjactivity_when_idx;
create index invadjactivity_when_idx
       on invadjactivity(whenoccurred);
drop index invadjactivity_custid_idx;
create index invadjactivity_custid_idx
       on invadjactivity(custid,item);
exit;
