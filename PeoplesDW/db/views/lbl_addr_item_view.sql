create or replace view lbl_addr_item_view
(
   lpid,
   childlpid,
   item,
   shiptoname,
   shiptoaddr1,
   shiptoaddr2,
   shiptocity,
   shiptostate,
   shiptopostalcode,
   shiptocsz,
   shiptocontact,
   po,
   seq
)
as
select
   SP.parentlpid,
   SP.lpid,
   SP.item,
   decode(OH.shiptoname, null, CN.name, OH.shiptoname),
   decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1),
   decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2),
   decode(OH.shiptoname, null, CN.city, OH.shiptocity),
   decode(OH.shiptoname, null, CN.state, OH.shiptostate),
   decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   rtrim(decode(OH.shiptoname, null, CN.city, OH.shiptocity)) || ', '||
      rtrim(decode(OH.shiptoname, null, CN.state, OH.shiptostate))|| ' ' ||
      decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   decode(OH.shiptocontact, null, CN.contact, OH.shiptocontact),
   oh.po,
   Z.seq
from orderhdr OH,
     shippingplate SP,
     consignee CN,
     zseq Z
where OH.shipto = CN.consignee(+)
  and OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and OH.ordertype = 'O'
  and SP.parentlpid is not null
  and SP.type in ('F','P')
  and Z.seq <= SP.quantity
union
select
   (select parentlpid from shippingplate where lpid = (select parentlpid from shippingplate where lpid = SP.lpid)),
   SP.lpid,
   SP.item,
   decode(OH.shiptoname, null, CN.name, OH.shiptoname),
   decode(OH.shiptoname, null, CN.addr1, OH.shiptoaddr1),
   decode(OH.shiptoname, null, CN.addr2, OH.shiptoaddr2),
   decode(OH.shiptoname, null, CN.city, OH.shiptocity),
   decode(OH.shiptoname, null, CN.state, OH.shiptostate),
   decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   rtrim(decode(OH.shiptoname, null, CN.city, OH.shiptocity)) || ', '||
      rtrim(decode(OH.shiptoname, null, CN.state, OH.shiptostate))|| ' ' ||
      decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode),
   decode(OH.shiptocontact, null, CN.contact, OH.shiptocontact),
   oh.po,
   Z.seq
from orderhdr OH,
     shippingplate SP,
     consignee CN,
     zseq Z
where OH.shipto = CN.consignee(+)
  and OH.orderid = SP.orderid
  and OH.shipid = SP.shipid
  and OH.ordertype = 'O'
  and SP.parentlpid in (select lpid from shippingplate where parentlpid is not null and type = 'C')
   and z.seq <= sp.quantity
  and SP.type in ('F','P')
  and Z.seq <= SP.quantity;
comment on table lbl_addr_item_view is '$Id';

exit;
