--
-- $Id$
--
select taskid, orderid, shipid, orderitem, orderlot
from subtasks s
where orderid is not null
and not exists
(select * from commitments c
where s.orderid = c.orderid
  and s.shipid = c.shipid
  and s.orderitem = c.orderitem
  and nvl(s.orderlot,'(none)') = nvl(c.orderlot,'(none)'))
order by orderid;
exit;
