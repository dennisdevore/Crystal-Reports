create or replace view smallpackagecontents
(CARTONID
,ORDERID
,SHIPID
,CUSTID
,PARENTLPID
,ITEM
,DESCR
,UNITOFMEASURE
,DTLPASSTHRUDOL01
,QUANTITY)
as
select
m.cartonid
,m.orderid
,m.shipid
,sp.custid
,sp.lpid
,spp.item
,ci.descr
,spp.unitofmeasure
,od.dtlpassthrudoll01
,sum(spp.quantity)
from multishipdtl m, shippingplate sp, shippingplate spp, custitem ci, orderdtl od
where sp.fromlpid = m.cartonid
  and spp.parentlpid = sp.lpid
  and ci.custid = sp.custid
  and ci.item = spp.item
  and od.orderid = m.orderid
  and od.shipid = m.shipid
  and od.item = spp.item
group by m.cartonid, m.orderid, m.shipid, sp.custid, sp.lpid, spp.item, ci.descr, spp.unitofmeasure, od.dtlpassthrudoll01;

comment on table smallpackagecontents is '$Id: smallpackagecontentsview.sql 1 2005-05-26 12:20:03Z ed $';
