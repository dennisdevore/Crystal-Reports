create or replace view lbl_scc14_ctn_view
(
   orderid,
   shipid,
   sscc14,
   shiptoname,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   shiptoaddr3,
   dc,
   carriername,
   shipdate,
   item,
   wmit,
   po,
   reference,
   type,
   dept,
   loc,
   loadno,
   prono,
   bol,
   custname,
   custaddr1,
   custaddr2,
   custcity,
   custstate,
   custpostalcode,
   whsename,
   whseaddr1,
   whseaddr2,
   whsecity,
   whsestate,
   whsepostalcode,
   whseaddr3,
   packunits,
   seq,
   seqof,
   bigseq,
   bigseqof,
   descr,
   zipbarcode,
   ziphumancode,
   shipfromname
)
as
select
   OD.orderid,
   OD.shipid,
   zedi.get_sscc14_code('0',OD.dtlpassthruchar09),
   decode(CN.consignee, null, OH.shiptoname, CN.name),
   decode(CN.consignee, null, OH.shiptoaddr1, CN.addr1),
   decode(CN.consignee, null, OH.shiptoaddr2, CN.addr2),
   decode(CN.consignee, null, OH.shiptocity, CN.city),
   decode(CN.consignee, null, OH.shiptostate, CN.state),
   decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode),
   decode(CN.consignee, null, OH.shiptocity, CN.city) || ', '
      || decode(CN.consignee, null, OH.shiptostate, CN.state) || ' '
      || decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode),
   substr(decode(CN.consignee, null, OH.shiptoname, CN.name),
          instr(decode(CN.consignee, null, OH.shiptoname, CN.name),'DC',-1)),
   CA.name,
   OH.shipdate,
   OD.item,
   nvl(OD.consigneesku, WM.wmit),
   OH.po,
   OH.reference,
   OH.hdrpassthruchar10,
   OH.hdrpassthruchar02,
   OH.hdrpassthruchar09,
   OH.loadno,
   L.prono,
   OH.orderid||'-'||OH.shipid,
   CU.name,
   CU.addr1,
   CU.addr2,
   CU.city,
   CU.state,
   CU.postalcode,
   FA.name,
   FA.addr1,
   FA.addr2,
   FA.city,
   FA.state,
   FA.postalcode,
   FA.city || ', ' || FA.state || ' ' || FA.postalcode,
   CI.abbrev,
   OD.seq,
   OD.seqof,
   OD.bigseq,
   OD.bigseqof,
   CI.descr,
   '420' || substr(decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode), 1, 5),
   '(420)' || substr(decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode), 1, 5),
   'C/O ' || FA.name
from loads L,
     carrier CA,
     consignee CN,
     customer CU,
     facility FA,
     custitem CI,
     custitemwmitview WM,
     orderhdr OH,
     orderdtlseqview OD
where OH.shipto = CN.consignee(+)
  and OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OH.loadno = L.loadno(+)
  and OH.ordertype = 'O'
  and OD.custid = WM.custid(+)
  and OD.item = WM.item(+)
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+)
  and OH.carrier = CA.carrier(+)
  and OH.custid = CU.custid(+)
  and OH.fromfacility = FA.facility(+)
  and not exists (select * from shippingplate where orderid = OH.orderid and shipid = OH.shipid
                     and status in ('U', 'P'));

comment on table lbl_scc14_ctn_view is '$Id';

exit;
