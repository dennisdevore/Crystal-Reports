--
-- $Id$
--
set feedback off verify off;
break on report;
compute count of item on report;
compute sum of units weight cube on report;
spool shipped_items1.txt;
select
item,
sum(orderdtl.qtyship) as units,
sum(orderdtl.weightship) as weight,
sum(orderdtl.cubeship) as cube
from orderdtl, orderhdr
 where orderhdr.custid = 'HP'
	and ordertype = 'O'
	and orderstatus = '9'
	and orderhdr.orderid = orderdtl.orderid
	and orderhdr.shipid = orderdtl.shipid
 group by item
 order by item;
spool off;
exit;
