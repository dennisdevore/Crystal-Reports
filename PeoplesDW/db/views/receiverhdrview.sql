create or replace view receiverhdrview
(
ORDERID,                      
SHIPID,                       
CUSTID,                       
toFACILITY,                 
carrier,
doorloc,
loadno,
stopno,
shipno,
shipper,
document,
doclabel,
trailer,
seal,
rcvddate,
lotlabel,
itemlabel,
orderhdrrowid,
loadsrowid,
loadstoprowid,
loadstopshiprowid,
ordertype,
orderstatus,
trailernosetemp,
trailermiddletemp,
trailertailtemp,
reference,
shippername
)
as
select
orderhdr.ORDERID,                      
orderhdr.SHIPID,                       
orderhdr.CUSTID,                       
tofacility,
loadsview.carrier,
loadsview.doorloc,
orderhdr.loadno,
orderhdr.stopno,
orderhdr.shipno,
shipper,
decode(ordertype,'Q',rma,po),
decode(ordertype,'Q','RMA:',zcu.po_label(orderhdr.custid) || ':'),
loadsview.trailer,
loadsview.seal,
loadsview.rcvddate,
zcu.lot_label(orderhdr.custid),
zcu.item_label(orderhdr.custid),
orderhdr.rowid,
loadsview.loadsrowid,
loadstopview.loadstoprowid,
loadstopship.rowid,
ordertype,
orderstatus,
orderhdr.trailernosetemp,
orderhdr.trailermiddletemp,
orderhdr.trailertailtemp,
orderhdr.reference,
orderhdr.shippername
from orderhdr, loadsview, loadstopview, loadstopship
where orderhdr.loadno = loadsview.loadno (+)
  and orderhdr.loadno = loadstopview.loadno (+)
  and orderhdr.stopno = loadstopview.stopno (+)
  and orderhdr.loadno = loadstopship.loadno (+)
  and orderhdr.stopno = loadstopship.stopno (+)
  and orderhdr.shipno = loadstopship.shipno (+);
  
comment on table receiverhdrview is '$Id';
  
exit;
