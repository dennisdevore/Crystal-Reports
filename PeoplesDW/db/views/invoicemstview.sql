create or replace view invoicemaster
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
 invoicedate
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
       H.invoicedate
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
       H.invoicedate;
       
comment on table invoicemaster is '$Id$';
       
exit;
