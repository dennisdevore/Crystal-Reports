create or replace view loadstopstageview
(facility
,stageloc
,loadno
,stopno
,loadstopstatus
,loadtype
)
as
select
loadstop.facility,
nvl(loadstop.stageloc,loads.stageloc),
loadstop.loadno,
loadstop.stopno,
loadstop.loadstopstatus,
loads.loadtype
from loads, loadstop
where loads.loadno = loadstop.loadno
  and loadstop.loadstopstatus in ('2','3','4','5','6','7','A','E');

create or replace view stagelocview
(facility
,stageloc
,loadno
,stopno
,loadstatus
,loadstatusabbrev
,loadtype
,loadtypeabbrev
,locationstatus
,locationstatusabbrev
,locationdescr
)
as
select
location.facility,
location.locid,
loadstopstageview.loadno,
loadstopstageview.stopno,
loadstopstageview.loadstopstatus,
loadstatus.abbrev,
loadstopstageview.loadtype,
loadtypes.abbrev,
location.status,
locationstatus.abbrev,
location.descr
from loadstatus, loadtypes, locationstatus, loadstopstageview, location
where loadstopstageview.loadtype = loadtypes.code(+)
  and loadstopstageview.loadstopstatus = loadstatus.code (+)
  and location.loctype = 'STG'
  and location.status = locationstatus.code(+)
  and location.facility = loadstopstageview.facility(+)
  and location.locid = loadstopstageview.stageloc(+);

comment on table stagelocview is '$Id$';

exit;
exit;


