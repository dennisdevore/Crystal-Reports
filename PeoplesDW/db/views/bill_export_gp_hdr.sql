CREATE OR REPLACE VIEW BILL_EXPORT_GP_HDR ( CUSTID,
INVOICE, DOCTYPE, POSTDATE, INVDATE, AMOUNT, FACILITY ) AS select
   ph.custid,
   ph.invoice,
   case when (select count(1)
                 from postdtl pds
                 where pds.invoice = ph.invoice
                   and pds.account = (select defaultvalue
                                        from systemdefaults
                                        where defaultid = 'AR_ACCOUNT')
                   and pds.credit > 0) = 0
        then '1' else '6' end,
   ph.postdate,
   ph.invdate,
   to_char(abs(ph.amount),'999999.99'),
   ph.facility
from posthdr ph;

exit;

