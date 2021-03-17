create or replace view shipnote856hdr
(
    custid,
    asnnumber,
    structure,
    shipdate,
    shiptime,
    shipstatus,
    pronumber,
    shipunits,
    weight,
    uomweight,
    appointment,
    carrier,
    trailer,
    bol,
    transportation,
    carriername,
    customer_name,
    customer_addr1,
    customer_addr2,
    customer_city,
    customer_state,
    customer_postalcode,
    shipto_id,
    shipto_name,
    shipto_addr1,
    shipto_addr2,
    shipto_city,
    shipto_state,
    shipto_postalcode,
    facility_id,
    facility_name,
    facility_addr1,
    facility_addr2,
    facility_city,
    facility_state,
    facility_postalcode
)
as
select
    S.custid,
    S.asnnumber,
    S.structure,
    to_char(L.statusupdate,'YYYYMMDD'),
    to_char(L.statusupdate,'HH24MISS'),
    S.status,
    L.prono,
    S.shipunits,
    S.weight,
    'LB',
    S.appointment,
    CA.carrier,
    L.trailer,
    S.bol,
    S.shiptype,
    CA.name,
    C.name,
    C.addr1,
    C.addr2,
    C.city,
    C.state,
    C.postalcode,
    CN.consignee,
    CN.name,
    CN.addr1,
    CN.addr2,
    CN.city,
    CN.state,
    CN.postalcode,
    F.facility,
    F.name,
    F.addr1,
    F.addr2,
    F.city,
    F.state,
    F.postalcode
from carrier CA, facility F, customer C, consignee CN, 
     loads L, shipnote856hdrex S
where S.loadno = L.loadno
  and S.custid = C.custid
  and S.consignee = CN.consignee
  and S.facility = F.facility
  and L.carrier = CA.carrier;

comment on table shipnote856hdr is '$Id$';


create or replace view shipnote856ord
(
    custid,
    asnnumber,
    orderid,
    shipid,
    po,
    shipunits,
    paymentcode
)
as
select
    S.custid,
    S.asnnumber,
    S.orderid,
    S.shipid,
    O.po,
    S.shipunits,
    decode(O.shipterms,'COL','CC','PPD','PP','??')
from orderhdr O, shipnote856ordex S
where S.orderid = O.orderid
  and S.shipid = O.shipid;

comment on table shipnote856ord is '$Id$';


create or replace view shipnote856tar
(
    custid,
    asnnumber,
    orderid,
    shipid,
    ucc128
)
as
select
    O.custid,
    S.asnnumber,
    S.orderid,
    S.shipid,
    S.ucc128
from orderhdr O, shipnote856tarex S
where S.orderid = O.orderid
  and S.shipid = O.shipid;

comment on table shipnote856tar is '$Id$';

create or replace view shipnote856itm
(
    custid,
    asnnumber,
    orderid,
    shipid,
    ucc128,
    upc,
    item,
    venditem,
    shipped,
    shipuom,
    orderer,
    orderuom,
    description
)
as
select
    S.custid,
    S.asnnumber,
    S.orderid,
    S.shipid,
    S.ucc128,
    S.upc,
    S.item,
    S.venditem,
    S.shipped,
    S.shipuom,
    S.ordered,
    S.orderuom,
    I.descr
from custitem I, shipnote856itmex S
where S.custid = I.custid
  and S.item = I.item;

comment on table shipnote856itm is '$Id$';


exit;
