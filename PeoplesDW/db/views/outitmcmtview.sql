create or replace view outitmcmtview
(
    orderid,
    shipid,
    item,
    lotnumber,
    OD_comment,
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
    OD.comment1,
    CI.item,
    CI.comment1,
    CID.item,
    CID.comment1
from
    outitmview OD,
    custitemoutcomments CI,
    custitemoutcomments CID
where
    OD.custid = CI.custid(+) and
    OD.item = CI.item(+) and
    nvl(OD.consignee, OD.shipto) = CI.consignee(+) and
    OD.custid = CID.custid(+) and
    OD.item = CID.item(+) and
    CID.consignee(+) = 'default';

comment on table outitmcmtview is '$Id';

exit;

