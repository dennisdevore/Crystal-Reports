create or replace view invoicemaster1
(
 masterinvoice,
 invstatus,
 custid,
 custname,
 facility,
 postdate,
 printdate,
 invtotal,
 userid,
 csr,
 invoicedate,
 invoice
)
as
select H.masterinvoice,
       H.invstatus,
       H.custid,
       C.name,
       H.facility,
       H.postdate,
       H.printdate,
       sum(nvl(D.billedamt,(nvl(D.calcedamt,0))) * decode(D.invtype,'C',-1,1)),
       H.lastuser,
       C.csr,
       H.invoicedate,
	   H.invoice
  from billstatus B, customer C, invoicedtl D, invoicehdr H
 where H.custid = C.custid (+)
   and H.invstatus = B.code (+)
   and H.invoice = D.invoice(+)
   and '4' != D.billstatus(+)
   and H.masterinvoice is not null
 group by 
       H.masterinvoice,
       H.invstatus,
       H.custid,
       C.name,
       H.facility,
       H.postdate,
       H.printdate,
       H.lastuser,
       C.csr,
       H.invoicedate,
	   H.invoice;
       
comment on table invoicemaster1 is '$Id: invoicemstview1.sql 18639 2017-06-01 18:27:27Z davem $';
       
exit;
