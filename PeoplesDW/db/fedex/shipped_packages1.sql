--
-- $Id$
--
set feedback off verify off;
break on report;
compute count of item on report;
compute sum of units weight cube on report;
spool shipped_packages1.txt;
select '08/07/2000 hpshopping.com' as shipped_packages from dual;
select count(1) as package_count
from shippingplate
 where parentlpid is null
	and custid = 'HP'
	and exists (select * from orderhdr
  where orderhdr.dateshipped >= to_date('20000807030000', 'yyyymmddhh24miss')
    and orderhdr.dateshipped <  to_date('20000808030000', 'yyyymmddhh24miss'));
spool off;
exit;
