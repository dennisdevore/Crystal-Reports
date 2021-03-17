create or replace view packlistitem
(
   orderid,
   shipid,
   custid,
   item,
   description,
   unitofmeasure,
   lotnumber,
   quantity,
   weight
)
as
select
       OH.orderid,
       OH.shipid,
       OH.custid,
       SP.item,
       CI.descr,
       SP.unitofmeasure,
       SP.lotnumber,
       SP.quantity,
       SP.weight
from
    orderhdr OH,
    custitem CI,
    shippingplate SP
where
    OH.orderid = SP.orderid(+) and
    OH.shipid = SP.shipid(+) and
    OH.custid = SP.custid(+) and
    SP.custid = CI.custid(+) and
    SP.item = CI.item(+) and
    SP.type in ('F', 'P') and
    (OH.orderstatus = '8' or
    OH.orderstatus = '9');

comment on table packlistitem is '$Id$';

 exit;

