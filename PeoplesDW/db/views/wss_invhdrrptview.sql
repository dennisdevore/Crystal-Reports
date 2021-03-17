create or replace view wss_invoicehdrrpt
(
 masterinvoice,
 invoice,
 invdate,
 invoicedate,
 invtypecode,
 invtype,
 invstatus,
 invstatusdesc,
 custid,
 custname,
 facility,
 postdate,
 printdate,
 invtotal,
 item_label,
 lot_label,
 name,
 contact,
 addr1,
 addr2,
 city,
 state,
 postalcode,
 countrycode,
 phone,
 fax,
 email,
 rcvddate,
 prono,
 loadno,
 carrier,
 sumassessorial,
 reference,
 renewfromdate,
 renewtodate,
 orderid,
 shipid,
 po,
 cases,
 vendor,
 misc_total
)
as
select H.masterinvoice,
       H.invoice,
       H.invdate,
       H.invoicedate,
       IT.code,
       IT.abbrev,
       H.invstatus,
       NVL(B.abbrev,'UNKNOWN'),
       H.custid,
       C.name,
       H.facility,
       H.postdate,
       H.printdate,
       zbut.invoice_total(H.invoice, H.invtype),
       zcu.item_label(H.custid),
       zcu.lot_label(H.custid),
       CA.name,
       CA.contact,
       CA.addr1,
       CA.addr2,
       CA.city,
       CA.state,
       CA.postalcode,
       CA.countrycode,
       CA.phone,
       CA.fax,
       CA.email,
       L.rcvddate,
       L.prono,
       L.loadno,
       CR.name,
       decode(NVL(C.sumassessorial,'N'),
                'Y','Y',
                substr(zbut.invoice_check_sum(H.invoice),1,1)),
       OH.reference,
       H.renewfromdate,
       H.renewtodate,
       OH.orderid,
       OH.shipid,
       OH.po,
       nvl((select sum(billedqty) from invoicedtl id where id.invoice = h.invoice and id.calceduom='CS'),0),
       nvl(CO.name, OH.shippername),
	   nvl((select sum(INV.invtotal) from invoicehdrrpt INV where H.masterinvoice = INV.masterinvoice and INV.invtypecode='M'),0)
  from billstatus B, invoicetypes IT, custaddr CA, customer C,
       carrier CR, loads L, orderhdr OH,
       invoicehdr H, consignee CO
 where H.custid = C.custid (+)
   and H.invtype = IT.code (+)
   and H.invstatus = B.code (+)
   and H.loadno = L.loadno(+)
   and L.carrier = CR.carrier(+)
   and H.custid = CA.custid
   and H.orderid = OH.orderid(+)
   and 1 = OH.shipid(+)
   and decode(H.invtype,'C','M',H.invtype) = CA.invtype
   and OH.consignee = CO.consignee (+);

comment on table invoicehdrrpt is '$Id: wss_invhdrrptview.sql 1002 2006-07-14 19:47:12Z eric $';


exit;


