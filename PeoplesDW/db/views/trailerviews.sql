create or replace view trailerview
(TRAILER_NUMBER
,TRAILER_LPID
,FACILITY
,LOCATION
,CARRIER
,CONTENTS_STATUS
,TRAILER_STATUS
,LOADNO
,STYLE
,TRAILER_TYPE
,DISPOSITION
,ACTIVITY_TYPE
,EXPECTED_TIME_IN
,GATE_TIME_IN
,EXPECTED_TIME_OUT
,GATE_TIME_OUT
,PUT_ON_WATER
,ETA_TO_PORT
,ARRIVED_AT_PORT
,LAST_FREE_DATE
,CARRIER_CONTACT_DATE
,ARRIVED_IN_YARD
,APPOINTMENT_DATE
,DUE_BACK
,RETURNED_TO_PORT
,LASTUSER
,LASTUPDATE
,TRAILER_STATUS_ABBREV
,DISPOSITION_ABBREV
,STYLE_ABBREV
,TRAILER_TYPE_ABBREV
,CONTENTS_STATUS_ABBREV
,ACTIVITY_TYPE_ABBREV
)
as
select
  t.TRAILER_NUMBER,t.TRAILER_LPID,t.FACILITY,t.LOCATION,t.CARRIER,
  t.CONTENTS_STATUS,t.TRAILER_STATUS,t.LOADNO,t.STYLE,t.TRAILER_TYPE,
  t.DISPOSITION,t.ACTIVITY_TYPE,t.EXPECTED_TIME_IN,t.GATE_TIME_IN,
  t.EXPECTED_TIME_OUT,t.GATE_TIME_OUT,t.PUT_ON_WATER,t.ETA_TO_PORT,
  t.ARRIVED_AT_PORT,t.LAST_FREE_DATE,t.CARRIER_CONTACT_DATE,t.ARRIVED_IN_YARD,
  t.APPOINTMENT_DATE,t.DUE_BACK,t.RETURNED_TO_PORT,t.LASTUSER,t.LASTUPDATE,
  nvl(trst.abbrev,t.trailer_status),
  nvl(trdi.abbrev,t.disposition),
  nvl(trsty.abbrev,t.style),
  nvl(trty.abbrev,t.trailer_type),
  nvl(cs.abbrev,t.contents_status),
  nvl(tat.abbrev,t.activity_type)
from trailer_status trst, trailer_dispositions trdi, trailer_styles trsty,
     trailer_types trty, contents_status cs, trailer_activity_types tat,
     trailer t
where t.trailer_status = trst.code(+)
  and t.disposition = trdi.code(+)
  and t.style = trsty.code(+)
  and t.trailer_type = trty.code(+)
  and t.contents_status = cs.code(+)
  and t.activity_type = tat.code(+);

comment on table trailerview is '$Id: trailerview.sql 1416 2006-12-19 23:11:38Z ed $';

create or replace view trailer_historyview
(TRAILER_NUMBER
,ACTIVITY_TIME
,TRAILER_LPID
,FACILITY
,LOCATION
,CARRIER
,CONTENTS_STATUS
,TRAILER_STATUS
,LOADNO
,STYLE
,TRAILER_TYPE
,DISPOSITION
,ACTIVITY_TYPE
,EXPECTED_TIME_IN
,GATE_TIME_IN
,EXPECTED_TIME_OUT
,GATE_TIME_OUT
,PUT_ON_WATER
,ETA_TO_PORT
,ARRIVED_AT_PORT
,LAST_FREE_DATE
,CARRIER_CONTACT_DATE
,ARRIVED_IN_YARD
,APPOINTMENT_DATE
,DUE_BACK
,RETURNED_TO_PORT
,LASTUSER
,LASTUPDATE
,TRAILER_STATUS_ABBREV
,DISPOSITION_ABBREV
,STYLE_ABBREV
,TRAILER_TYPE_ABBREV
,CONTENTS_STATUS_ABBREV
,ACTIVITY_TYPE_ABBREV
)
as
select
  t.TRAILER_NUMBER,t.ACTIVITY_TIME,t.TRAILER_LPID,t.FACILITY,t.LOCATION,t.CARRIER,
  t.CONTENTS_STATUS,t.TRAILER_STATUS,t.LOADNO,t.STYLE,t.TRAILER_TYPE,
  t.DISPOSITION,t.ACTIVITY_TYPE,t.EXPECTED_TIME_IN,t.GATE_TIME_IN,
  t.EXPECTED_TIME_OUT,t.GATE_TIME_OUT,t.PUT_ON_WATER,t.ETA_TO_PORT,
  t.ARRIVED_AT_PORT,t.LAST_FREE_DATE,t.CARRIER_CONTACT_DATE,t.ARRIVED_IN_YARD,
  t.APPOINTMENT_DATE,t.DUE_BACK,t.RETURNED_TO_PORT,t.LASTUSER,t.LASTUPDATE,
  nvl(trst.abbrev,t.trailer_status),
  nvl(trdi.abbrev,t.disposition),
  nvl(trsty.abbrev,t.style),
  nvl(trty.abbrev,t.trailer_type),
  nvl(cs.abbrev,t.contents_status),
  nvl(tat.abbrev,t.activity_type)
from trailer_status trst, trailer_dispositions trdi, trailer_styles trsty,
     trailer_types trty, contents_status cs, trailer_activity_types tat,
     trailer_history t
where t.trailer_status = trst.code(+)
  and t.disposition = trdi.code(+)
  and t.style = trsty.code(+)
  and t.trailer_type = trty.code(+)
  and t.contents_status = cs.code(+)
  and t.activity_type = tat.code(+);

comment on table trailer_historyview is '$Id: trailerhistoryview.sql 1416 2006-12-19 23:11:38Z ed $';

create or replace view yardview
(facility
,location
,trailer_lpid
,trailer_number
,carrier
,contents_status_abbrev
,contents_status
,loadno
,expected_time_out
,trailer_status_abbrev
,trailer_status
,location_status
,loctype
)
as
select
l.facility as facility,
l.locid as location,
t.trailer_lpid,
t.trailer_number,
t.carrier,
t.contents_status_abbrev,
t.contents_status,
t.loadno,
t.expected_time_out,
nvl(t.trailer_status_abbrev, '(empty loc.)') as trailer_status_abbrev,
t.trailer_status,
l.status,
nvl(l.loctype,'n0n')
from TrailerView t, location l
where t.facility = l.facility(+)
and t.location = l.locid(+);
exit;

