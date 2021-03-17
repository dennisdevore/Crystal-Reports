create or replace view invitemsum
(
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
po,
item,
lotnumber,
activity,
activityabbrev,
dtlcount,
sumamount
)
as
select invoicedtl.invoice,
       invoicedtl.billstatus,
       billstatus.abbrev,
       invoicedtl.facility,
       invoicedtl.custid,
       invoicedtl.orderid,
       invoicedtl.po,
       invoicedtl.item,
       invoicedtl.lotnumber,
       invoicedtl.activity,
       activity.abbrev,
       count(1),
       nvl(sum(invoicedtl.billedamt),0)
  from invoicedtl, billstatus, activity
 where invoicedtl.billstatus = billstatus.code (+)
   and invoicedtl.activity = activity.code (+)
   and invoicedtl.billstatus !='4'
 group by invoicedtl.invoice,
          invoicedtl.billstatus,
          billstatus.abbrev,
          invoicedtl.facility,
          invoicedtl.custid,
          invoicedtl.orderid,
          invoicedtl.po,
          invoicedtl.item,
          invoicedtl.lotnumber,
          invoicedtl.activity,
          activity.abbrev
union
select -invoicedtl.orderid,
       invoicedtl.billstatus,
       billstatus.abbrev,
       invoicedtl.facility,
       invoicedtl.custid,
       invoicedtl.orderid,
       invoicedtl.po,
       invoicedtl.item,
       invoicedtl.lotnumber,
       invoicedtl.activity,
       activity.abbrev,
       count(1),
       nvl(sum(invoicedtl.billedamt),0)
  from invoicedtl, billstatus, activity
 where invoicedtl.billstatus = billstatus.code (+)
   and invoicedtl.activity = activity.code (+)
   and invoicedtl.invoice is null
   and invoicedtl.billstatus !='4'
 group by -invoicedtl.orderid,
          invoicedtl.billstatus,
          billstatus.abbrev,
          invoicedtl.facility,
          invoicedtl.custid,
          invoicedtl.orderid,
          invoicedtl.po,
          invoicedtl.item,
          invoicedtl.lotnumber,
          invoicedtl.activity,
          activity.abbrev;

comment on table invitemsum is '$Id$';

exit;
