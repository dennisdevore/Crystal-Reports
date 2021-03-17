--
-- $Id$
--
select to_char(created,'YYYYMMDDHH24MISS') Created, source, 
substr(message,1,40) Message
from pecas_log
where created >= sysdate - 10/(24*60)
order by seq;
