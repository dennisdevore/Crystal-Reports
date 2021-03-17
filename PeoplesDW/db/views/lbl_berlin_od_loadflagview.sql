create or replace view lbl_berlin_od_loadflagview
(
   lpid,
   shiftno,
   lfdate,
   press,
   jobno,
   skid,
   formno,
   lot,
   run,
   cname,
   descr,
   skidcnt,
   net,
   tare,
   gross,
   twoup,
   destination,
   dest1,
   dest2,
   dest3,
   dest4,
   dest5
)
as
select SP.lpid,
       null,                           -- shiftno
       sysdate,                        -- lfdate
       null,                           -- press
       OH.hdrpassthruchar01,
       null,                           -- skid
       null,                           -- formno
       OH.hdrpassthruchar04,
       null,                           -- run
       OH.hdrpassthruchar06,
       CI.descr,
       null,                           -- skidcnt
       SP.weight,
       CI.tareweight,
       SP.weight + CI.tareweight,
       null,                           -- twoup
       null,                           -- destination
       null,                           -- dest1
       null,                           -- dest2
       null,                           -- dest3
       null,                           -- dest4
       null                            -- dest5
   from shippingplate SP, orderhdr OH, custitem CI
   where OH.orderid (+) = SP.orderid
     and OH.shipid (+) = SP.shipid
     and CI.custid (+) = SP.custid
     and CI.item (+) = SP.item;

comment on table lbl_berlin_od_loadflagview is '$Id';

exit;
