CREATE OR REPLACE VIEW BILL_EXPORT_FOR_OPEN_VIEW
(CUSTID, INVOICE, INVDATE, POSTDATE, AMOUNT)
AS 
select
   custid,
   to_char(invoice,'FM099999'),
   to_char(invdate,'MMDDYYYY'),
   postdate,
   to_char(-1*amount, 'FMS0999999999.00')
from posthdr;

exit;
