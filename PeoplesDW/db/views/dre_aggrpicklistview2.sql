create or replace view DRE_AGGRPICKLISTVIEW2 as
select * from DRE_AGGRPICKLISTVIEW
union 
select 0 as wave,null as wave_desc,0 as taskid,
null as tasktype,a.fromfacility as facility, a.item,c.descr as item_desc,'PRE-ORDER' as lot,null as fromlpid,'??' as location,a.uom,
a.qtyorder - nvl(b.qty,0) as qty,a.orderid,a.shipid,null as picktype,
null as shipplatetype,c.serialrequired,a.weightorder - nvl(b.wght,0) as wght,
(a.qtyorder - nvl(b.qty,0)) * c.cube/1728 as cube,
c.LOTREQUIRED,c.USER1REQUIRED,c.USER2REQUIRED,c.USER3REQUIRED,
 (a.weightorder - nvl(b.wght,0) + (zlbl.uom_qty_conv(a.custid,a.item,a.qtyorder,a.uom,c.baseuom) * nvl(c.tareweight,0)) 
	- nvl(b.grossweight,0) ) as grossweight,to_date('1/1/1900','mm/dd/yyyy') as MFG_DATE,
	  a.lineorder
from orderdtl a, DRE_AGGRPICKLISTVIEWSUM b,  custitem c
where a.orderid = b.orderid (+) and
a.shipid = b.shipid (+) and
a.item = b.item (+) and
a.uom = b.uom (+) and
a.qtyorder - nvl(b.qty,0) > 0 and
a.item = c.item and
a.custid = c.custid;
comment on table DRE_AGGRPICKLISTVIEW2 is '$Id$';
exit;
