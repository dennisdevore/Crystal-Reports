create or replace view TASKDEFICIENCYRPTVIEW ( WAVE, 
ORDERID, SHIPID, ITEM, QTYORDER, QTYTASKED )  as
select
oh.wave,
od.orderid,
od.shipid,
od.item,
od.qtyorder,
nvl((select sum(nvl(st.qty,0))
 from subtasks st
 where st.orderid = od.orderid
 and st.shipid = od.shipid
 and st.orderitem = od.item
 and nvl(st.orderlot,'(none)') = nvl(od.lotnumber,'(none)')),0) qtytasked
from orderhdr oh,
orderdtl od
where oh.orderid = od.orderid
and oh.shipid = od.shipid;
comment on table TASKDEFICIENCYRPTVIEW is '$Id: taskdeficiencyrptview.sql 3834 2009-09-02 20:28:39Z ed $';
exit;
