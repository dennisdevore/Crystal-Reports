create or replace view outcustcmtview
(
    orderid,
    shipid,
    OHC_comment,
    CI_custid,
    CI_comment,
    CID_custid,
    CID_comment
)
as
select
    OH.orderid,
    OH.shipid,
    OH.comment1,
    CI.custid,
    CI.comment1,
    CID.custid,
    CID.comment1
from
    orderhdr OH,
    custitemoutcomments CI,
    custitemoutcomments CID
where
    OH.custid = CI.custid(+) and
    CI.item(+) = 'default' and
    nvl(OH.consignee, OH.shipto) = CI.consignee(+) and
    OH.custid = CID.custid(+) and
    CID.item(+) = 'default' and
    CID.consignee(+) = 'default';

comment on table outcustcmtview is '$Id';

exit;

