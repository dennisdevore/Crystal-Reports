create or replace view lbl_bp_task_cs_view
(
   taskid,
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
   seqof,
   custid
)
as
select
   OD.taskid,
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
   OD.seqof,
   OD.custid
from orderhdr OH,
     consignee CN,
     customer CU,
     facility FA,
     custitem CI,
     (select SP.taskid,
             SP.orderid,
             SP.shipid,
             SP.custid,
             SP.item,
              D.dtlpassthruchar01,
              D.dtlpassthruchar14,
              Z.seq,
              zlbl.p1pk_qty_conv(SP.taskid, SP.custid, SP.item, D.uom, 'CS', 'Y') seqof
         from zseq Z, orderdtl D, shippingplate SP
        where D.orderid = SP.orderid
          and D.shipid = SP.shipid
          and D.item = SP.item
          and Z.seq > (select nvl(max(P1.seq), 0) from p1pkcaselabels P1
                        where P1.orderid = SP.orderid
                          and P1.shipid = SP.shipid
                          and P1.custid = SP.custid
                          and P1.item = SP.item)
          and Z.seq <= zlbl.p1pk_qty_conv(SP.taskid, SP.custid, SP.item, D.uom, 'CS', 'N')
                  + (select nvl(max(P1.seq), 0) from p1pkcaselabels P1
                        where P1.orderid = SP.orderid
                          and P1.shipid = SP.shipid
                          and P1.custid = SP.custid
                          and P1.item = SP.item)) OD
where OH.shipto = CN.consignee(+)
  and OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OH.ordertype = 'O'
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+)
  and OH.custid = CU.custid(+)
  and OH.fromfacility = FA.facility(+);

comment on table lbl_bp_task_cs_view is '$Id';

exit;
