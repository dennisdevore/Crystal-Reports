create or replace view bill_3linx_base
(
orderid,
shipid,
custid,
item,
parentlpid,
trackingno,
quantity
)
as
select
   oh.orderid,
   oh.shipid,
   oh.custid,
   sp.item,
   sp.parentlpid,
   sp.trackingno,
   sum(sp.quantity)
from shippingplate sp, orderhdr oh
where oh.ordertype = 'O'
  and oh.orderstatus = '9'
  and sp.orderid = oh.orderid
  and sp.shipid = sp.shipid
  and sp.parentlpid in (select sp.lpid from multishipdtl md, shippingplate sp
                       where md.orderid = oh.orderid
                         and md.shipid = oh.shipid
                         and md.status = 'PROCESSED'
                         and sp.fromlpid = md.cartonid)
  and type in ('F', 'P')
group by oh.orderid, oh.shipid, oh.custid, sp.item, sp.parentlpid, sp.trackingno;


create or replace view bill_3linx_view
(
datereceived,
dc,
custid,
orderid,
reference,
carrier,
deliveryservice,
item,
quantity,
lpid,
dateshipped,
trackingno,
weight,
cost,
insurance,
city,
state,
zip,
countrycode,
ordercharge,
itempicks,
itemrate,
itemcharge,
surcharge,
cutomdoc,
printchg,
splpid)
as
select
   to_char(oh.entrydate,'mm/dd/yyyy'),
   oh.fromfacility,
   b3b.custid,
   b3b.orderid,
   oh.reference,
   oh.carrier,
   oh.deliveryservice,
   b3b.item,
   b3b.quantity,
   ''''||sp.fromlpid,
   to_char(oh.dateshipped,'mm/dd/yyyy'),
   '''' ||b3b.trackingno,
   b3l.get_weight(b3b.parentlpid, sp.fromlpid, b3b.item),
   b3l.get_cost(b3b.parentlpid, sp.fromlpid, b3b.item),
   b3l.get_insurance2(b3b.custid, b3b.item, b3b.quantity,b3b.parentlpid),
   oh.shiptocity,
   oh.shiptostate,
   oh.shiptopostalcode,
   decode(oh.shiptocountrycode, 'USA', null, oh.shiptocountrycode),
   b3l.get_ordercharge(b3b.parentlpid, sp.fromlpid, b3b.item, b3b.orderid, b3b.shipid),
   b3l.get_picks2(b3b.custid, b3b.item, b3b.quantity),
   (select to_number(abbrev) from bill3linxparm where rtrim(code) = 'ITEMRATE'),
   b3l.get_itemcharge(b3b.custid, b3b.item, b3b.quantity),
   b3l.get_surcharge(b3b.parentlpid, sp.fromlpid, b3b.item, b3b.orderid,b3b.shipid, oh.carrier),
   b3l.get_customdoc(b3b.parentlpid, sp.fromlpid, b3b.item, oh.shiptocountrycode,b3b.orderid,b3b.shipid),
   b3l.get_print(b3b.parentlpid, sp.fromlpid, b3b.item, oh.carrier,b3b.orderid,b3b.shipid),
   '''' ||sp.lpid
from bill_3linx_base b3b, orderhdr oh, shippingplate sp
where oh.orderid = b3b.orderid
  and oh.shipid = b3b.shipid
  and oh.ordertype = 'O'
  and oh.orderstatus = '9'
  and sp.orderid = b3b.orderid
  and sp.shipid = b3b.shipid
  and sp.lpid = b3b.parentlpid;

exit;

