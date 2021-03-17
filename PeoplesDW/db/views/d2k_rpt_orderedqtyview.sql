create or replace view d2k_rpt_orderqtyview
(
       CUSTID,
       FACILITY,
       ITEM,
       QTYORDER
)
as
select oh.custid,
       oh.fromfacility,
       od.item,
       sum(od.qtyorder)
  from orderhdr oh,
       orderdtl od
 where oh.orderid = od.orderid
   and oh.shipid = od.shipid
   and oh.orderstatus in ('0','1')
   and od.linestatus = 'A'
 group by oh.custid,
       oh.fromfacility,
       od.item;

comment on table d2k_rpt_orderqtyview is '$Id$';        
       
exit;
