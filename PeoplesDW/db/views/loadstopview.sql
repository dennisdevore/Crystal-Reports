create or replace view loadstopview
(
LOADNO,
STOPNO,
ENTRYDATE,
SHIPTO,
LOADSTOPSTATUS,
loadstopstatusabbrev,
STAGELOC,
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
LASTUSER,
LASTUPDATE,
STATUSUSER,
STATUSUPDATE,
facility,
loadtype,
loadtypeabbrev,
loadstoprowid
)
as
select
loadstop.LOADNO,
loadstop.STOPNO,
loadstop.ENTRYDATE,
loadstop.SHIPTO,
loadstop.LOADSTOPSTATUS,
loadstatus.abbrev,
nvl(loadstop.STAGELOC,loads.stageloc),
loadstop.QTYORDER,
loadstop.WEIGHTORDER,
loadstop.CUBEORDER,
loadstop.AMTORDER,
loadstop.QTYSHIP,
loadstop.WEIGHTSHIP,
loadstop.CUBESHIP,
loadstop.AMTSHIP,
loadstop.QTYRCVD,
loadstop.WEIGHTRCVD,
loadstop.CUBERCVD,
loadstop.AMTRCVD,
loadstop.COMMENT1,
loadstop.LASTUSER,
loadstop.LASTUPDATE,
loadstop.STATUSUSER,
loadstop.STATUSUPDATE,
loads.facility,
loads.loadtype,
loadtypes.abbrev,
loadstop.rowid
from  loads, loadtypes, loadstatus, loadstop
where loads.loadno = loadstop.loadno
  and loads.loadtype = loadtypes.code(+)
  and loadstop.loadstopstatus = loadstatus.code (+);
  
comment on table loadstopview is '$Id';
  
--exit;
