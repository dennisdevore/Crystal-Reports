create or replace view bolitmcmtview
(
    orderid,
    shipid,
    item,
    lotnumber,
    ODC_item,
    ODC_comment,
    CI_item,
    CI_comment,
    CID_item,
    CID_comment
)
as
select
    OD.orderid,
    OD.shipid,
    OD.item,
    nvl(OD.lotnumber,'**NULL**'),
    ODC.item,
    ODC.bolcomment,
    CI.item,
    CI.comment1,
    CID.item,
    CID.comment1
from
    orderdtlbolcomments ODC,
    custitembolcomments CI,
    custitembolcomments CID,
    bolitmview OD
where
    OD.orderid = ODC.orderid(+) and
    OD.shipid = ODC.shipid(+) and
    OD.item = ODC.item(+) and
    nvl(OD.lotnumber,'*NULL*') = nvl(ODC.lotnumber(+),'*NULL*') and
    OD.custid = CI.custid(+) and
    OD.item = CI.item(+) and
    OD.consignee = CI.consignee(+) and
    OD.custid = CID.custid(+) and
    OD.item = CID.item(+) and
    CID.consignee(+) = 'default';

comment on table bolitmcmtview is '$Id$';

    create or replace view bolitmcmtviewA
    (
        orderid,
        shipid,
        item,
        lotnumber,
        bolitmcomment
    ) as
            select
                  OD.orderid,
                  OD.shipid,
                  OD.item,
		  nvl(OD.lotnumber,'**NULL**'),
                   zbol.bolcustitmcomments(OD.orderid,
                           OD.shipid,OD.item,OD.lotnumber) as bolitmcomment
            from orderdtl OD;
comment on table bolitmcmtviewA is '$Id$';
exit;
