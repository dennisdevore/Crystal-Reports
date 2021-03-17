CREATE OR REPLACE VIEW BILL_EXPORT_GP_DTL
(INVOICE, ACCOUNT, DISTTYPE, DEBIT, CREDIT,SEQ,
 VDEBIT, VCREDIT, GLACCOUNT) as select
   ph.invoice,
   rtrim(ph.facility) || pd.account,
   '9',
   pd.debit,
   pd.credit,
   '1',
   to_char(pd.debit , 'FM999990.00'),
   to_char(pd.credit , 'FM999990.00'),
   pd.account
from posthdr ph, postdtl pd
where ph.invoice = pd.invoice
  and pd.account <> (select defaultvalue
                     from systemdefaults
                     where defaultid = 'AR_ACCOUNT')
union
select
   ph.invoice,
   (select defaultvalue from systemdefaults where defaultid = 'AR_ACCOUNT'),
   '3',
   pd.credit,
   pd.debit,
   '1',
   to_char(pd.debit , 'FM999990.00'),
   to_char(pd.credit , 'FM999990.00'),
   pd.account
from posthdr ph, postdtl pd
where ph.invoice = pd.invoice
  and pd.account <> (select defaultvalue
                     from systemdefaults
                     where defaultid = 'AR_ACCOUNT');

exit;

