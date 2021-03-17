create or replace view totecontentsview
(
       totelpid,
       lpid,
       orderid,
       shipid,
       item,
       lotnumber,
       unitofmeasure,
       quantity
)
as
select
       T.lpid,
       C.lpid,
       S.orderid,
       S.shipid,
       C.item,
       C.lotnumber,
       C.unitofmeasure,
       C.quantity
  from shippingplate S, plate C, plate T
 where C.parentlpid = T.lpid
   and T.type = 'TO'
   and S.lpid = C.fromshippinglpid;
   
comment on table totecontentsview is '$Id$';
   
--exit;
