--
-- $Id$
--
break on report;
compute sum of lipcount quantity on report;

--spool lip.txt;
select item,
	 	 invstatus,
		 inventoryclass,
		 count(1) as lipcount,
		 sum(quantity) as quantity
  from plate
 where type = 'PA'
   and facility = 'HPL'
group by item,invstatus,inventoryclass
order by item,invstatus,inventoryclass;
--spool off;
exit;
