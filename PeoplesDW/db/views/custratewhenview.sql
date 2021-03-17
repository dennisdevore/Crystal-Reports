create or replace view custratewhenview
(
custid,
rategroup,
effdate,
activity,
billmethod,
businessevent,
automatic,
lastuser,
lastupdate,
businesseventabbrev,
automaticabbrev,
rategroupabbrev,
activityabbrev,
billmethodabbrev
)
as
select
custid
,rategroup
,effdate
,activity
,billmethod
,businessevent
,automatic
,custratewhen.lastuser
,custratewhen.lastupdate
,businessevents.abbrev
,autopromptvalues.abbrev
,substr(zrt.rategroup_abbrev(custratewhen.custid,custratewhen.rategroup),1,12)
,substr(zrt.activity_abbrev(custratewhen.activity),1,12)
,billingmethod.abbrev
from custratewhen, autopromptvalues, businessevents, billingmethod
where custratewhen.automatic = autopromptvalues.code(+)
and custratewhen.businessevent = businessevents.code(+)
and custratewhen.billmethod = billingmethod.code(+);

comment on table custratewhenview is '$Id$';

exit;
