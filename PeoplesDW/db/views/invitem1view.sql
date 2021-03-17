create or replace view invitem
(
itemrowid,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
po,
item,
lotnumber,
businessevent,
activity,
activityabbrev,
dtlcount,
minimum,
minimumord,
calculation,
sumamount,
billmethod,
loadno,
billedqty,
lastuser,
lastupdate,
statususer,
statusupdate,
bmcode,
shipid,
reference,
shiptoname,
pallettype
)
as
select /*+ ordered */ ID.rowid,
       ID.invoice,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       ID.orderid,
       OH.po,
       ID.item,
       ID.lotnumber,
       ID.businessevent,
       ID.activity,
       AC.abbrev,
       1,
       ID.minimum,
       nvl(ID.minimum,0),
       decode(nvl(ID.minimum,-1),
         -1, to_char(billedqty)|| ' '||calceduom
--          || decode(ID.billmethod,'QTYM','%'||ID.moduom,'')
          ||' @ '
          ||  decode(billedrate*100,
                floor(billedrate*100), ltrim(to_char(billedrate, '999,990.99')),
                ltrim(to_char(billedrate))),
         -- ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99'))),
         decode(substr(ID.billmethod,1,2),'SC',
               ' Surcharge @ '||ltrim(to_char(ID.minimum, '990.99'))||'%',
               ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99')))),
       nvl(ID.billedamt,0),
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       decode(ID.loadno, 0, null, ID.loadno),
       ID.billedqty,
       ID.lastuser,
       ID.lastupdate,
       ID.statususer,
       ID.statusupdate,
       ID.billmethod,
       ID.shipid,
       OH.reference,
       decode(OH.shiptoname, null, CO.name, OH.shiptoname),
	   ID.pallettype
  from invoicedtl ID, billingmethod BM, billstatus BS, activity AC, orderhdr OH, consignee CO
 where ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and (ID.invoice > 0 or (ID.invoice < 0 and ID.billstatus in ('E','4')))
   and ID.orderid = OH.orderid(+)
   and ID.shipid = OH.shipid(+)
   and OH.shipto = CO.consignee(+)
union
select /*+ ordered */ ID.rowid,
       -ID.orderid,
       ID.billstatus,
       BS.abbrev,
       ID.facility,
       ID.custid,
       ID.orderid,
       ID.po,
       ID.item,
       ID.lotnumber,
       ID.businessevent,
       ID.activity,
       AC.abbrev,
       1,
       ID.minimum,
       nvl(ID.minimum,0),
       decode(nvl(ID.minimum,-1),
         -1, to_char(billedqty)|| ' '||calceduom
--          || decode(ID.billmethod,'QTYM','%'||ID.moduom,'')
          ||' @ '
          ||  decode(billedrate*100,
                floor(billedrate*100), ltrim(to_char(billedrate, '999,990.99')),
                ltrim(to_char(billedrate))),
         ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99'))),
       nvl(ID.billedamt,0),
       decode(ID.billmethod,'QTYM',BM.abbrev||'-'||ID.moduom,BM.abbrev),
       decode(ID.loadno, 0, null, ID.loadno),
       ID.billedqty,
       ID.lastuser,
       ID.lastupdate,
       ID.statususer,
       ID.statusupdate,
       ID.billmethod,
       ID.shipid,
       OH.reference,
       decode(OH.shiptoname, null, CO.name, OH.shiptoname),
	   ID.pallettype
  from invoicedtl ID, billingmethod BM, billstatus BS, activity AC, orderhdr OH, consignee CO
 where ID.billstatus = BS.code (+)
   and ID.activity = AC.code (+)
   and ID.billmethod = BM.code (+)
   and (ID.invoice = 0)
   and ID.orderid = OH.orderid(+)
   and ID.shipid = OH.shipid(+)
   and OH.shipto = CO.consignee(+);

comment on table invitem is '$Id$';

exit;
