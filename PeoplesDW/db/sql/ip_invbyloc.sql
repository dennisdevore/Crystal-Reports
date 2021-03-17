--
-- $Id$
--
set heading off feedback off verify off pagesize 0
break on report;
compute sum of lipcount quantity on report;

spool ip_invbyloc1.txt;
select item,
		 location,
		 invstatus,
		 count(1) as lipcount,
		 sum(quantity) as quantity
  from plate
 where type = 'PA'
   and facility = 'HPL'
	and inventoryclass = 'IP'
group by item,location,invstatus
order by item,location,invstatus;
spool off; 
exit;
