set linesize 200
set pagesize 50
col a format a50 heading "Segment"
col b format a10 heading "Segment|Type"
col c format 999,999,999,999 heading "Storage|Usage"
spool disk_space_by_table.out
break on report
compute avg count sum of c on report
select segment_name a, segment_type b, bytes c
from user_segments
where bytes > 10000000
order by bytes desc
/
spool off
