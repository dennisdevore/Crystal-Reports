create or replace view lbl_bp_cs_view
(
   orderid,
   shipid,
   custname,
   whsename,
   whseaddr1,
   whseaddr2,
   whseaddr3,
   shiptoname,
   shiptoaddr1,
   shiptoaddr2,
   shiptoaddr3,
   vendorno,
   ziphumancode,
   zipbarcode,
   carrier,
   bol,
   loadno,
   loc,
   type,
   dept,
   po,
   wmit,
   stkno,
   scc14,
   seq,
   seqof
)
as
select
   OD.orderid,
   OD.shipid,
   CU.name,
   'C/O ' || FA.name,
   FA.addr1,
   FA.addr2,
   FA.city || ', ' || FA.state || ' ' || FA.postalcode,
   decode(CN.consignee, null, OH.shiptoname, CN.name),
   decode(CN.consignee, null, OH.shiptoaddr1, CN.addr1),
   decode(CN.consignee, null, OH.shiptoaddr2, CN.addr2),
   decode(CN.consignee, null, OH.shiptocity, CN.city) || ', '
      || decode(CN.consignee, null, OH.shiptostate, CN.state) || ' '
      || decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode),
   'VENDOR#: ' || zlbl.extract_word(decode(CN.consignee, null, OH.shiptoaddr2, CN.addr2), 2),
   '(420) ' || substr(decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode), 1, 5),
   '420' || substr(decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode), 1, 5),
   OH.carrier,
   OH.orderid||'-'||OH.shipid,
   OH.loadno,
   OH.hdrpassthruchar09,
   OH.hdrpassthruchar12,
   OH.hdrpassthruchar02,
   OH.po,
   OD.dtlpassthruchar01,
   OD.item,
   '1'||substr(zedi.get_sscc14_code('0','000000'|| substr(LPAD(substr(decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode), 1, 5),300,'0'),-5,5)),2),
   OD.seq,
   OD.seqof
from orderhdr OH,
     consignee CN,
     customer CU,
     facility FA,
     custitem CI,
     (select D.orderid,
              D.shipid,
              D.custid,
              D.item,
              D.dtlpassthruchar01,
              D.dtlpassthruchar14,
              seq,
              zlbl.uom_qty_conv(D.custid, D.item, D.qtypick, D.uom, 'CS') seqof
         from zseq Z, orderdtl D, orderhdr H
        where D.orderid = H.orderid
          and D.shipid = H.shipid
          and Z.seq <= zlbl.uom_qty_conv(D.custid, D.item, D.qtypick, D.uom, 'CS')) OD
where OH.shipto = CN.consignee(+)
  and OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OH.ordertype = 'O'
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+)
  and OH.custid = CU.custid(+)
  and OH.fromfacility = FA.facility(+)
  and not exists (select * from shippingplate where orderid = OH.orderid and shipid = OH.shipid
                     and status in ('U', 'P'));

comment on table lbl_bp_cs_view is '$Id';

exit;


