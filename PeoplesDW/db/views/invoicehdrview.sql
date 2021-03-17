create or replace view invoicehdrsum
(
 masterinvoice,
 invoice,
 invdate,
 invtype,
 invtypedesc,
 invstatus,
 invstatusdesc,
 custid,
 custname,
 facility,
 postdate,
 printdate,
 invtotal,
 orderid,
 shipid,
 loadno,
 csr,
 lastuser,
 lastupdate,
 statususer,
 statusupdate
)
as
select H.masterinvoice,
       H.invoice,
       H.invdate,
       H.invtype,
       IT.abbrev,
       H.invstatus,
       NVL(B.abbrev,'UNKNOWN'),
       H.custid,
       C.name,
       H.facility,
       H.postdate,
       H.printdate,
       sum(nvl(D.billedamt,(nvl(D.calcedamt,0)))),
       decode(H.invstatus,'E',floor((H.invoice*-1)/100),H.orderid),
       decode(H.invstatus,'E',mod((H.invoice*-1),100),null),
       H.loadno,
       C.csr,
       H.lastuser,
       H.lastupdate,
       H.statususer,
       H.statusupdate
  from billstatus B, invoicetypes IT, customer C, invoicedtl D, invoicehdr H
 where H.custid = C.custid (+)
   and H.invtype = IT.code (+)
   and H.invstatus = B.code (+)
   and H.invoice = D.invoice(+)
   and '4' != D.billstatus(+)
 group by
       H.masterinvoice,
       H.invoice,
       H.invdate,
       H.invtype,
       IT.abbrev,
       H.invstatus,
       NVL(B.abbrev,'UNKNOWN'),
       H.custid,
       C.name,
       H.facility,
       H.postdate,
       H.printdate,
       decode(H.invstatus,'E',floor((H.invoice*-1)/100),H.orderid),
       decode(H.invstatus,'E',mod((H.invoice*-1),100),null),
       H.loadno,
       C.csr,
       H.lastuser,
       H.lastupdate,
       H.statususer,
       H.statusupdate
UNION
select to_char(decode(ID.orderid,-1,ID.orderid,null)),
       -ID.orderid,
       nvl(ID.expiregrace,O.entrydate),
       O.ordertype,
       OT.abbrev,
       '0',
       'Not Invoiced',
       ID.custid,
       C.name,
       ID.facility,
       to_date(NULL,'YYYYMMDD'),
       to_date(NULL,'YYYYMMDD'),
       zbut.invoice_total(-ID.orderid, 'X'),
       -ID.orderid,
       0,
       0,
       C.csr,
       '',
       to_date(NULL,'YYYYMMDD'),
       '',
       to_date(NULL,'YYYYMMDD')
  from billstatus B, ordertypes OT, customer C, orderhdr O, invoicedtl ID
 where (ID.invoice = 0)
   and ID.custid = C.custid (+)
   and O.orderid = ID.orderid
   and ID.billstatus = B.code (+)
   and O.ordertype = OT.code(+)
 group by 
       decode(ID.orderid,-1,ID.orderid,null),
       -ID.orderid,
       nvl(ID.expiregrace,O.entrydate),
       O.ordertype,
       OT.abbrev,
       '0',
       'Not Invoiced',
       ID.custid,
       C.name,
       ID.facility,
       NULL,
       NULL,
       C.csr,
       NULL,
       NULL,
       NULL,
       NULL;
       
comment on table invoicehdrsum is '$Id$';
       
exit;
