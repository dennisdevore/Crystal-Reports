--
-- $Id$
--
set heading off feedback off verify off pagesize 0
spool invbyitemcd.txt;
select item || ',' || sum(quantity)
  from plate
 where type = 'PA'
   and facility = 'HPL'
	and inventoryclass = 'RG'
group by item
order by item;
spool off; 
exit;
