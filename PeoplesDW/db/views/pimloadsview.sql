create or replace view pimloadsview (
loadstatusabbrev,
loadtypeabbrev,
billoflading,
loadtype,
loadno,
entrydate,
rcvddate,
billdate,
loadstatus,
trailer,
seal,
facility,
doorloc,
stageloc,
carrier,
source,
qtyorder,
weightorder,
cubeorder,
amtorder,
qtyship,
weightship,
cubeship,
amtship,
qtyrcvd,
weightrcvd,
cubercvd,
amtrcvd,
comment1,
statususer,
statusupdate,
lastuser,
lastupdate,
carriername,
loadsrowid,
unknownlipcount,
apptdate,
putonwater,
etatoport,
arrivedatport,
lastfreedate,
carriercontactdate,
arrivedinyard,
appointmentdate,
dueback,
returnedtoport,
freetimedays,
dailydemurrage,
trackforcustomer,
recent_loadno,
custid,
po,
reference,
ordershipdate,
orderapptdate
)
as
select
loadstatus.abbrev,
loadtypes.abbrev,
loads.billoflading,
loads.loadtype,
loads.loadno,
loads.entrydate,
loads.rcvddate,
loads.billdate,
loads.loadstatus,
loads.trailer,
loads.seal,
loads.facility,
loads.doorloc,
loads.stageloc,
loads.carrier,
loads.source,
loads.qtyorder,
loads.weightorder,
loads.cubeorder,
loads.amtorder,
loads.qtyship,
loads.weightship,
loads.cubeship,
loads.amtship,
loads.qtyrcvd,
loads.weightrcvd,
loads.cubercvd,
loads.amtrcvd,
loads.comment1,
loads.statususer,
loads.statusupdate,
loads.lastuser,
loads.lastupdate,
carrier.name,
loads.rowid,
zld.unknown_lip_count(loads.loadno),
loads.apptdate,
loads.putonwater,
loads.etatoport,
loads.arrivedatport,
loads.lastfreedate,
loads.carriercontactdate,
loads.arrivedinyard,
loads.appointmentdate,
loads.dueback,
loads.returnedtoport,
carrier.freetimedays,
carrier.dailydemurrage,
loads.trackforcustomer,
loads.recent_loadno,
decode((select count(distinct custid) as custcnt from orderhdr where loadno = loads.loadno),1,
       (select distinct custid from orderhdr where loadno = loads.loadno),'MULTI'),
decode((select count(1) from orderhdr where loadno = loads.loadno),1,
       (select po from orderhdr where loadno = loads.loadno),'MULTI'),
decode((select count(1) from orderhdr where loadno = loads.loadno),1,
       (select reference from orderhdr where loadno = loads.loadno),'MULTI'),
decode((select count(1) from orderhdr where loadno = loads.loadno),1,
       (select shipdate from orderhdr where loadno = loads.loadno),
       (select min(shipdate) from orderhdr where loadno = loads.loadno and shipdate is not null and
            abs(sysdate - shipdate) = (select min(abs(sysdate - shipdate)) from orderhdr where loadno = loads.loadno))),
decode((select count(1) from orderhdr where loadno = loads.loadno),1,
       (select apptdate from orderhdr where loadno = loads.loadno),
       (select min(apptdate) from orderhdr where loadno = loads.loadno and apptdate is not null and
            abs(sysdate - apptdate) = (select min(abs(sysdate - apptdate)) from orderhdr where loadno = loads.loadno)))
from loads, loadstatus, loadtypes, carrier
where loads.loadstatus = loadstatus.code (+)
  and loads.loadtype = loadtypes.code (+)
  and loads.carrier = carrier.carrier (+);

exit;