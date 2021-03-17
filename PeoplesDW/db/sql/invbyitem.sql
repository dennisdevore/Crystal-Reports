--
-- $Id$
--
set heading off feedback off verify off pagesize 0
break on report;
compute sum of lipcount quantity on report;

spool invbyitem3.txt;
select item,
		 invstatus,
		 count(1) as lipcount,
		 sum(quantity) as quantity
  from plate
 where type = 'PA'
   and facility = 'HPL'
	and inventoryclass = 'RG'
group by item,invstatus
order by item,invstatus;
spool off; 
exit;
