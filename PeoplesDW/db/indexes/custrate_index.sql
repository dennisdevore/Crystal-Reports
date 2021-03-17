--
-- $Id$
--
drop index custrate_unique;

create unique index custrate_unique
   on custrate(custid,rategroup,effdate,activity,billmethod) reverse;

drop index custrate_activity;

create index custrate_activity
   on custrate(custid,rategroup,activity,billmethod);

exit;