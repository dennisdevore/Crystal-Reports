create or replace view massmansmallpackageview
(
   loadno,              -- Really WAVE but we need to fake out importexport
   fromfacility,
   cartonid,
   item,
   reference,
   po,
   shiptoname,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   shiptocountrycode,
   estweight,
   carrier,
   terms,
   sku,
   seq,
   orderid
)
as
select
   MM.wave,
   OH.fromfacility,
   MD.cartonid,
   MM.item,
   MH.reference,
   MH.po,
   MH.shiptoname,
   MH.shiptoaddr1,
   MH.shiptoaddr2,
   MH.shiptocity,
   MH.shiptostate,
   MH.shiptopostalcode,
   MH.shiptocountrycode,
   MD.estweight,
   MH.carriercode,
   MH.terms,
   CI.itmpassthruchar01,
   MM.seq,
   OH.orderid
from mass_manifest_ctn MM,
     multishiphdr MH,
     orderhdr OH,
     multishipdtl MD,
     custitem CI
where MH.orderid = MM.orderid
  and MH.shipid = MM.shipid
  and OH.orderid = MM.orderid
  and OH.shipid = MM.shipid
  and MD.cartonid = MM.ctnid
  and CI.custid = OH.custid
  and CI.item = MM.item
  and 'N' = zcu.credit_hold(OH.custid);

comment on table massmansmallpackageview is '$Id$';

exit;
