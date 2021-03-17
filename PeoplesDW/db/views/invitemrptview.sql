create or replace view invitemrpt
(
idrowid,
masterinvoice,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
shipid,
po,
item,
itemdesc,
lotnumber,
activitydate,
activity,
activityabbrev,
activitydescr,
enteredqty,
entereduom,
calceduom,
billedqty,
billedrate,
billedamt,
minimum,
minimumord,
calculation,
sumamount,
billmethod,
weight,
useinvoice,
moduom,
lpid,
gross,
length,
width,
height,
revenuegroup,
orderitem,
orderitemdesc,
shiptoname
)
as
select ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(ID.orderid,0,99999999,ID.orderid),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       CI.descr,
       ID.lotnumber,
       ID.activitydate,
       ID.activity,
       AC.abbrev,
       AC.descr,
       ID.enteredqty,
       ID.entereduom,
       ID.calceduom,
       ID.billedqty,
       ID.billedrate,
       ID.billedamt,
       ID.minimum,
       -- nvl(ID.minimum,0),
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       decode(nvl(ID.minimum,-1),
         -1, to_char(billedqty)|| ' '||calceduom||' @ '
          ||  decode(billedrate*100,
                floor(billedrate*100), ltrim(to_char(billedrate, '999,990.99')),
                ltrim(to_char(billedrate))),
         -- ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99'))),
         decode(substr(ID.billmethod,1,2),'SC',
               ' Surcharge @ '||ltrim(to_char(ID.minimum, '990.99'))||'%',
               ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99')))),
       nvl(ID.billedamt,0),
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       ID.weight,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
       nvl(decode(ID.weight,0,null,ID.weight),-1*(zlbl.uom_qty_conv(ID.custid,ID.item,ID.billedqty,ID.calceduom,CI.baseuom) *
		nvl(CI.tareweight,0))) +
		 (zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,CI.baseuom) *
			 nvl(CI.tareweight,0)),
       CI.length,CI.width,CI.height,
       AC.revenuegroup,
       CI2.item,
       CI2.descr,
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC, custitem CI,
       orderhdr OH, consignee CO, orderdtl OD, custitem CI2
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item     = CI.item (+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype != 'A'
   and ID.invtype != 'R'
   and ID.orderid = OH.orderid (+)
   and ID.shipid = OH.shipid (+)
   and OH.shipto = CO.consignee (+)
   and ID.orderid = OD.orderid (+)
   and ID.shipid = OD.shipid (+)
   and ID.orderitem = OD.item (+)
   and nvl(ID.orderlot,'(none)') = nvl(OD.lotnumber (+), '(none)')
   and OD.custid = CI2.custid (+)
   and OD.item = CI2.item (+)
UNION
select ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(sign(ID.orderid),1,ID.orderid,null),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       CI.descr,
       ID.lotnumber,
       trunc(ID.activitydate),
       ID.activity,
       AC.abbrev,
       AC.descr,
       0,
       ' ',
       ID.calceduom,
       sum(ID.billedqty),
       ID.billedrate,
       sum(ID.billedamt),
       ID.minimum,
       -- 0,
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       ' ',
       0,
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       0,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
       nvl(decode(ID.weight,0,null,ID.weight),-1*(zlbl.uom_qty_conv(ID.custid,ID.item,ID.billedqty,ID.calceduom,CI.baseuom) *
		nvl(CI.tareweight,0))) +
		 (zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,CI.baseuom) *
			 nvl(CI.tareweight,0)),
	CI.length,CI.width,CI.height,
	AC.revenuegroup,
       CI2.item,
       CI2.descr,
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC, custitem CI,
       orderhdr OH, consignee CO, orderdtl OD, custitem CI2
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item   = CI.item(+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype = 'A'
   and NVL(C.sumassessorial,'N') != 'Y'
   and ID.orderid = OH.orderid (+)
   and ID.shipid = OH.shipid (+)
   and OH.shipto = CO.consignee (+)
   and ID.orderid = OD.orderid (+)
   and ID.shipid = OD.shipid (+)
   and ID.orderitem = OD.item (+)
   and nvl(ID.orderlot,'(none)') = nvl(OD.lotnumber (+), '(none)')
   and OD.custid = CI2.custid (+)
   and OD.item = CI2.item (+)
  group by
       ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(sign(ID.orderid),1,ID.orderid,null),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       CI.descr,
       ID.lotnumber,
       trunc(ID.activitydate),
       ID.activity,
       AC.abbrev,
       AC.descr,
       0,
       ' ',
       ID.calceduom,
       ID.billedrate,
       ID.minimum,
       -- 0,
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       ' ',
       0,
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       0,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
      nvl(decode(ID.weight,0,null,ID.weight),-1*(zlbl.uom_qty_conv(ID.custid,ID.item,ID.billedqty,ID.calceduom,CI.baseuom) *
		nvl(CI.tareweight,0))) +
		 (zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,CI.baseuom) *
			 nvl(CI.tareweight,0)),
	CI.length,CI.width,CI.height,AC.revenuegroup,
       CI2.item,
       CI2.descr,
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
UNION
select ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(ID.orderid,0,99999999,ID.orderid),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       CI.descr,
       ID.lotnumber,
       ID.activitydate,
       ID.activity,
       AC.abbrev,
       AC.descr,
       ID.enteredqty,
       ID.entereduom,
       ID.calceduom,
       ID.billedqty,
       ID.billedrate,
       ID.billedamt,
       ID.minimum,
       -- nvl(ID.minimum,0),
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       decode(nvl(ID.minimum,-1),
         -1, to_char(billedqty)|| ' '||calceduom||' @ '
          ||  decode(billedrate*100,
                floor(billedrate*100), ltrim(to_char(billedrate, '999,990.99')),
                ltrim(to_char(billedrate))),
         -- ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99'))),
         decode(substr(ID.billmethod,1,2),'SC',
               ' Surcharge @ '||ltrim(to_char(ID.minimum, '990.99'))||'%',
               ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99')))),
       nvl(ID.billedamt,0),
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       ID.weight,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
       nvl(decode(ID.weight,0,null,ID.weight),-1*(zlbl.uom_qty_conv(ID.custid,ID.item,ID.billedqty,ID.calceduom,CI.baseuom) *
		nvl(CI.tareweight,0))) +
		 (zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,CI.baseuom) *
			 nvl(CI.tareweight,0)),
       CI.length,CI.width,CI.height,
       AC.revenuegroup,
       CI2.item,
       CI2.descr,
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC, custitem CI,
       orderhdr OH, consignee CO, orderdtl OD, custitem CI2
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item   = CI.item(+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype = 'R'
   and ID.orderid = OH.orderid (+)
   and ID.shipid = OH.shipid (+)
   and OH.shipto = CO.consignee (+)
   and ID.orderid = OD.orderid (+)
   and ID.shipid = OD.shipid (+)
   and ID.orderitem = OD.item (+)
   and nvl(ID.orderlot,'(none)') = nvl(OD.lotnumber (+), '(none)')
   and OD.custid = CI2.custid (+)
   and OD.item = CI2.item (+)
  UNION
select decode(C.custid,'JoW',C.rowid,null),
       IH.masterinvoice,
       ID.invoice,
       null,
       null,
       null,
       ID.custid,
       IH.orderid,
       1,
       null,
       null,
       null,
       null,
       trunc(sysdate),
       null,
       null,
       null,
       0,
       null,
       null,
       0,
       0,
       0,
       0,
       0,
       null,
       0,
       null,
       0,
       null,
       null,
       null,
       0,
       0,
       0,
       0,
       null,
       null,
       null,
       null
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype = 'A'
   and NVL(C.sumassessorial,'N') = 'Y'
 group by decode(C.custid,'JoW',C.rowid,null),IH.masterinvoice,ID.invoice, IH.orderid, 1, ID.custid, trunc(sysdate);
comment on table invitemrpt is '$Id$';

create or replace view pho_invitemrpt
(
idrowid,
masterinvoice,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
shipid,
po,
item,
itemdescr,
lotnumber,
activitydate,
activity,
activityabbrev,
activitydescr,
enteredqty,
entereduom,
calceduom,
billedqty,
billedrate,
billedamt,
minimum,
minimumord,
calculation,
sumamount,
billmethodabbrev,
billmethod,
weight,
useinvoice,
moduom,
lpid,
gross,
length,
width,
height,
revenuegroup,
comment1,
enteredqtypcs,
enteredqtyctn,
shiptoname
)
as
select ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(ID.orderid,0,99999999,ID.orderid),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       CI.descr,
       ID.lotnumber,
       ID.activitydate,
       ID.activity,
       AC.abbrev,
       AC.descr,
       ID.enteredqty,
       ID.entereduom,
       ID.calceduom,
       ID.billedqty,
       ID.billedrate,
       ID.billedamt,
       ID.minimum,
       -- nvl(ID.minimum,0),
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       decode(nvl(ID.minimum,-1),
         -1, to_char(billedqty)|| ' '||calceduom||' @ '
          ||  decode(billedrate*100,
                floor(billedrate*100), ltrim(to_char(billedrate, '999,990.99')),
                ltrim(to_char(billedrate))),
         -- ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99'))),
         decode(substr(ID.billmethod,1,2),'SC',
               ' Surcharge @ '||ltrim(to_char(ID.minimum, '990.99'))||'%',
               ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99')))),
       nvl(ID.billedamt,0),
       ID.billmethod,
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       ID.weight,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
       nvl(decode(ID.weight,0,null,ID.weight),-1*(zlbl.uom_qty_conv(ID.custid,ID.item,ID.billedqty,ID.calceduom,CI.baseuom) *
		nvl(CI.tareweight,0))) +
		 (zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,CI.baseuom) *
			 nvl(CI.tareweight,0)),
       CI.length,CI.width,CI.height,
       AC.revenuegroup,
       zinvcmt.invoiceitmcomments(ID.rowid,ID.invoice),
       zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,'PCS'),
       zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,'CTN'),
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC, custitem CI,
       orderhdr OH, consignee CO
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item     = CI.item (+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype != 'A'
   and ID.invtype != 'R'
   and ID.orderid = OH.orderid (+)
   and ID.shipid = OH.shipid (+)
   and OH.shipto = CO.consignee (+)
UNION
select ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(sign(ID.orderid),1,ID.orderid,null),
       nvl(ID.shipid,1),
       ID.po,
       null,
       null,
       null,
       trunc(ID.activitydate),
       ID.activity,
       AC.abbrev,
       AC.descr,
       0,
       ' ',
       ID.calceduom,
       sum(ID.billedqty),
       ID.billedrate,
       sum(ID.billedamt),
       ID.minimum,
       -- 0,
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       ' ',
       0,
       ID.billmethod,
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       0,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
       sum(nvl(decode(ID.weight,0,null,ID.weight),-1*(zlbl.uom_qty_conv(ID.custid,ID.item,ID.billedqty,ID.calceduom,CI.baseuom) *
		nvl(CI.tareweight,0))) +
		 (zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,CI.baseuom) *
			 nvl(CI.tareweight,0))),
	CI.length,CI.width,CI.height,
	AC.revenuegroup,
    zinvcmt.invoiceitmcomments(ID.rowid,ID.invoice),
       0,
       0,
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC, custitem CI,
       orderhdr OH, consignee CO
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item   = CI.item(+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype = 'A'
   and NVL(C.sumassessorial,'N') != 'Y'
   and ID.orderid = OH.orderid (+)
   and ID.shipid = OH.shipid (+)
   and OH.shipto = CO.consignee (+)
  group by
       ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(sign(ID.orderid),1,ID.orderid,null),
       nvl(ID.shipid,1),
       ID.po,
       null,
       null,
       null,
       trunc(ID.activitydate),
       ID.activity,
       AC.abbrev,
       AC.descr,
       0,
       ' ',
       ID.calceduom,
       ID.billedrate,
       ID.minimum,
       -- 0,
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       ' ',
       0,
       ID.billmethod,
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       0,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
       CI.length,CI.width,CI.height,AC.revenuegroup,
       zinvcmt.invoiceitmcomments(ID.rowid,ID.invoice),
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
UNION
select ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(ID.orderid,0,99999999,ID.orderid),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       CI.descr,
       ID.lotnumber,
       ID.activitydate,
       ID.activity,
       AC.abbrev,
       AC.descr,
       ID.enteredqty,
       ID.entereduom,
       ID.calceduom,
       ID.billedqty,
       ID.billedrate,
       ID.billedamt,
       ID.minimum,
       -- nvl(ID.minimum,0),
       decode(ID.billmethod, 'SCLN',11,'SCIT',12,'SCOR',13,'SCIN',14,
                             'LINE',1,'ITEM',2,'ORDR',3,'INV',4,'ACCT',0,
                             nvl(ID.minimum,0)),
       decode(nvl(ID.minimum,-1),
         -1, to_char(billedqty)|| ' '||calceduom||' @ '
          ||  decode(billedrate*100,
                floor(billedrate*100), ltrim(to_char(billedrate, '999,990.99')),
                ltrim(to_char(billedrate))),
         -- ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99'))),
         decode(substr(ID.billmethod,1,2),'SC',
               ' Surcharge @ '||ltrim(to_char(ID.minimum, '990.99'))||'%',
               ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99')))),
       nvl(ID.billedamt,0),
       ID.billmethod,
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       ID.weight,
       ID.useinvoice,
       ID.moduom,
       ID.lpid,
       nvl(decode(ID.weight,0,null,ID.weight),-1*(zlbl.uom_qty_conv(ID.custid,ID.item,ID.billedqty,ID.calceduom,CI.baseuom) *
		nvl(CI.tareweight,0))) +
		 (zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,CI.baseuom) *
			 nvl(CI.tareweight,0)),
       CI.length,CI.width,CI.height,
       AC.revenuegroup,
       zinvcmt.invoiceitmcomments(ID.rowid,ID.invoice),
       zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,'PCS'),
       zlbl.uom_qty_conv(ID.custid,ID.item,ID.enteredqty,ID.entereduom,'CTN'),
       decode(OH.shiptoname, null, CO.name, OH.shiptoname)
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC, custitem CI,
       orderhdr OH, consignee CO
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item   = CI.item(+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype = 'R'
   and ID.orderid = OH.orderid (+)
   and ID.shipid = OH.shipid (+)
   and OH.shipto = CO.consignee (+)
  UNION
select ID.rowid,
       IH.masterinvoice,
       ID.invoice,
       null,
       null,
       null,
       ID.custid,
       IH.orderid,
       1,
       null,
       null,
       null,
       null,
       trunc(sysdate),
       null,
       null,
       null,
       0,
       null,
       null,
       0,
       0,
       0,
       0,
       0,
       null,
       0,
       null,
       null,
       0,
       null,
       null,
       null,
       0,
       0,
       0,
       0,
       null,
       zinvcmt.invoiceitmcomments(ID.rowid,ID.invoice),
       0,
       0,
       null
  from invoicehdr IH, invoicedtl ID, customer C, billingmethod BM, billstatus BS, activity AC
 where IH.invoice = ID.invoice
   and ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ((ID.invoice > 0 and ID.billstatus !='4') or (ID.invoice < 0 and ID.billstatus in ('4','E')))
   and ID.billedqty != 0
   and C.custid = ID.custid
   and ID.invtype = 'A'
   and NVL(C.sumassessorial,'N') = 'Y'
   and IH.invoice = ID.invoice
 group by ID.rowid, IH.masterinvoice, ID.invoice, IH.orderid, 1, ID.custid, trunc(sysdate),
       zinvcmt.invoiceitmcomments(ID.rowid,ID.invoice);

comment on table pho_invitemrpt is '$Id$';

create or replace view invitemsumrpt
(
idrowid,
masterinvoice,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
shipid,
po,
item,
itemdesc,
lotnumber,
activitydate,
activity,
activityabbrev,
activitydescr,
enteredqty,
entereduom,
calceduom,
billedqty,
billedrate,
billedamt,
minimum,
minimumord,
calculation,
sumamount,
billmethod,
weight,
useinvoice,
moduom,
lpid,
gross,
length,
width,
height,
revenuegroup,
orderitem,
orderitemdesc,
shiptoname
)
as
select
idrowid,
masterinvoice,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
shipid,
po,
item,
itemdesc,
lotnumber,
activitydate,
activity,
activityabbrev,
activitydescr,
enteredqty,
entereduom,
calceduom,
billedqty,
billedrate,
billedamt,
minimum,
minimumord,
calculation,
sumamount,
billmethod,
weight,
useinvoice,
moduom,
lpid,
gross,
length,
width,
height,
revenuegroup,
orderitem,
orderitemdesc,
shiptoname
from invitemrpt
where substr(activity,1,2) <> 'SM'
and substr(activity,1,2) <> 'SL'
union
select
idrowid,
masterinvoice,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
shipid,
po,
item,
itemdesc,
lotnumber,
activitydate,
activity,
activityabbrev,
activitydescr,
nvl((select sum(enteredqty)
from invitemrpt
where invoice=iir.invoice
and nvl(item,'(none)')=nvl(iir.item,'(none)')
and nvl(lotnumber,'(none)')=nvl(iir.lotnumber,'(none)')
and nvl(orderid,0)=nvl(iir.orderid,0)
and nvl(shipid,0)=nvl(iir.shipid,0)
and substr(activity,1,2) = 'SL'),0) enteredqty,
entereduom,
calceduom,
nvl((select sum(billedqty)
from invitemrpt
where invoice=iir.invoice
and nvl(item,'(none)')=nvl(iir.item,'(none)')
and nvl(lotnumber,'(none)')=nvl(iir.lotnumber,'(none)')
and nvl(orderid,0)=nvl(iir.orderid,0)
and nvl(shipid,0)=nvl(iir.shipid,0)
and substr(activity,1,2) = 'SL'),0) billedqty,
billedrate,
nvl((select sum(billedamt)
from invitemrpt
where invoice=iir.invoice
and nvl(item,'(none)')=nvl(iir.item,'(none)')
and nvl(lotnumber,'(none)')=nvl(iir.lotnumber,'(none)')
and nvl(orderid,0)=nvl(iir.orderid,0)
and nvl(shipid,0)=nvl(iir.shipid,0)
and substr(activity,1,2) = 'SL'),0) billedamt,
minimum,
minimumord,
calculation,
nvl((select sum(sumamount)
from invitemrpt
where invoice=iir.invoice
and nvl(item,'(none)')=nvl(iir.item,'(none)')
and nvl(lotnumber,'(none)')=nvl(iir.lotnumber,'(none)')
and nvl(orderid,0)=nvl(iir.orderid,0)
and nvl(shipid,0)=nvl(iir.shipid,0)
and substr(activity,1,2) = 'SL'),0) sumamount,
billmethod,
nvl((select sum(weight)
from invitemrpt
where invoice=iir.invoice
and nvl(item,'(none)')=nvl(iir.item,'(none)')
and nvl(lotnumber,'(none)')=nvl(iir.lotnumber,'(none)')
and nvl(orderid,0)=nvl(iir.orderid,0)
and nvl(shipid,0)=nvl(iir.shipid,0)
and substr(activity,1,2) = 'SL'),0.0) weight,
useinvoice,
moduom,
lpid,
gross,
length,
width,
height,
revenuegroup,
orderitem,
orderitemdesc,
shiptoname
from invitemrpt iir
where substr(activity,1,2) = 'SM';

comment on table pho_invitemrpt is '$Id$';

exit;
