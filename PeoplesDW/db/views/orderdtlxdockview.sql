create or replace view orderdtlxdockview
(
  orderid,
  shipid,
  item,
  lotnumber,
  qtyxdock
)
as
select xdockorderid,
       xdockshipid,
       item,
       lotnumber,
       sum(qtyorder)
from orderdtl
where xdockorderid is not null
group by
       xdockorderid,
       xdockshipid,
       item,
       lotnumber;

comment on table orderdtlxdockview is '$Id$';

exit;
