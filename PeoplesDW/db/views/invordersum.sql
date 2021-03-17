create or replace view alps.invordersum
(
    billstatus,
    billstatusabbrev,
    facility,
    custid,
    custname,
    orderid,
    po,
    dtlcount,
    sumamount
)
as
select invoicedtl.billstatus,
       billstatus.abbrev,
       invoicedtl.facility,
       invoicedtl.custid,
       customer.name,
       invoicedtl.orderid,
       invoicedtl.po,
       count(1),
       nvl(sum(invoicedtl.billedamt),0)
  from invoicedtl, customer, billstatus
 where invoicedtl.custid = customer.custid (+)
   and invoicedtl.billstatus = billstatus.code (+)
 group by invoicedtl.billstatus,
          billstatus.abbrev,
          invoicedtl.facility,
          invoicedtl.custid,
          customer.name,
          invoicedtl.orderid,
          invoicedtl.po;

comment on table invordersum is '$Id';

exit;
