select s.sid, s.serial#, s.status, p.spid, p.program
from v$session s, v$process p
where s.username = 'ALPS'
and p.addr (+) = s.paddr
and type = 'USER';

-- alter system kill session 'sid,<serial#>' immediate;

exit;
