create or replace view bolitmview
(
    orderid,
    shipid,
    item,
    lotnumber,
    custid,
    consignee
)
as 
select
    OD.orderid,
    OD.shipid,
    OD.item,
    OD.lotnumber,
    OD.custid,
    zbol.order_consignee(OD.orderid, OD.shipid)
from
    orderdtl OD;
    
comment on table bolitmview is '$Id$';
    
exit;

