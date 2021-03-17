create or replace view orderhdrbolcommentsview
(
    orderid,
    shipid,
    bolcomment
)
as
select
    OH.orderid,
    OH.shipid,
    zbol.orderhdrbolcomments(OH.orderid,OH.shipid)
from
    orderhdrbolcomments OH;

comment on table loadsbolcommentsview is '$Id$';

exit;
