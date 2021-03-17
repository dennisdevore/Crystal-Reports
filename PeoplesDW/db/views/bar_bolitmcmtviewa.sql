create or replace view bar_bolitmcmtviewa
(
   BOLITMCOMMENT,
   ITEM,
   LOTNUMBER,
   ORDERID,
   SHIPID
)
as
select
   OD.item,
   OD.orderid,
   OD.shipid,
   OD.lotnumber,
   zbol.bolcustitmcomments(OD.orderid, OD.shipid, OD.item, OD.lotnumber) as bolitmcomment
from orderdtl OD;

exit;
