create or replace view lbl_ucc128_ctn_view
(
   lpid,
   sscc18,
   shiptoname,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   dc,
   carriername,
   shipdate,
   orderid,
   shipid,
   item,
   wmit,
   po,
   reference,
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
   whsepostalcode
)
as
select
   SP.lpid,
   zedi.get_ucc128_code(OH.custid,'0',SP.lpid, Z.seq),
   decode(CN.consignee, null, OH.shiptoname, CN.name),
   decode(CN.consignee, null, OH.shiptoaddr1, CN.addr1),
   decode(CN.consignee, null, OH.shiptoaddr2, CN.addr2),
   decode(CN.consignee, null, OH.shiptocity, CN.city),
   decode(CN.consignee, null, OH.shiptostate, CN.state),
   decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode),
   substr(decode(CN.consignee, null, OH.shiptoname, CN.name),
          instr(decode(CN.consignee, null, OH.shiptoname, CN.name),'DC',-1)),
   CA.name,
   OH.shipdate,
   SP.orderid,
   SP.shipid,
   SP.item,
   nvl(OD.consigneesku, WM.wmit),
   OH.po,
   OH.reference,
   OH.loadno,
   L.prono,
   SP.orderid||'-'||SP.shipid,
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
   FA.postalcode
from orderhdr OH,
     orderdtl OD,
     loads L,
     carrier CA,
     consignee CN,
     customer CU,
     facility FA,
     custitemwmitview WM,
     shippingplate SP,
     zseq Z
where OH.shipto = CN.consignee(+)
  and OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and OH.ordertype = 'O'
  and SP.type in ('P','F')
  and SP.loadno = L.loadno(+)
  and SP.orderid = OD.orderid(+)
  and SP.shipid = OD.shipid(+)
  and SP.orderitem = OD.item(+)
  and SP.custid = WM.custid(+)
  and SP.item = WM.item(+)
  and nvl(SP.orderlot,'<none>') = nvl(OD.lotnumber(+),'<none>')
  and OH.carrier = CA.carrier(+)
  and OH.custid = CU.custid(+)
  and OH.fromfacility = FA.facility(+)
  and Z.seq <= SP.quantity
  and not exists (select * from shippingplate where orderid = OH.orderid
	  and shipid = OH.shipid and status in ('U', 'P'));

comment on table lbl_ucc128_ctn_view is '$Id';

exit;
