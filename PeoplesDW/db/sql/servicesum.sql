--
-- $Id$
--
select
substr(hdrpassthruchar07,1,3) as service,
count(1)
from orderhdr
where custid = 'HP'
and orderstatus < '9'
group by hdrpassthruchar07;
exit;
