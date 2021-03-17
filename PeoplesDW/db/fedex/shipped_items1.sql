--
-- $Id$
--
set feedback off verify off;
break on report;
compute count of item on report;
compute sum of units weight cube on report;
spool shipped_items1.txt;
select '08/07/2000 hpshopping.com' as sku_summary from dual;
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
        and orderhdr.dateshipped >= to_date('20000807030000', 'yyyymmddhh24miss')
        and orderhdr.dateshipped <  to_date('20000808030000', 'yyyymmddhh24miss')
 group by item
 order by item;
spool off;
exit;

