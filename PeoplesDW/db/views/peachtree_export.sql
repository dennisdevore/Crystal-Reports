CREATE OR REPLACE VIEW PEACHTREE_EXPORT ( CUSTID,
INVOICE, USEINVOICE, CREDITMEMO, POSTDATE,
DUEDATE, ARACCOUNT, NUMBEROFDISTRIBUTIONS, APPLYTOINVOICEDISTRIBUTION,
GLACCOUNT, DEBITCREDIT, TAXTYPE, INVDATE, INVDUEDATE ) AS select
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
   ph.postdate + nvl((select abbrev from AR_DAYS where code = 'DAYS'), 30),
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
      then to_char(pd.debit,'99999.99') else to_char(-1 * pd.credit, '99999.99')
 end,
   '1' ,
   ph.invdate,
   ph.invdate + nvl((select abbrev from AR_DAYS where code = 'DAYS'), 30)
from posthdr ph, postdtl pd
where  ph.invoice = pd.invoice and pd.account <> (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT');

comment on table PEACHTREE_EXPORT is '$Id: peachtree_export.sql 135 2005-09-06 12:14:48Z ed $';

exit;
