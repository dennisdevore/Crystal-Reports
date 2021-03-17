create or replace view lbl_addr_shipview
(
   lpid,
   shiptoname,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   shipdate,
   carriername,
   stageloc,
   orderid,
   shipid,
   po,
   reference,
   loadno,
   custname,
   whsename,
   whseaddr1,
   whseaddr2,
   whsecity,
   whsestate,
   whsepostalcode,
   seq
)
as
select
   SP.lpid,
   decode(OH.shiptoname, null, CN.name, OH.shiptoname),
   decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1),
   decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2),
   decode(OH.shiptoname, null, CN.city, OH.shiptocity),
   decode(OH.shiptoname, null, CN.state, OH.shiptostate),
   decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   OH.shipdate,
   CR.name,
   OH.stageloc,
   OH.orderid,
   OH.shipid,
   OH.po,
   OH.reference,
   OH.loadno,
   CU.name,
   FA.name,
   FA.addr1,
   FA.addr2,
   FA.city,
   FA.state,
   FA.postalcode,
   Z.seq
from orderhdr OH,
     shippingplate SP,
     consignee CN,
     carrier CR,
     customer CU,
     facility FA,
     zseq Z
where OH.shipto = CN.consignee(+)
  and OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and OH.ordertype = 'O'
  and SP.parentlpid is null
  and OH.carrier = CR.carrier(+)
  and OH.custid = CU.custid(+)
  and OH.fromfacility = FA.facility(+)
  and Z.seq <= zlbl.cs_labels(SP.lpid);

comment on table lbl_addr_shipview is '$Id';

exit;
