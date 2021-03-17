create or replace view handlingtypesview
(code
,descr
,abbrev
,activity
,activityabbrev
)
as
select
handlingtypes.code,
handlingtypes.descr,
handlingtypes.abbrev,
handlingtypes.activity,
activity.abbrev
from handlingtypes, activity
where handlingtypes.activity = activity.code(+);

comment on table handlingtypesview is '$Id$';

exit;
