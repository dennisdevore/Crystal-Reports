create or replace view revenuerptview
(facility
,custid
,revenuegroup
,activity
,chargedate
,actual
,linemin
,itemmin
,ordermin
,invoicemin
,accountmin
,total
)
as
select
 I.facility
,I.custid
,A.revenuegroup
,I.activity
,H.invoicedate
,sum(decode(billmethod,'FLAT',decode(I.invtype,'C',-billedamt,billedamt),
        'QTY',decode(I.invtype,'C',-billedamt,billedamt),
        'CWT',decode(I.invtype,'C',-billedamt,billedamt),0))
,sum(decode(billmethod,'LINE',decode(I.invtype,'C',-billedamt,billedamt),0))
,sum(decode(billmethod,'ITEM',decode(I.invtype,'C',-billedamt,billedamt),0))
,sum(decode(billmethod,'ORDR',decode(I.invtype,'C',-billedamt,billedamt),0))
,sum(decode(billmethod,'INV',decode(I.invtype,'C',-billedamt,billedamt),0))
,sum(decode(billmethod,'ACCT',decode(I.invtype,'C',-billedamt,billedamt),0))
,sum(decode(I.invtype,'C',-billedamt,billedamt))
from  invoicehdr H, activity A, invoicedtl I
where I.activity = A.code(+)
  and I.billstatus = '3'
  and H.invoice = I.invoice
group by 
 I.facility
,I.custid
,A.revenuegroup
,I.activity
,H.invoicedate;

comment on table revenuerptview is '$Id';

exit;
