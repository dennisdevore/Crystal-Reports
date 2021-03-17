create or replace view barrett_michaels_lblview
(
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
   MM.orderid,
   MM.shipid,
   CU.name,
   FA.addr1,
   FA.city||' '||FA.state||' '||FA.postalcode,
   OH.shiptoname,
   OH.shiptoaddr1,
   OH.shiptocity||' '||OH.shiptostate||' '||OH.shiptopostalcode,
   OH.po,
   CI.itmpassthruchar01,
   MM.seq,
   MM.seqof,
   MM.item
from mass_manifest_ctn MM,
     orderhdr OH,
     customer CU,
     facility FA,
     custitem CI
where OH.orderid = MM.orderid
  and OH.shipid = MM.shipid
  and CU.custid = OH.custid
  and OH.fromfacility = FA.facility
  and CI.custid = OH.custid
  and CI.item = MM.item;

comment on table barrett_michaels_lblview is '$Id';

exit;
