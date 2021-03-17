--
-- $Id$
--
set feedback off verify off;
break on report;
compute count of reference on report;
spool closed_orders1.txt;
select
reference,
status,
substr(dt(statusdate),1,17)
from closed_order_view
 where statusdate >= to_date('200008010000', 'yyyymmddhh24mi')
   and statusdate <  to_date('200008080200', 'yyyymmddhh24mi')
 order by statusdate;

select count(1) as ShippedCount
  from orderhdr
 where custid = 'HP'
	and ordertype = 'O'
	and orderstatus = '9'
   and dateshipped >= to_date('200008010000', 'yyyymmddhh24mi')
   and dateshipped <  to_date('200008080200', 'yyyymmddhh24mi');

select count(1) as CancelledCount
  from orderhdr
 where custid = 'HP'
	and ordertype = 'O'
	and orderstatus = 'X'
   and statusupdate >= to_date('200008010000', 'yyyymmddhh24mi')
   and statusupdate <  to_date('200008080200', 'yyyymmddhh24mi');


spool off;
exit;
