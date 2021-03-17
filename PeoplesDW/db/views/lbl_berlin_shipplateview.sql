create or replace view lbl_berlin_shipplateview
(
   lpid,
   item,
   descr,
   weight,
   po,
   cname
)
as
select SP.lpid,
       SP.item,
       CI.descr,
       SP.weight,
       OH.po,
       CU.name
   from shippingplate SP, customer CU, custitem CI, orderhdr OH
   where CU.custid (+) = SP.custid
     and CI.custid (+) = SP.custid
     and CI.item (+) = SP.item
     and OH.orderid = SP.orderid
     and OH.shipid = SP.shipid
     and OH.ordertype = 'O'
     and SP.parentlpid is null;

comment on table lbl_berlin_shipplateview is '$Id';

exit;
