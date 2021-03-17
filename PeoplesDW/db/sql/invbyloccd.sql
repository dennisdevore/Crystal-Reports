--
-- $Id$
--
set heading off feedback off verify off pagesize 0
spool invbyloccd.txt;
select item || ',' || location || ',' || sum(quantity)
  from plate
 where type = 'PA'
   and facility = 'HPL'
	and inventoryclass = 'RG'
group by item,location,invstatus
order by item,location,invstatus;
spool off; 
exit;
