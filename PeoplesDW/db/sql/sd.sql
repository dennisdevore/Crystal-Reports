set heading off;
spool sd.out
select
defaultid,
defaultvalue
from systemdefaults
order by defaultid;
exit;
