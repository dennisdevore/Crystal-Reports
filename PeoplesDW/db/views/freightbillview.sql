create or replace view freightbillview
(
    orderid,
    shipid,
    custid,
    jobno,
    dateshipped,
    billoflading,
    shipterms,
    quantity,
    weight,
    skids,
    cartons,
    carrier,
    scac,
    shiptype,
    name,
    addr1,
    addr2,
    contact,
    city,
    state,
    zip,
    shippingcharges
)
as
select
    O.orderid,
    O.shipid,
    O.custid,
    O.reference,
    O.dateshipped,
    nvl(L.billoflading,nvl(to_char(L.loadno,'FM0000009'),
                        to_char(O.orderid,'FM0000009')||'/'||
                        to_char(O.shipid,'FM09'))),
    O.shipterms,
    O.qtyship,
    zimppecas.order_weight(O.orderid, O.shipid), --O.weightship,
    zimppecas.order_skids(O.orderid, O.shipid),
    zimppecas.order_cartons(O.orderid, O.shipid),
    O.carrier,
    C.scac,
    O.shiptype,
    O.shiptoname,
    O.shiptoaddr1,
    O.shiptoaddr2,
    O.shiptocontact,
    O.shiptocity,
    O.shiptostate,
    O.shiptopostalcode,
    zoe.sum_shipping_cost(O.orderid, O.shipid)
 from alps.orderhdr O, alps.loads L, alps.carrier C
where O.orderstatus = '9'
  and O.shipterms = 'PPD'
  and O.shiptype != 'M'
  and O.loadno = L.loadno(+)
  and O.carrier = C.carrier(+);
  
comment on table freightbillview is '$Id$';
  

drop public synonym freightbillview;
create public synonym freightbillview for pecas.freightbillview;

exit;
