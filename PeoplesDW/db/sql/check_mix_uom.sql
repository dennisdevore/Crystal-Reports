--
-- $Id$
--
select facility, custid, item, count(distinct unitofmeasure)
from plate
where type = 'PA'
group by facility , custid, item
having count(distinct unitofmeasure) > 1
/
