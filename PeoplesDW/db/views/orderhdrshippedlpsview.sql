create or replace view ORDERHDRSHIPPEDLPSVIEW
(ORDERID
,SHIPID
,CUSTID
,FROMFACILITY
,ORDERTYPE
,ORDERSTATUS
,SHIPTYPE
,SHIPPEDMASTERS
,SHIPPEDCARTONS
,SHIPPEDPARENTS
,SHIPPEDPARCELLIPS
,SHIPPEDNONPARCELLIPS
) as
select
orderid,
shipid,
custid,
fromfacility,
ordertype,
orderstatus,
shiptype,
(select count(1)
   from shippingplate
  where orderid = oh.orderid
    and shipid = oh.shipid
    and status = 'SH'
    and type = 'M'),
(select count(1)
   from shippingplate
  where orderid = oh.orderid
    and shipid = oh.shipid
    and status = 'SH'
    and type = 'C'),
(select count(1)
   from shippingplate
  where orderid = oh.orderid
    and shipid = oh.shipid
    and status = 'SH'
    and parentlpid is null),
(select count(1)
   from shippingplate
  where orderid = oh.orderid
    and shipid = oh.shipid
    and oh.shiptype = 'S'
    and status = 'SH'
    and parentlpid is null),
(select count(1)
   from shippingplate
  where orderid = oh.orderid
    and shipid = oh.shipid
    and oh.shiptype <> 'S'
    and status = 'SH'
    and parentlpid is null)
from orderhdr oh
/
exit;
