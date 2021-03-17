create or replace view mericle_lbl_view
(
   lpid,
   ship_to,
   addr_1,
   addr_2,
   addr_3,
   reference,
   po,
   carrier
)
as
select
   SP.lpid,
   decode(OH.shiptoname, null, CN.name, OH.shiptoname),
   decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1),
   decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2),
   decode(OH.shiptoname, null, CN.city, OH.shiptocity)
   	|| ', ' || decode(OH.shiptoname, null, CN.state, OH.shiptostate)
      || '  ' || decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   OH.reference,
   OH.po,
   CR.name
from shippingplate SP,
	  orderhdr OH,
     consignee CN,
     carrier CR
where OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and OH.shipto = CN.consignee(+)
  and OH.carrier = CR.carrier(+);
  
comment on table mericle_lbl_view is '$Id';

exit;
