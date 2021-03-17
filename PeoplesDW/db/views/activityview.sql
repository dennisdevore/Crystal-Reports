create or replace view activityview
(
code,
descr,
abbrev,
glacct,
lastuser,
lastupdate,
mincategory,
mincategoryabbrev
)
as
select
activity.code,
activity.descr,
activity.abbrev,
activity.glacct,
activity.lastuser,
activity.lastupdate,
activity.mincategory,
activityminimumcategory.abbrev
from activity, activityminimumcategory
where activity.mincategory = activityminimumcategory.code(+);

comment on table activityview is '$Id$';

exit;
