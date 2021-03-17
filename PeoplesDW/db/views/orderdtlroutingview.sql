create or replace view orderdtlroutingview
(
   orderid,
   shipid,
   item,
   lotnumber,
   qtyorder,
   weightorder,
   itmpassthrunum01,
   qtyorder_cs,
   qtyorder_pl
)
as
   select od.orderid,
          od.shipid,
          od.item,
          od.custid,
          nvl(od.lotnumber, '(none)'),
          od.qtyorder,
          ci.itmpassthrunum01,
          nvl (zlbl.uom_qty_conv (od.custid, od.item, nvl(od.qtyorder, 0), od.uom, 'CS'), 0),
          nvl (zlbl.uom_qty_conv (od.custid, od.item, nvl(od.qtyorder, 0), od.uom, 'PL'), 0)
     from orderdtl od, 
          custitem ci
    where od.custid = ci.custid
      and od.item = ci.item;

comment on table orderdtlroutingview is '$Id: orderdtlroutingview.sql 7945 2012-02-09 21:30:05Z eric $';
