create or replace view lbl_addr_ship2view
(
   lpid,
   txtlpid,
   shiptoname,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   shiptocsz,
   shiptophone,
   shiptofax,
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
   whsepostalcode
)
as
select
   SP.lpid,
   SP.lpid,
   decode(OH.shiptoname, null, CN.name, OH.shiptoname),
   decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1),
   decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2),
   decode(OH.shiptoname, null, CN.city, OH.shiptocity),
   decode(OH.shiptoname, null, CN.state, OH.shiptostate),
   decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   rtrim(decode(OH.shiptoname, null, CN.city, OH.shiptocity)) || ', '||
      rtrim(decode(OH.shiptoname, null, CN.state, OH.shiptostate))|| ' ' ||
      decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   decode(OH.shiptoname, null, CN.phone, OH.shiptophone),
   decode(OH.shiptoname, null, CN.fax, OH.shiptofax),
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
   FA.postalcode
from orderhdr OH,
     shippingplate SP,
     consignee CN,
     carrier CR,
     customer CU,
     facility FA
where OH.shipto = CN.consignee(+)
  and OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and OH.ordertype = 'O'
  and SP.parentlpid is null
  and OH.carrier = CR.carrier(+)
  and OH.custid = CU.custid(+)
  and OH.fromfacility = FA.facility(+);

comment on table lbl_addr_ship2view is '$Id';

exit;
