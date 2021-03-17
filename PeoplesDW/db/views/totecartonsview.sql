create or replace view totecartonsview
(
  totelpid,
  lpid,
  orderid,
  shipid,
  quantity,
  weight,
  status,
  splpid
)
as
select
   totelpid,
   fromlpid,
   orderid,
   shipid,
   quantity,
   weight,
   status,
   lpid
  from shippingplate
 where type = 'C'
   and status in ('PA', 'S');
   
comment on table totecartonsview is '$Id$';
   
--exit;
