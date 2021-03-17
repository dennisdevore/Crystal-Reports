create or replace view invorderview
(
 orderid,
 shipid,
 reference,
 shiptoname
)
as
select O.orderid,
       O.shipid,
       O.reference,
       decode(O.shiptoname,null,CNS.name,O.shiptoname)
  from consignee CNS, orderhdr O
 where O.shipto = CNS.consignee(+);

comment on table invorderview is '$Id$';

exit;
