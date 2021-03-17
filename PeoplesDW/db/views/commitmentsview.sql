create or replace view commitmentsview
(FACILITY,
CUSTID,
ITEM,
INVENTORYCLASS,
INVSTATUS,
LOTNUMBER,
UOM,
QTY,
ORDERID,
SHIPID,
orderitem,
priority,
LASTUSER,
LASTUPDATE,
custname,
priorityabbrev,
inventoryclassabbrev,
invstatusabbrev,
uomabbrev,
orderlot
)
as
select
commitments.FACILITY,
commitments.CUSTID,
commitments.ITEM,
commitments.INVENTORYCLASS,
commitments.INVSTATUS,
commitments.LOTNUMBER,
commitments.UOM,
commitments.QTY,
commitments.ORDERID,
commitments.SHIPID,
commitments.orderitem,
commitments.priority,
commitments.LASTUSER,
commitments.LASTUPDATE,
customer.name,
orderpriority.abbrev,
inventoryclass.abbrev,
inventorystatus.abbrev,
unitsofmeasure.abbrev,
orderlot
from
commitments, customer, inventoryclass, inventorystatus,
unitsofmeasure, orderpriority
where commitments.custid = customer.custid(+)
  and commitments.inventoryclass = inventoryclass.code(+)
  and commitments.invstatus = inventorystatus.code(+)
  and commitments.uom = unitsofmeasure.code(+)
  and commitments.priority = orderpriority.code(+);

comment on table commitmentsview is '$Id$';

exit;
