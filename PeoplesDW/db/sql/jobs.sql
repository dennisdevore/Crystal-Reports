set heading off
select
what,
job,
to_char(last_date, 'mm/dd/yyyy hh24:mi:ss') last_date,
to_char(next_date, 'mm/dd/yyyy hh24:mi:ss') next_date,
broken
from user_jobs
order by what;
exit;
