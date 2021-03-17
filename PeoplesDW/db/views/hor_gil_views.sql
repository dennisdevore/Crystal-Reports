-- hor_gil_itemview
create or replace view hor_gil_itemview
(
  item,
  custid,
  facility,
  unitofmeasure,
  quantity,
  type,
  inventoryclass,
  weight,
  descr
)
as
select
  item,
  custid,
  facility,
  unitofmeasure,
  quantity,
  type,
  inventoryclass,
  weight,
  descr
from platesumview
where custid = 'GIL' and
  type = 'PA'
order by facility, custid, item, inventoryclass, unitofmeasure;

-- hor_gil_itemview_old
create or replace view hor_gil_itemview_old
(
  item,
  custid,
  facility,
  unitofmeasure,
  quantity,
  type,
  inventoryclass,
  weight,
  descr
)
as
select
  item,
  custid,
  facility,
  unitofmeasure,
  quantity,
  type,
  inventoryclass,
  weight,
  descr
from platesumview
where custid = 'GIL' and
  facility = 'PAZ' and
  type = 'PA'
order by facility, custid, item, inventoryclass, unitofmeasure;

-- hor_gil_shippedctns
create or replace view hor_gil_shippedctns
(
  reference,
  custid,
  orderstatus,
  type,
  dateshipped,
  parentlpid,
  quantity,
  weight,
  hdrpassthruchar01,
  shipdate,
  shiptype,
  trackingno,
  prono,
  name,
  shippingcost,
  item,
  carrier,
  deliveryservice,
  shiptoname,
  orderid,
    shipid
) as
select
  oh.reference,
  oh.custid,
  oh.orderstatus,
  sp.type,
  oh.dateshipped,
  sp.parentlpid,
  sp.quantity,
  sp.weight,
  oh.hdrpassthruchar01,
  oh.shipdate,
  oh.shiptype,
  sp.trackingno,
  oh.prono,
  co.name,
  sp.shippingcost,
  sp.item,
  oh.carrier,
  oh.deliveryservice,
  oh.shiptoname,
  sp.orderid,
  sp.shipid
from (shippingplate sp inner join
    orderhdr oh on (sp.orderid = oh.orderid) and (sp.shipid = oh.shipid))
  left outer join
    consignee co on oh.shipto = co.consignee
where oh.orderstatus = '9' and
  oh.custid = 'GIL' and
  (sp.type = 'C' or sp.type = 'F' or sp.type = 'M') and
  ((to_char(oh.dateshipped, 'YYYY/MM/DD') >=
    (select  to_char(trunc(add_months(sysdate, -3)), 'YYYY/MM/DD') from dual)) and
      (to_char(oh.dateshipped, 'YYYY/MM/DD') <=
        (select  to_char(trunc(sysdate), 'YYYY/MM/DD') from dual)))
order by oh.reference;

-- hor_gil_returns
create or replace view hor_gil_returns
(
  ordertype,
  orderid,
  shipid,
  rma,
  shiptoname,
  entrydate,
  custid,
  item,
  qtyrcvd,
  reference,
  lotnumber,
  expirationdate,
  inventoryclassabbrev,
  invstatusabbrev
)
as
select
  oh.ordertype,
  oh.orderid,
  oh.shipid,
  oh.rma,
  oh.shiptoname,
  oh.entrydate,
  oh.custid,
  ap.item,
  od.qtyrcvd,
  oh.reference,
  ap.lotnumber,
  ap.expirationdate,
  ap.inventoryclassabbrev,
  ap.invstatusabbrev
from (orderhdr oh inner join allplateview ap on
    (oh.orderid = ap.orderid) and (oh.shipid = ap.shipid))
  inner join orderdtl od on ((ap.orderid = od.orderid) and
    (ap.shipid = od.shipid)) and
  (ap.item = od.item)
