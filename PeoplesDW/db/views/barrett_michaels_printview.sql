create or replace view barrett_michaels_printview
(
   lpid,
   orderid,
   shipid,
   fromname,
   fromaddr,
   fromcsz,
   toname,
   toaddr,
   tocsz,
   po,
   sku,
   seq,
   seqof,
   item
)
as
select
   SP.lpid,
   BL.orderid,
   BL.shipid,
   BL.fromname,
   BL.fromaddr,
   BL.fromcsz,
   BL.toname,
   BL.toaddr,
   BL.tocsz,
   BL.po,
   BL.sku,
   BL.seq,
   BL.seqof,
   BL.item
from shippingplate SP,
     orderhdr OH,
     barrett_michaels_lblview BL
where OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and (BL.orderid, BL.shipid) in
         (select orderid, shipid from orderhdr where wave = OH.wave)
order by item, seq, orderid;

comment on table barrett_michaels_printview is '$Id';

exit;
