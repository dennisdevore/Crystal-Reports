--
-- $Id$
--
break on report;
compute sum of lipcount quantity on report;

select nvl(pickingzone,'???') as pickingzone,
		 nvl(loctype, '???') as loctype,
       location,
       count(1) as lipcount,
       sum(quantity) as quantity
  from location l, plate p
 where p.type = 'PA'
   and p.facility = 'HPL'
   and p.custid = 'HP'
   and p.facility = l.facility
   and p.location = l.locid
group by pickingzone, loctype, location
order by pickingzone, loctype, location;
exit;
