
CREATE OR REPLACE VIEW GET_210_HDR_VIEW ( FACILITY,
LOADNO, CUSTID, ORDERID, SHIPID, PRONO,
BOLNUMBER, SHIPTERMS, INVOICE, ALTINV, INVDATE,
POSTDATE, TRAILERID, CONTAINERID, HDRPASSTHRUCHAR01, IFSD, TOTAMTDUE, MASTERBOL
 ) AS select  distinct
   ih.facility,
   ih.loadno,
   ph.custid,
   oh.orderid,
   oh.shipid,
   oh.prono,
   oh.billoflading,
   oh.shipterms,
   ph.invoice,
   ih.invoice as altinv,
   ph.invdate,
   ph.postdate,
   L.trailer,
   lo.trailer,
   oh.hdrpassthruchar01,
   oh.hdrpassthruchar06,
   (select sum(billedamt) from invoicedtl id
   where  id.invoice = ph.invoice
         and (id.activity = '13DC' or
              id.activity = '21CD')), L.loadno
from posthdr ph, invoicehdr ih, orderhdr oh, loads L, loads lo
where  ph.invoice = ih.invoice and
       ih.loadno = oh.loadno and
       ih.loadno = L.loadno and
       oh.loadno = lo.loadno and
       ih.loadno is not null;

CREATE OR REPLACE VIEW GET_210_HDRHDR_VIEW ( FACILITY,
LOADNO, CUSTID, ORDERID, SHIPID, PRONO,
BOLNUMBER, SHIPTERMS, INVOICE, ALTINV, INVDATE,
POSTDATE, TRAILERID, CONTAINERID, HDRPASSTHRUCHAR01, IFSD, TOTAMTDUE, MASTERBOL
 ) AS select  distinct
   facility,
   loadno,
   custid,
   orderid,
   shipid,
   prono,
   bolnumber,
   shipterms,
   invoice,
   altinv,
   invdate,
   postdate,
   trailerid,
   containerid,
   hdrpassthruchar01,
   ifsd,
   totamtdue,
   masterbol from get_210_hdr_view;



CREATE OR REPLACE VIEW GET_210_ORDER_VIEW (
LOADNO, CUSTID, ORDERID, PRONO,
BOLNUMBER,  TRAILERID, REFERENCE
 ) AS select
   gh.loadno,
   gh.custid,
   oh.orderid,
   oh.prono,
   oh.hdrpassthruchar05,
   oh.hdrpassthruchar01,
   gh.ifsd
from GET_210_HDR_VIEW gh,  orderhdr oh
where  gh.loadno = oh.loadno;


