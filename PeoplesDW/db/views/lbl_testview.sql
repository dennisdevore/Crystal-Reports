create or replace view lbl_masterview
(
   lpid,
   quantity,
   item
)
as
select
   S.lpid,
   S.quantity,
   S.item
   from shippingplate S, orderhdr O
   where S.type = 'M'
     and O.orderid = S.orderid
     and O.shipid = S.shipid
     and O.shiptype = 'L';

comment on table lbl_masterview is '$Id';

create or replace view lbl_childview
(
   lpid,
   quantity,
   item
)
as
select
   S.lpid,
   S.quantity,
   S.item
   from shippingplate S, orderhdr O
   where S.type in ('P','F')
     and O.orderid = S.orderid
     and O.shipid = S.shipid
     and O.shiptype = 'S';

comment on table lbl_childview is '$Id';

exit;
