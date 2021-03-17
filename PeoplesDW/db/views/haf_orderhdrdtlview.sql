--
-- $Id:  $
--

create or replace view haf_orderhdrdtlview
(
  orderid,
  po, 
  reference,
  item,
  itemdesc,
  lot,
  qty,
  weight,
  uom,
  lpid,
  fromlpid,
  expdate,
  mfgdate,
  shiptoname,
  shiptoaddr1,
  shiptocity,
  shiptostate,
  shiptozip
) as 
select
sp.orderid,
oh.po,
oh.reference,
sp.item,
custitem.descr,
sp.lotnumber,
sp.quantity,
sp.weight,
sp.unitofmeasure,
sp.lpid,
sp.fromlpid,
pl.expirationdate,
pl.manufacturedate,
consignee.name,
consignee.addr1,
consignee.city,
consignee.state,
consignee.postalcode
from shippingplate sp, plate p, custitem, orderhdr oh, consignee, plate pl
where sp.fromlpid = p.lpid
  and sp.type <> 'M'
  and sp.item = custitem.item
  and sp.custid = custitem.custid
  and sp.orderid = oh.orderid
  and oh.shipto = consignee.consignee
  and sp.fromlpid = pl.lpid;
