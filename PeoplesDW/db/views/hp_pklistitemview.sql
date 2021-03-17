create or replace view hppacklistitem
(
   orderid, 
   shipid, 
   custid,
   item, 
   description,
   unitofmeasure,
   lotnumber,
   quantity, 
   weight,
   unitamount,
   serialnumber,
   trackingno
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
       SP.weight,
       OD.dtlpassthrunum01,
       SP.serialnumber,
       SP.trackingno
from
    orderhdr OH,
    custitem CI,
    orderdtl OD,
    shippingplate SP
where
    OH.orderid = SP.orderid(+) and
    OH.shipid = SP.shipid(+) and
    OH.custid = SP.custid(+) and
    SP.orderid = OD.orderid(+) and
    SP.shipid = OD.shipid(+) and
    SP.item = OD.item(+) and
    nvl(SP.lotnumber,'(none)') = nvl(OD.lotnumber(+),'(none)') and
    SP.custid = CI.custid(+) and
    SP.item = CI.item(+) and
    SP.type in ('F', 'P') and
    (OH.orderstatus = '8' or
    OH.orderstatus = '9');

comment on table hppacklistitem is '$Id$';

-- exit;