where oh.ordertype = 'Q' and
  oh.custid = 'GIL' and
  ((to_char(oh.entrydate, 'YYYY/MM/DD') >=
    (select  to_char(trunc(add_months(sysdate, -3)), 'YYYY/MM/DD') from dual)) and
      (to_char(oh.entrydate, 'YYYY/MM/DD') <=
        (select  to_char(trunc(sysdate), 'YYYY/MM/DD') from dual)))
order by oh.orderid;

--Hor_gil_poconfirm
create or replace view hor_gil_poconfirm
(
  orderid,
  shipid,
  item,
  lotnumber,
  itementered,
  uomentereddesc,
  itemdesc,
  qtyentered,
  weightorder,
  custid,
  cust_name,
  cust_contact,
  cust_addr1,
  cust_addr2,
  cust_city,
  cust_state,
  cust_postalcode,
  cust_phone,
  cust_fax,
  cust_countrycode,
  doclabel,
  document,
  fac_facility,
  fac_name,
  fac_addr1,
  fac_addr2,
  fac_city,
  fac_state,
  fac_countrycode,
  fac_postalcode,
  fac_phone,
  fac_fax,
  fac_manager,
  rcvddate,
  loadno,
  itemlabel,
  lotlabel,
  qtyrcvdgood,
  qtyrcvddmgd,
  weightrcvd,
  shipper_name,
  carrier_name,
  trailer,
  od_comment,
  comment1,
  mfg_date,
  exp_date,
  useritem1,
  inpallets,
  outpallets
)
as
select
  rh.orderid,
  rh.shipid,
  rd.item,
  rd.lotnumber,
  rd.itementered,
  rd.uomentereddesc,
  rd.itemdesc,
  rd.qtyentered,
  rd.weightorder,
  rh.custid,
  cu.name,
  cu.contact,
  cu.addr1,
  cu.addr2,
  cu.city,
  cu.state,
  cu.postalcode,
  cu.phone,
  cu.fax,
  cu.countrycode,
  rh.doclabel,
  rh.document,
  fa.facility,
  fa.name,
  fa.addr1,
  fa.addr2,
  fa.city,
  fa.state,
  fa.countrycode,
  fa.postalcode,
  fa.phone,
  fa.fax,
  fa.manager,
  rh.rcvddate,
  rh.loadno,
  rh.itemlabel,
  rh.lotlabel,
  rd.qtyrcvdgood,
  rd.qtyrcvddmgd,
  rd.weightrcvd,
  sh.name,
  ca.name,
  rh.trailer,
  od.od_comment,
  oh.comment1,
  rd.mfg_date,
  rd.exp_date,
  rd.useritem1,
  ph.inpallets,
  ph.outpallets
from
  (((((((receiverhdrview rh inner join dre_receiverdtlview rd on
    (rh.orderid = rd.orderid) and (rh.shipid = rd.shipid)) left outer join
    custrcptview cu on rh.custid = cu.custid) left outer join
    carrier ca on rh.carrier = ca.carrier) left outer join
    facility fa on rh.tofacility = fa.facility) left outer join
    shipper sh on rh.shipper = sh.shipper) inner join
    orderhdrcmtviewa oh on rh.orderhdrrowid = oh.orderhdrrowid) left outer join
    pallethistory ph on ((rh.loadno = ph.loadno) and
      (rh.orderid = ph.orderid) and (rh.shipid = ph.shipid))) left outer join
    dre_rpt_orderdtlcmtviewa od on rd.orderdtlrowid = od.od_rowid
where
  rh.custid = 'GIL' and
  rh.orderstatus = 'R' and
  ((to_char(rh.rcvddate, 'YYYY/MM/DD') >=
    (select to_char(trunc(add_months(sysdate, -3)), 'YYYY/MM/DD') from dual)) and
      (to_char(rh.rcvddate, 'YYYY/MM/DD') <=
        (select  to_char(trunc(sysdate), 'YYYY/MM/DD') from dual)))
order by rh.orderid, rh.shipid, rd.itementered, rd.lotnumber;

create or replace view hor_empty_view
(
  custid,
  aColumn
)
as
select
  'GIL',
  ' '
from
  dual;

exit;
