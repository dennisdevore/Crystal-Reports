create or replace view lbl_mericle_kmart_view
(
   lpid,
   from1,
   from2,
   from3,
   from4,
   carrier,
   pro_number,
   blnum,
   storename__num,
   to_1,
   to_2,
   to_3,
   ship_zip,
   ponum,
   barcode
)
as
select
   SP.lpid,
   CU.name,
   FA.addr1,
   FA.addr2,
   ltrim(FA.city) || ', ' || ltrim(FA.state) || ' ' || FA.postalcode,
   CA.name,
   OH.prono,
   OH.reference,
   decode(OH.shiptoname, null, CN.name, OH.shiptoname),
   decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1),
   decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2),
   decode(OH.shiptoname, null, CN.city, OH.shiptocity)
   	|| ', ' || decode(OH.shiptoname, null, CN.state, OH.shiptostate)
      || '  ' || decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   OH.po,
   zedi.get_sscc18_code(OH.custid, decode(OH.shiptype, 'S', '0', '1'), SP.lpid)
from shippingplate SP,
     orderhdr OH,
     facility FA,
     customer CU,
     carrier CA,
     consignee CN
where SP.orderid = OH.orderid
  and SP.shipid = OH.shipid
  and OH.fromfacility = FA.facility(+)
  and OH.custid = CU.custid(+)
  and OH.carrier = CA.carrier(+)
  and OH.shipto = CN.consignee(+);

comment on table lbl_mericle_kmart_view is '$Id$';

exit;
