CREATE OR REPLACE VIEW BILL_EXPORT_MAS_HDR ( CUSTID,
INVOICE, DOCTYPE, POSTDATE, INVDATE, AMOUNT )
AS select
   ph.custid,
   ph.invoice,
   '501',
   ph.postdate,
   ph.invdate,
   (select sum(pds.credit) from postdtl pds where pds.invoice = ph.invoice and pds.credit > 0)
  from posthdr ph, postdtl pd
  where ph.invoice = pd.invoice
    and pd.account <> (select defaultvalue
                         from systemdefaults
                        where defaultid = 'AR_ACCOUNT')
    and pd.credit > 0
union
select
   ph.custid,
   ph.invoice,
   '502',
   ph.postdate,
   ph.invdate,
   (select sum(pds.debit) from postdtl pds where pds.invoice = ph.invoice and pds.debit > 0)
  from posthdr ph, postdtl pd
  where ph.invoice = pd.invoice
    and pd.account <> (select defaultvalue
                         from systemdefaults
                        where defaultid = 'AR_ACCOUNT')
    and pd.debit > 0;

CREATE OR REPLACE VIEW BILL_EXPORT_MAS_DTL ( CUSTID,
INVOICE, DOCTYPE, GLACCOUNT, ACTIVITY, CALCEDUOM,
BILLEDRATE, BILLEDAMT, BILLDEQTY )
AS select
   ph.custid,
   ph.invoice,
   '501',
   a.glacct || '-0' || substr(ph.facility,2),
   id.activity,
   id.calceduom,
   id.billedrate,
   sum(id.billedamt),
   sum(id.billedqty)
  from invoicedtl id, posthdr ph, activity a
where id.invoice in (select invoice from invoicehdr ih
                 where ih.masterinvoice = to_char(ph.invoice, 'FM09999999')
   and ih.invtype != 'C'
   and ih.invstatus = '3')
   and id.billstatus = '3'
   and id.activity = a.code(+)
group by ph.custid, ph.invoice, '501',  a.glacct || '-0' || substr(ph.facility,2),
   id.activity, id.calceduom, id.billedrate
union select
   ph.custid,
   ph.invoice,
   '502',
   a.glacct || '-0' || substr(ph.facility,2),
   id.activity,
   id.calceduom,
   id.billedrate,
   -1 * sum(id.billedamt),
   sum(id.billedqty)
  from invoicedtl id, posthdr ph, activity a
where id.invoice in (select invoice from invoicehdr ih
                 where ih.masterinvoice = to_char(ph.invoice, 'FM09999999')
   and ih.invtype = 'C'
   and ih.invstatus = '3')
   and id.billstatus = '3'
   and id.activity = a.code(+)
group by ph.custid, ph.invoice, '502',  a.glacct || '-0' || substr(ph.facility,2),
   id.activity, id.calceduom, id.billedrate;

exit;

