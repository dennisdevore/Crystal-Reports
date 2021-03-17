create or replace view itempickview
(
    custid,
    item,
    pickdate,
    qtypick
)
as
select D.custid,
       D.item,
       trunc(H.dateshipped),
       sum(nvl(D.qtypick,0))
from orderhdr H, orderdtl D
where H.orderid = D.orderid
  and H.shipid = D.shipid
  AND H.ordertype = 'O'
group by D.custid, D.item, trunc(H.dateshipped);

comment on table itempickview is '$Id$';

exit;
