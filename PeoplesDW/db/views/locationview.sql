create or replace view locationview
(facility
,locid
,locationstatus
,locationstatusabbrev
,locationdescr
,loctypeabbrev
,storagetypeabbrev
,velocity
,section
,pickingzone
,putawayzone
,checkdigit
,loctype
,putawayseq
,pickingseq
,storagetype
,equipprof
,unitofstorage
,aisle
)
as
select
location.facility,
location.locid,
location.status,
locationstatus.abbrev,
location.descr,
locationtypes.abbrev,
storagetypes.abbrev,
location.velocity,
section,
pickingzone,
putawayzone,
checkdigit,
loctype,
putawayseq,
pickingseq,
storagetype,
equipprof,
unitofstorage,
aisle
from location, locationstatus,
     locationtypes, storagetypes
where location.status = locationstatus.code (+)
  and location.loctype = locationtypes.code (+)
  and location.storagetype = storagetypes.code (+);
  
comment on table locationview is '$Id';
  
exit;
