create or replace view dre_ordercheckview
(
   orderid,
   shipid,
   lpid,
   custid,
   item,
   itemdesc,
   lotnumber,
   quantity,
   unitofmeasure,
   location,
   qtyentered,
   loadno,
   grossweight
)
as
select S.orderid,
       S.shipid,
       ordercheckview_lpid(lpid, type, fromlpid, parentlpid),
       S.custid,
       S.item,
       CI.descr,
       S.lotnumber,
       sum(S.quantity),
       S.unitofmeasure,
       S.location,
       sum(S.qtyentered),
	     S.loadno,
	     sum(S.weight + (nvl(zlbl.uom_qty_conv(S.custid,S.item,S.quantity,S.unitofmeasure,CI.baseuom),0) * nvl(CI.tareweight,0)))
   from shippingplate S, custitem CI
   where S.type in ('F', 'P')
     and S.status = 'S'
     and CI.custid = S.custid
     and CI.item = S.item
   group by S.orderid,
            S.shipid,
            ordercheckview_lpid(lpid, type, fromlpid, parentlpid),
            S.custid,
            S.item,
            CI.descr,
            S.lotnumber,
            S.unitofmeasure,
            S.location,
            S.loadno;

exit;
