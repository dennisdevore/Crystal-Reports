break on report;
compute sum of count(1) on report;
set heading off;
set pagesize 0;
select constraint_type,status,count(1)
from user_constraints
group by constraint_type,status
order by constraint_type,status;
exit;

