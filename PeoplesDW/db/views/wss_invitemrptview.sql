create or replace view wss_invitemrpt
(
idrowid,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
shipid,
po,
item,
lotnumber,
activitydate,
activity,
activityabbrev,
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
revenuegroup
)
as
select ID.rowid,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(ID.orderid,0,99999999,ID.orderid),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       ID.lotnumber,
       ID.activitydate,
       ID.activity,
       AC.abbrev,
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
       AC.revenuegroup
  from customer C, billingmethod BM, billstatus BS, activity AC, invoicedtl ID, custitem CI
 where ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item     = CI.item (+)
   and ID.invoice > 0
   and ID.billedqty != 0
   and ID.billstatus != '4'
   and C.custid = ID.custid
   and ID.invtype != 'A'
   and ID.invtype != 'R'
UNION
select ID.rowid,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(sign(ID.orderid),1,ID.orderid,null),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       null,
       trunc(ID.activitydate),
       ID.activity,
       AC.abbrev,
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
	AC.revenuegroup
  from customer C, billingmethod BM, billstatus BS, activity AC, invoicedtl ID, custitem CI
 where ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item   = CI.item(+)
   and ID.invoice > 0
   and ID.billedqty != 0
   and ID.billstatus != '4'
   and C.custid = ID.custid
   and ID.invtype = 'A'
   and NVL(C.sumassessorial,'N') != 'Y'
  group by
       ID.rowid,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(sign(ID.orderid),1,ID.orderid,null),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       null,
       trunc(ID.activitydate),
       ID.activity,
       AC.abbrev,
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
	CI.length,CI.width,CI.height,AC.revenuegroup
UNION
select distinct ID.rowid,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       decode(ID.orderid,0,99999999,ID.orderid),
       nvl(ID.shipid,1),
       ID.po,
       ID.item,
       ID.lotnumber,
       ID.activitydate,
       ID.activity,
       AC.abbrev,
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
       AC.revenuegroup
  from customer C, billingmethod BM, billstatus BS, activity AC, invoicedtl ID, custitem CI
 where
       ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.custid = CI.custid(+)
   and ID.item   = CI.item(+)
   and ID.invoice > 0
   and ID.billedqty != 0
   and ID.billstatus != '4'
   and C.custid = ID.custid
   and ID.invtype = 'R'
  UNION
select decode(C.custid,'JoW',C.rowid,null),
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
       trunc(sysdate),
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
       null
  from customer C, billingmethod BM, billstatus BS, activity AC, invoicehdr IH, invoicedtl ID
 where ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and ID.invoice > 0
   and ID.billedqty != 0
   and ID.billstatus != '4'
   and C.custid = ID.custid
   and ID.invtype = 'A'
   and NVL(C.sumassessorial,'N') = 'Y'
   and IH.invoice = ID.invoice
 group by decode(C.custid,'JoW',C.rowid,null), ID.invoice, IH.orderid, 1, ID.custid, trunc(sysdate);

comment on table invitemrpt is '$Id: wss_invitemrptview.sql 88 2005-08-15 12:14:17Z ed $';

exit;
