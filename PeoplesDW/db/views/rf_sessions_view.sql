create or replace view rf_sessions_view
(sessionid
,rf_type
,rf_userid
,linux_processid
,webrf_sessionid
,username
,facility
,lastlocation
,max_begtime
,max_endtime
)
as
select
rs.sessionid,
rs.rf_type,
rs.rf_userid,
rs.processid,
uh.session_id,
uh.username,
uh.facility,
uh.lastlocation,
zus.max_begtime(rs.rf_userid),
zus.max_endtime(rs.rf_userid)
from
rf_sessions rs, userheader uh
where upper(rs.rf_userid) = uh.nameid(+);
exit;
