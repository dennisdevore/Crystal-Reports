create or replace view pacam856hdr
(
    custid,
    loadno,
    shipmentid,
    uom,
    ladingqty,
    weight,
    carrier,
    shiptype,
    carrierauth,
    carrierauth2,
    carrierauth3,
    billoflading,
    prono,
    shipdate,
    shiptime,
    shipto,
    facility
)
as
select
    '1234567890',
    loadno,
    loadno,
    loadno,
    loadno,
    'CS',
    qtyship,
    weightship,
    carrier,
    'L',
    'carrierauth',
    billoflading,
    prono,
    to_char(statusupdate,'YYYYMMDD'),
    to_char(statusupdate,'HH24MISS'),
    '1234567890',
    facility
from loads
where loadtype = 'OUTC'
  and loadstatus = '9';


create or replace view pacam856ord
(
    custid,
    loadno,
    shipmentid,
    orderid,
    shipid,
    po,
    qtyship,
    uom
)
as
select
    custid,
    loadno,
    loadno,
    orderid,
    shipid,
    po,
    qtyship,
    'CS'
from orderhdr
where loadno in (select loadno from pacam856hdr);


create or replace view pacam856pckg
(
    custid,
    loadno,
    shipmentid,
    orderid,
    shipid,
    barcode
)
as
select
    custid,
    loadno,
    loadno,
    orderid,
    shipid,
    '12345678901234567890'
from pacam856ord;

create or replace view pacam856dtl
(
    custid,
    loadno,
    shipmentid,
    orderid,
    shipid,
    barcode,
    upc,
    sku,
    item,
    qtyship,
    uom
)
as
select
    s.custid,
    s.loadno,
    s.loadno,
    s.orderid,
    s.shipid,
    '12345678901234567890',
    u.upc,
    u.upc,
    o.item,
    o.qtyship,
    'EA'
from pacam856ord s, orderdtl o, custitemupcview u
where s.custid = o.custid
  and s.orderid = o.orderid
  and s.shipid = o.shipid
  and u.custid = s.custid(+)
  and u.item = o.item(+);

exit;
