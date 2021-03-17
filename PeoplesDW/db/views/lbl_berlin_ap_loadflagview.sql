create or replace view lbl_berlin_ap_loadflagview
(
   lpid,
   trackingno,
   destination,
   destzip,
   jobno,
   cname,
   volume,
   uomqty,
   uom,
   weight,
   pieceqty,
   skidtype,
   skidno,
   skidcnt,
   string,
   lot
)
as
select SP.lpid,
       OH.hdrpassthruchar05,
       OH.shiptoname,
       OH.shiptopostalcode,
       OH.hdrpassthruchar01,
       OH.hdrpassthruchar06,
       SP.quantity * zci.item_cube(SP.custid, SP.item, SP.unitofmeasure),
       null,                              -- uomqty
       null,                              -- uom
       SP.weight,
       SP.quantity,
       null,                              -- skidtype
       null,                              -- skidno
       null,                              -- skidcnt
       OH.hdrpassthruchar03,
       OH.hdrpassthruchar04
   from shippingplate SP, orderhdr OH
   where OH.orderid (+) = SP.orderid
     and OH.shipid (+) = SP.shipid;

comment on table lbl_berlin_ap_loadflagview is '$Id';

exit;
