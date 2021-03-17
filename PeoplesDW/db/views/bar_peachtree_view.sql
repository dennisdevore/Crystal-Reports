CREATE OR REPLACE VIEW BAR_PEACHTREE_VIEW
(CUSTID, INVOICE, USEINVOICE, CREDITMEMO, POSTDATE,
 DUEDATE, ARACCOUNT, NUMBEROFDISTRIBUTIONS, APPLYTOINVOICEDISTRIBUTION, GLACCOUNT,
 DEBITCREDIT, TAXTYPE, INVDATE, INVDESC, FMTGLACCOUNT)
AS
select
   ph.custid,
   ph.invoice,
   (select to_number(min(id.useinvoice))
      from invoicedtl id, invoicehdr ih
      where ih.masterinvoice = to_char(ph.invoice, 'FM09999999')
           and id.invoice = ih.invoice ),
   case when (select pds.credit
                 from postdtl pds
                 where pds.invoice = ph.invoice and pds.account = (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT')) > 0
        then 'TRUE' else 'FALSE' end,
   ph.postdate,
   ph.invdate + nvl((select abbrev from AR_DAYS where code = 'DAYS'), 30),
   (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT'),
   (select count(*) from postdtl pds
      where pds.invoice = ph.invoice and pds.account <> (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT')),
   case when (select pds.credit
                 from postdtl pds
                 where pds.invoice = ph.invoice and pds.account = (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT')) > 0
         then (select count(*) from postdtl pds
             where pds.invoice = ph.invoice and pds.account <> (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT') and
                    pds.account <= pd.account)
   else null end,
   pd.account,
   case when (select pds.credit
                from postdtl pds
                where pds.invoice = ph.invoice and pds.account = (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT')) > 0
      then to_char(pd.debit,'999999.99') else to_char(-1 * pd.credit, '999999.99')
   end,
   '1',
   ph.invdate,
   case when ((select count(distinct p.descr) from PTInvoiceNames p, invoicehdr ih
               where p.code = ih.invtype and
                   ih.masterinvoice = to_char(ph.invoice, 'FM09999999')) > 1)
      then 'Master Invoice'
      else (select distinct p.descr from PTInvoiceNames p, invoicehdr ih
              where p.code = ih.invtype and
                  ih.masterinvoice = to_char(ph.invoice, 'FM09999999'))
      end,
   case when (ph.facility = 'FRT')
      then substr(pd.account,1,5) || 'ZTK-' || substr(pd.account,6,2)
      else substr(pd.account,1,5) || substr(ph.facility,1,3) || '-' || substr(pd.account,6,2)
      end
from posthdr ph, postdtl pd
where  ph.invoice = pd.invoice and pd.account <> (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT');

exit;
