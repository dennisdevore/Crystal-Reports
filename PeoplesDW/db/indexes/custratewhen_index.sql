--
-- $Id$
--
drop index custratewhen_unique;

create unique index custratewhen_unique
   on custratewhen(custid,rategroup,effdate,activity,billmethod,businessevent);
exit;
