create or replace view ldarrivalplateview
(
   lpid,
   item,
   custid,
   facility,
   location,
   status,
   holdreason,
   unitofmeasure,
   quantity,
   type,
   serialnumber,
   lotnumber,
   creationdate,
   manufacturedate,
   expirationdate,
   expiryaction,
   lastcountdate,
   po,
   recmethod,
   condition,
   lastoperator,
   lasttask,
   fifodate,
   destlocation,
   destfacility,
   countryof,
   parentlpid,
   useritem1,
   useritem2,
   useritem3,
   disposition,
   lastuser,
   lastupdate,
   invstatus,
   qtyentered,
   itementered,
   uomentered,
   inventoryclass,
   loadno,
   stopno,
   shipno,
   weight,
   adjreason,
   qtyrcvd,
   controlnumber,
   qcdisposition,
   fromlpid,
   dropseq,
   fromshippinglpid,
   workorderseq,
   workordersubseq,
   qtytasked,
   childfacility,
   childitem,
   parentfacility,
   parentitem,
   prevlocation,
   custname,
   itemdescr,
   seq,
   seqof,
   dateprinted,
   timeprinted,
--PRN: 4889 Add reference field from orderheader and itembc for label
   itembc,
   container,
   invclass,
--
   dtlpassthruchar01,
   dtlpassthruchar02,
   dtlpassthruchar03,
   dtlpassthruchar04,
   dtlpassthruchar05,
   dtlpassthruchar06,
   dtlpassthruchar07,
   dtlpassthruchar08,
   dtlpassthruchar09,
   dtlpassthruchar10
)
as
select
   PL.lpid,
   PL.item,
   PL.custid,
   PL.facility,
   PL.location,
   PL.status,
   PL.holdreason,
   PL.unitofmeasure,
   PL.quantity,
   PL.type,
   PL.serialnumber,
   PL.lotnumber,
   PL.creationdate,
   PL.manufacturedate,
   PL.expirationdate,
   PL.expiryaction,
   PL.lastcountdate,
   PL.po,
   PL.recmethod,
   PL.condition,
   PL.lastoperator,
   PL.lasttask,
   PL.fifodate,
   PL.destlocation,
   PL.destfacility,
   PL.countryof,
   PL.parentlpid,
   PL.useritem1,
   PL.useritem2,
   PL.useritem3,
   PL.disposition,
   PL.lastuser,
   PL.lastupdate,
   PL.invstatus,
   PL.qtyentered,
   PL.itementered,
   PL.uomentered,
   PL.inventoryclass,
   PL.loadno,
   PL.stopno,
   PL.shipno,
   PL.weight,
   PL.adjreason,
   PL.qtyrcvd,
   PL.controlnumber,
   PL.qcdisposition,
   PL.fromlpid,
   PL.dropseq,
   PL.fromshippinglpid,
   PL.workorderseq,
   PL.workordersubseq,
   PL.qtytasked,
   PL.childfacility,
   PL.childitem,
   PL.parentfacility,
   PL.parentitem,
   PL.prevlocation,
   CU.name,
   CI.descr,
   null,
   (select count(*) from plate where orderid = PL.orderid and shipid = PL.shipid),
   to_char(sysdate, 'MM/DD/RR'),
   to_char(sysdate, 'HH:MI AM'),
--PRN: 4889 Add reference field from orderheader and itembc for labels.
   PL.item,
   oh.reference,
   PL.inventoryclass,
   OD.dtlpassthruchar01,
   OD.dtlpassthruchar02,
   OD.dtlpassthruchar03,
   OD.dtlpassthruchar04,
   OD.dtlpassthruchar05,
   OD.dtlpassthruchar06,
   OD.dtlpassthruchar07,
   OD.dtlpassthruchar08,
   OD.dtlpassthruchar09,
   OD.dtlpassthruchar10
from orderhdr OH,
     orderdtl OD,
     plate PL,
     customer CU,
     custitem CI
where CU.custid = PL.custid
  and CI.custid = PL.custid
  and CI.item = PL.item
  and OH.orderid(+) = PL.orderid
  and OH.shipid(+) = PL.shipid
  and OD.orderid(+) = PL.orderid
  and OD.shipid(+) = PL.shipid
  and OD.item(+) = PL.item
  and nvl(OD.lotnumber(+), '(none)') = nvl(PL.lotnumber,'(none)');
--

comment on table ldarrivalplateview is '$Id';

exit;