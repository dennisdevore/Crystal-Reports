--
-- $Id$
--
break on report;
compute sum of count(1) on report;
compute sum of sum(quantity) on report;
select custid,type,count(1),sum(quantity)
from plate
where status = 'P'
group by custid,type
order by custid,type;
select custid,quantity,count(1),sum(quantity)
  from plate p1
where type = 'MP'
and not exists
(select * from plate p2
  where p2.parentlpid = p1.lpid)
group by custid,quantity;
select custid,lpid,quantity,lastupdate
  from plate p1
where type = 'MP'
and not exists
(select * from plate p2
  where p2.parentlpid = p1.lpid)
and lastupdate < sysdate - 1
order by lastupdate;
exit;
