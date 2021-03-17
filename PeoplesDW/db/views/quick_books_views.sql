create or replace view BILL_EXPORT_QB_TF
 (CUSTID,MASTERINVOICE, ITEXT) AS select
 ph.custid,
 ih.masterinvoice,
 '!TRNS,TRNSTYPE,DATE,ACCNT,NAME,AMOUNT,DOCNUM,MEMO,TOPRINT,ADDR1,ADDR2,ADDR3,ADDR4,DUEDATE,CLASS,PONUM'
 from posthdr ph, invoicehdr ih
 where ih.masterinvoice = to_char(ph.invoice, 'FM09999999');

comment on table BILL_EXPORT_QB_TF is '$Id: quick_book_views.sql 1 2008-08-26 12:20:03Z jeff $';


create or replace view BILL_EXPORT_QB_SF
  (CUSTID,MASTERINVOICE, ITEXT) AS select
  ph.custid,
  ih.masterinvoice,
  '!SPL,TRNSTYPE,DATE,ACCNT,NAME,AMOUNT,DOCNUM,MEMO,PRICE,INVITEM,CLASS, , , , , '
  from posthdr ph, invoicehdr ih
  where ih.masterinvoice = to_char(ph.invoice, 'FM09999999');

comment on table BILL_EXPORT_QB_SF is '$Id: quick_book_views.sql 1 2008-08-26 12:20:03Z jeff $';

create or replace view BILL_EXPORT_QB_EF
  (CUSTID,MASTERINVOICE, ITEXT) AS select
  ph.custid,
  ih.masterinvoice,
  '!ENDTRNS, , , , , , , , , , , , , , , '
  from posthdr ph, invoicehdr ih
  where ih.masterinvoice = to_char(ph.invoice, 'FM09999999');


create or replace view BILL_EXPORT_QB_TD
   (CUSTID,
    MASTERINVOICE,
    INVOICE,
    TRNS,
    TRNSTYPE,
    IDATE,
    ACCNT,
    INAME ,
    AMOUNT,
    DOCNUM ,
    MEMO,
    TOPRINT,
    ADDR1,
    ADDR2,
    ADDR3,
    ADDR4,
    DUEDATE,
    CLASS,
    PONUM,
    GLID
    ) AS select
   ph.custid,
   ih.masterinvoice,
   ih.invoice,
   'TRNS',
   'INVOICE',
   ph.invdate,
   'Accounts Receivable',
   c.name,
   ph.amount,
   ih.masterinvoice,
   '',
   'N',
   c.name,
   c.contact,
   c.addr1,
   c.city || ', ' || c.state || ' ' || c.postalcode,
   ph.invdate + 30,
   ih.facility,
   '',
   ''
   from posthdr ph, invoicehdr ih, customer c
   where ih.masterinvoice = to_char(ph.invoice, 'FM09999999')
     and ih.custid = c.custid(+);
comment on table BILL_EXPORT_QB_TD is '$Id: quick_book_views.sql 1 2008-08-26 12:20:03Z jeff $';


create or replace view BILL_EXPORT_QB_SD
   (CUSTID,MASTERINVOICE, INVOICE, TRNS, TRNSTYPE,
    IDATE, ACCNT, INAME, AMOUNT, DOCNUM,
    MEMO, PRICE, INVITEM , CLASS, IRISCLASS, IRISNAME, FACGLACCT, GLACCTFAC ) AS select
   ph.custid,
   ih.masterinvoice,
   ih.invoice,
   'TRNS',
   'INVOICE',
   ph.invdate,
   'Accounts Receivable',
   c.name,
   id.billedamt,
   ih.masterinvoice,
   ih.masterinvoice,
   id.billedrate,
   id.activity,
   ih.facility,
   null,
   null,
   null,
   null
   from posthdr ph, invoicehdr ih, invoicedtl id, customer c
   where ih.masterinvoice = to_char(ph.invoice, 'FM09999999')
     and ih.invoice = id.invoice
     and id.billedamt != 0
     and ih.custid = c.custid(+);
comment on table BILL_EXPORT_QB_SD is '$Id: quick_book_views.sql 1 2008-08-26 12:20:03Z jeff $';



create or replace view BILL_EXPORT_QB_ED
    (CUSTID,MASTERINVOICE, INVOICE, ITEXT) AS select
    ph.custid,
    ih.masterinvoice,
    ih.invoice,
    'ENDTRNS, , , , , , , , , , , , , , , '
    from posthdr ph, invoicehdr ih
    where ih.masterinvoice = to_char(ph.invoice, 'FM09999999');

comment on table BILL_EXPORT_QB_ED is '$Id: quick_book_views.sql 1 2008-08-26 12:20:03Z jeff $';

exit;
