create or replace view lbl_d2000_ordercomp_view
(
	orderid,
   shipid,
   orderno,
   wave,
	shiptoname,
	shiptoaddr1,
	shiptoaddr2,
	shiptocsz,
   carrier,
   shipdate,
   palletcount
)
as
select OH.orderid,
       OH.shipid,
       OH.orderid || '-' || OH.shipid,
		 OH.wave,
       decode(OH.shiptoname, null, CN.name, OH.shiptoname),
       decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1),
       decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2),
       rtrim(decode(OH.shiptoname, null, CN.city, OH.shiptocity)) || ', '
            || rtrim(decode(OH.shiptoname, null, CN.state, OH.shiptostate)) || ' '
            || decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
       CA.name,
       to_char(OH.shipdate, 'MM-DD-YYYY DY'),
       (select count(*) from shippingplate SP
            where SP.orderid = OH.orderid
              and SP.shipid = OH.shipid
              and SP.parentlpid is null)
from orderhdr OH,
     carrier CA,
     consignee CN
where CA.carrier(+) = OH.carrier
  and CN.consignee(+) = OH.shipto;

comment on table lbl_d2000_ordercomp_view is '$Id';

exit;
