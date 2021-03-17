create or replace view shipplatecontentsview
(
    lpid,
    orderid,
    shipid,
    custid,
    item,
    dtlpassthruchar09,
    consigneesku,
    quantity
)
as
select
    P.lpid,
    P.orderid,
    P.shipid,
    P.custid,
    C.item,
    OD.dtlpassthruchar09,
    OD.consigneesku,
    sum(C.quantity)
from orderdtl OD, shippingplate C, shippingplate P
where C.orderid = P.orderid
  and C.shipid = P.shipid
  and OD.orderid = C.orderid
  and OD.shipid = C.shipid
  and OD.item = C.orderitem
  and nvl(OD.lotnumber,'<NULL>') = nvl(C.orderlot,'<NULL>')
  and C.type in ('F','P')
  and zedi.check_ancestor(P.lpid, C.lpid) = 'Y'
group by P.lpid, P.orderid, P.shipid, P.custid, C.item, OD.dtlpassthruchar09,
    OD.consigneesku;

comment on table shipplatecontentsview is '$Id$';

create or replace view shipplateseqview
(
    lpid,
    orderid,
    shipid,
    custid,
    item,
    dtlpassthruchar09,
    consigneesku
)
as
select 
    lpid,
    orderid,
    shipid,
    custid,
    item,
    dtlpassthruchar09,
    consigneesku
from zseq, shipplatecontentsview
where zseq.seq <= quantity;

comment on table shipplateseqview is '$Id$';


-- exit;

