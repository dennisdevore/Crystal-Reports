--
-- $Id$
--
set feedback off verify off;
break on report;
compute count of reference on report;
spool all_orders1.txt;
select '08/07/2000 hpshopping.com' as closed_order_info from dual;
select
reference,
status,
substr(dt(statusdate),1,17) as datetime
from closed_order_view
 where statusdate >= to_date('20000807030000', 'yyyymmddhh24miss')
   and statusdate <  to_date('20000808030000', 'yyyymmddhh24miss')
 order by statusdate;

select count(1) as ReceivedCount
  from orderhdr
 where custid = 'HP'
   and ordertype = 'O'
   and entrydate >= to_date('20000807030000', 'yyyymmddhh24miss')
   and entrydate <  to_date('20000808030000', 'yyyymmddhh24miss');

select count(1) as ShippedCount
  from orderhdr
 where custid = 'HP'
	and ordertype = 'O'
	and orderstatus = '9'
   and dateshipped >= to_date('20000807030000', 'yyyymmddhh24miss')
   and dateshipped <  to_date('20000808030000', 'yyyymmddhh24miss');

select count(1) as CancelledCount
  from orderhdr
 where custid = 'HP'
	and ordertype = 'O'
	and orderstatus = 'X'
   and statusupdate >= to_date('20000807030000', 'yyyymmddhh24miss')
   and statusupdate <  to_date('20000808030000', 'yyyymmddhh24miss');

spool off;
exit;

