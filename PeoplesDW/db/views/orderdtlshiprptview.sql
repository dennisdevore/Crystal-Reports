create or replace view orderdtlshiprptview
(
ORDERID,
SHIPID,
ITEM,
LOTNUMBER,
LOTNUMBERNOTNULL,
CUSTID,
QTYORDER,
QTYSHIP,
UOM,
CASESSHIP
)
as
select
ORDERID,
SHIPID,
ITEM,
LOTNUMBER,
nvl(LOTNUMBER,'(none)'),
CUSTID,
QTYORDER,
QTYSHIP,
UOM,
nvl(zlbl.uom_qty_conv(custid, item, qtyship, uom, 'CS'),0)
from orderdtl od;

comment on table orderdtlshiprptview is '$Id: orderdtlshiprptview.sql 1416 2007-01-10 00:00:00Z eric $';

exit;
