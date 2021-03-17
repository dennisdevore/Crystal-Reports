CREATE OR REPLACE VIEW MASInvoice
(CompanyNo
,DivisionNo
,LocationNo
,InvioiceType
,CustomerNumber
,InvoiceNumber
,ReceiptDate
,ChargeCode
,RateAmount
,RateQty
,InvoiceAmount
)
 as select
'55',
ih.facility,
ih.facility,
decode(ih.invtype,'R', 'RECEIPT', 'S', 'RENEWAL', 'C', 'CREDIT', 'A', 'OUTBOUND', 'ANCILLARY'),
ph.custid,
ph.invoice,
ph.postdate,
id.activity,
id.billedrate,
sum(id.billedqty),
sum(id.billedamt)
from posthdr ph, invoicehdr ih, invoicedtl id
where ih.masterinvoice = to_char(ph.invoice, 'FM09999999')
  and ih.invstatus = '3'
  and id.billstatus = '3'
  and ih.invoice = id.invoice
  and nvl(id.billedamt,0) <> 0
group by '55',ih.facility,ih.facility,
          decode(ih.invtype,'R', 'RECEIPT', 'S', 'RENEWAL', 'C', 'CREDIT', 'A', 'OUTBOUND', 'ANCILLARY'),
          ph.custid, ph.invoice, ph.postdate, id.activity, id.billedrate;

 exit;
