create or replace view lbl_scc14_plt_view
(
   lpid,
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
   descr,
   zipbarcode,
   ziphumancode,
   shipfromname
)
as
select
   SP.lpid,
   SP.orderid,
   SP.shipid,
   zedi.get_sscc14_code('1',OD.dtlpassthruchar09),
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
   SP.item,
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
   CI.descr,
   '420' || substr(decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode), 1, 5),
   '(420)' || substr(decode(CN.consignee, null, OH.shiptopostalcode, CN.postalcode), 1, 5),
   'C/O ' || FA.name
from orderhdr OH,
     orderdtl OD,
     loads L,
     carrier CA,
     consignee CN,
     customer CU,
     facility FA,
     custitemwmitview WM,
     shippingplate SP,
     custitem CI
where OH.shipto = CN.consignee(+)
  and OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and OH.ordertype = 'O'
  and SP.parentlpid is null
  and SP.loadno = L.loadno(+)
  and SP.orderid = OD.orderid(+)
  and SP.shipid = OD.shipid(+)
  and SP.orderitem = OD.item(+)
  and nvl(SP.orderlot,'<none>') = nvl(OD.lotnumber(+),'<none>')
  and SP.custid = WM.custid(+)
  and SP.item = WM.item(+)
  and OH.carrier = CA.carrier(+)
  and OH.custid = CU.custid(+)
  and OH.fromfacility = FA.facility(+)
  and OD.custid = CI.custid(+)
  and OD.item = CI.item(+);
  
comment on table lbl_scc14_plt_view is '$Id';
  

exit;
