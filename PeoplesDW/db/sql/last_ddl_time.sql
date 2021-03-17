set heading off
select
object_name,
to_char(last_ddl_time, 'yyyy/mm/dd hh24:mi:ss') last_ddl_time
from user_objects
order by last_ddl_time desc;
exit;
