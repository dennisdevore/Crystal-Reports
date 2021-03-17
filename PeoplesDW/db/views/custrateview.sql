create or replace view custratesum
(
custid,
rategroup,
activity,
billmethod,
effdate
)
as
select custid, rategroup, activity, billmethod, max(effdate)
  from custrate
 group by custid, rategroup, activity, billmethod;

comment on table custratesum is '$Id$';

create or replace view custrateitemsum
(
custid,
rategroup,
effdate,
activity,
uom,
rate,
gracedays,
lastuser,
lastupdate,
activityabbrev,
rategroupabbrev,
uomabbrev,
billmethod,
billmethodabbrev,
calctype
)
as
select
custratesum.custid,
custratesum.rategroup,
custratesum.effdate,
custratesum.activity
,uom
,rate
,gracedays
,custrate.lastuser
,custrate.lastupdate
,substr(zrt.activity_abbrev(custratesum.activity),1,12)
,substr(zrt.rategroup_abbrev(custratesum.custid,custratesum.rategroup),1,12)
,substr(zit.uom_abbrev(uom),1,12)
,custratesum.billmethod
,substr(zrt.billmethod_abbrev(custratesum.billmethod),1,12)
,calctype
from custratesum, custrate
where custratesum.custid = custrate.custid
  and custratesum.rategroup = custrate.rategroup
  and custratesum.effdate = custrate.effdate
  and custratesum.activity = custrate.activity
  and custratesum.billmethod = custrate.billmethod;

comment on table custrateitemsum is '$Id$';

create or replace view custrateview
(
custid,
rategroup,
effdate,
activity,
uom,
rate,
gracedays,
lastuser,
lastupdate,
activityabbrev,
rategroupabbrev,
uomabbrev,
billmethod,
billmethodabbrev,
calctype
)
as
select
custid
,rategroup
,effdate
,activity
,uom
,rate
,gracedays
,custrate.lastuser
,custrate.lastupdate
,substr(zrt.activity_abbrev(custrate.activity),1,12)
,substr(zrt.rategroup_abbrev(custrate.custid,custrate.rategroup),1,12)
,substr(zit.uom_abbrev(uom),1,12)
,billmethod
,substr(zrt.billmethod_abbrev(billmethod),1,12)
,calctype
from custrate;

comment on table custrateview is '$Id$';

create or replace view custrateitemwhensum
(
custid,
rategroup,
effdate,
activity,
uom,
rate,
gracedays,
lastuser,
lastupdate,
activityabbrev,
rategroupabbrev,
uomabbrev,
billmethod,
billmethodabbrev,
businesseventabbrev,
automaticabbrev
)
as
select
custrateitemsum.custid,
custrateitemsum.rategroup,
custrateitemsum.effdate,
custrateitemsum.activity,
custrateitemsum.uom,
custrateitemsum.rate,
custrateitemsum.gracedays,
custrateitemsum.lastuser,
custrateitemsum.lastupdate,
custrateitemsum.activityabbrev,
custrateitemsum.rategroupabbrev,
custrateitemsum.uomabbrev,
custrateitemsum.billmethod,
custrateitemsum.billmethodabbrev,
nvl(custratewhenview.businesseventabbrev,'(none)'),
nvl(custratewhenview.automaticabbrev,'(none)')
from custrateitemsum, custratewhenview
where custrateitemsum.custid = custratewhenview.custid(+)
  and custrateitemsum.rategroup = custratewhenview.rategroup(+)
  and custrateitemsum.effdate = custratewhenview.effdate(+)
  and custrateitemsum.activity = custratewhenview.activity(+)
  and custrateitemsum.billmethod = custratewhenview.billmethod(+);

comment on table custrateitemwhensum is '$Id$';
  
exit;
