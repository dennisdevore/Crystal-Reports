create or replace view outitmview
(
    orderid,
    shipid,
    item,
    lotnumber,
    custid,
    consignee,
    shipto,
    comment1
)
as
select
    OD.orderid,
    OD.shipid,
    OD.item,
    OD.lotnumber,
    OD.custid,
    OH.consignee,
    OH.shipto,
    OD.comment1
from
    orderdtl OD,
    orderhdr OH
where
    OH.orderid = OD.orderid and
    OH.shipid = OD.shipid;

comment on table outitmview is '$Id';

exit;

