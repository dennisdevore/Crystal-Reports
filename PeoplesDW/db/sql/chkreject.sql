--
-- $Id$
--
select orderstatus,rejectcode,count(1)
from orderhdr
where custid = 'HP'
and ordertype not in ('R','Q','C')
group by orderstatus,rejectcode;
exit;
