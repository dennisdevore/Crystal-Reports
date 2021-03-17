create or replace view ordercarrierview (orderid, shipid, carrier, logo,
    service, descr)
as
select O.orderid, O.shipid, O.carrier, C.logo, 
    O.deliveryservice, S.descr
from carrierservicecodes S, carrier C,orderhdr O
where O.carrier = C.carrier(+)
and O.carrier = S.carrier(+)
and O.deliveryservice = S.servicecode(+);
