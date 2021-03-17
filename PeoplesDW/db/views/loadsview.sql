create or replace view loadsview
(
loadstatusabbrev,
loadtypeabbrev,
BILLOFLADING,
LOADTYPE,
LOADNO,
ENTRYDATE,
RCVDDATE,
BILLDATE,
LOADSTATUS,
TRAILER,
SEAL,
FACILITY,
DOORLOC,
STAGELOC,
CARRIER,
SOURCE,
QTYORDER,
WEIGHTORDER,
CUBEORDER,
AMTORDER,
QTYSHIP,
WEIGHTSHIP,
CUBESHIP,
AMTSHIP,
QTYRCVD,
WEIGHTRCVD,
CUBERCVD,
AMTRCVD,
COMMENT1,
STATUSUSER,
STATUSUPDATE,
LASTUSER,
LASTUPDATE,
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
liveunload,
etatofacility,
orderid,
custpo,
reference,
scheduledshipdate,
outbound_arrivaldate,
drop_type
)
as
select
loadstatus.abbrev,
loadtypes.abbrev,
BILLOFLADING,
LOADTYPE,
LOADNO,
ENTRYDATE,
RCVDDATE,
BILLDATE,
LOADSTATUS,
TRAILER,
SEAL,
FACILITY,
DOORLOC,
STAGELOC,
loads.CARRIER,
SOURCE,
QTYORDER,
WEIGHTORDER,
CUBEORDER,
AMTORDER,
QTYSHIP,
WEIGHTSHIP,
CUBESHIP,
AMTSHIP,
QTYRCVD,
WEIGHTRCVD,
CUBERCVD,
AMTRCVD,
COMMENT1,
STATUSUSER,
STATUSUPDATE,
loads.LASTUSER,
loads.LASTUPDATE,
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
loads.liveunload,
loads.etatofacility,
case when (select count(1) 
             from orderhdr oh
             where oh.loadno = loads.loadno) = 1 
     then (select to_char(orderid) 
                 from orderhdr where orderhdr.loadno = loads.loadno) 
     else 'MULTI' end,
case when (select count(1) 
             from orderhdr oh
             where oh.loadno = loads.loadno) = 1 
     then (select po 
                 from orderhdr where orderhdr.loadno = loads.loadno) 
     else 'MULTI' end,
case when (select count(1) 
             from orderhdr oh
             where oh.loadno = loads.loadno) = 1 
     then (select reference 
                 from orderhdr where orderhdr.loadno = loads.loadno) 
     else 'MULTI' end,
case when (select count(1) 
             from orderhdr oh
             where oh.loadno = loads.loadno) = 1 
     then (select to_char(shipdate, 'mm/dd/yyyy')
                 from orderhdr where orderhdr.loadno = loads.loadno) 
     else 'MULTI' end,
zld.outbound_arrivaldate(loads.loadno),
loads.drop_type
from loads, loadstatus, loadtypes, carrier
where loads.loadstatus = loadstatus.code (+)
  and loads.loadtype = loadtypes.code (+)
  and loads.carrier = carrier.carrier (+);
  
comment on table loadsview is '$Id';
  
-- exit;