CREATE OR REPLACE VIEW RCTPLATES ( LPID,
ITEM, CUSTID, FACILITY, LOCATION,
STATUS, UNITOFMEASURE, QUANTITY, TYPE,
SERIALNUMBER, LOTNUMBER, EXPIRATIONDATE, EXPIRYACTION,
PO, RECMETHOD, CONDITION, LASTOPERATOR,
LASTTASK, FIFODATE, PARENTLPID, USERITEM1,
USERITEM2, USERITEM3, INVSTATUS, INVENTORYCLASS,
 LOADNO, ORDERID, SHIPID,
WEIGHT, PLATEORSHIPPLATE, CONTROLNUMBER, FROMLPID,
LASTUSER, LASTUPDATE ) AS SELECT
PLATE.LPID,
PLATE.ITEM,
PLATE.CUSTID,
PLATE.FACILITY,
PLATE.LOCATION,
PLATE.STATUS,
PLATE.UNITOFMEASURE,
PLATE.QUANTITY,
PLATE.TYPE,
PLATE.SERIALNUMBER,
PLATE.LOTNUMBER,
PLATE.EXPIRATIONDATE,
PLATE.EXPIRYACTION,
PLATE.PO,
PLATE.RECMETHOD,
PLATE.CONDITION,
PLATE.LASTOPERATOR,
PLATE.LASTTASK,
PLATE.fifodate,
PLATE.PARENTLPID,
PLATE.USERITEM1,
PLATE.USERITEM2,
PLATE.USERITEM3,
PLATE.INVSTATUS,
PLATE.INVENTORYCLASS,
PLATE.loadno,
PLATE.orderid,
PLATE.shipid,
PLATE.weight,
'P',
PLATE.controlnumber,
PLATE.fromlpid,
PLATE.lastuser,
PLATE.lastupdate
FROM PLATE
WHERE  PLATE.TYPE NOT IN ('MP','XP')
UNION ALL
SELECT
DELETEDPLATE.LPID,
DELETEDPLATE.ITEM,
DELETEDPLATE.CUSTID,
DELETEDPLATE.FACILITY,
DELETEDPLATE.LOCATION,
DELETEDPLATE.STATUS,
DELETEDPLATE.UNITOFMEASURE,
DELETEDPLATE.QUANTITY,
DELETEDPLATE.TYPE,
DELETEDPLATE.SERIALNUMBER,
DELETEDPLATE.LOTNUMBER,
DELETEDPLATE.EXPIRATIONDATE,
DELETEDPLATE.EXPIRYACTION,
DELETEDPLATE.PO,
DELETEDPLATE.RECMETHOD,
DELETEDPLATE.CONDITION,
DELETEDPLATE.LASTOPERATOR,
DELETEDPLATE.LASTTASK,
DELETEDPLATE.fifodate,
DELETEDPLATE.PARENTLPID,
DELETEDPLATE.USERITEM1,
DELETEDPLATE.USERITEM2,
DELETEDPLATE.USERITEM3,
DELETEDPLATE.INVSTATUS,
DELETEDPLATE.INVENTORYCLASS,
DELETEDPLATE.loadno,
DELETEDPLATE.orderid,
DELETEDPLATE.shipid,
DELETEDPLATE.weight,
'D',
DELETEDPLATE.controlnumber,
DELETEDPLATE.fromlpid,
DELETEDPLATE.lastuser,
DELETEDPLATE.lastupdate
FROM DELETEDPLATE
WHERE  DELETEDPLATE.TYPE NOT IN ('MP','XP') AND DELETEDPLATE.STATUS = 'P' ;


CREATE OR REPLACE VIEW GET_210_INVDTL_VIEW (
LOADNO, CUSTID,  INVOICE, INVDATE, ACTIVITY, CHARGES
 ) AS select
   gh.loadno,
   gh.custid,
   gh.invoice,
   gh.invdate,
   id.activity,
   id.billedamt
from GET_210_HDR_VIEW gh, invoicedtl id
where  gh.altinv = id.invoice and
       (id.activity = '13DC' or
      id.activity = '21CD');

CREATE OR REPLACE VIEW GET_210_PLATE_VIEW ( LOADNO, CUSTID, 
 ITEM, LOTNUMBER, USERITEM1, USERITEM2, USERITEM3
 ) AS select
   gh.loadno,
   gh.custid,
   p.item,
   p.lotnumber,
   p.useritem1,
   p.useritem2,
   p.useritem3
from GET_210_HDR_VIEW gh, rctplates p
where  gh.orderid = p.orderid and
       gh.shipid = p.shipid;

CREATE OR REPLACE VIEW GET_210_PLATESUM_VIEW ( LOADNO, CUSTID, 
 ITEM, USERITEM1, USERITEM2, USERITEM3
 ) AS select
   gh.loadno,
   gh.custid,
   p.item,
   p.useritem1,
   p.useritem2,
   p.useritem3
from GET_210_HDR_VIEW gh, rctplates p
where  gh.orderid = p.orderid and
       gh.shipid = p.shipid;

CREATE OR REPLACE VIEW GET_210_CHGDTL_VIEW (
LOADNO, CUSTID,  LOTNUMBER, ACTIVITY, CHARGES
 ) AS select
   gh.loadno,
   gh.custid,
   gh.lotnumber,
   id.activity,
   id.billedamt
from GET_210_PLATE_VIEW gh,  invoicedtl id
where    gh.lotnumber = id.lotnumber;


