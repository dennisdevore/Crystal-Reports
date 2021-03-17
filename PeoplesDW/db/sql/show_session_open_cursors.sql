--
-- $Id$
--
select  user_process username,
 "Recursive Calls",
 "Opened Cursors",
 "Current Cursors"
from  (
 select  nvl(ss.USERNAME,'ORACLE PROC')||'('||se.sid||') ' user_process,
   sum(decode(NAME,'recursive calls',value)) "Recursive Calls",
   sum(decode(NAME,'opened cursors cumulative',value)) "Opened Cursors",
   sum(decode(NAME,'opened cursors current',value)) "Current Cursors"
 from  v$session ss,
  v$sesstat se,
  v$statname sn
 where  se.STATISTIC# = sn.STATISTIC#
 and  (NAME  like '%opened cursors current%'
 or   NAME  like '%recursive calls%'
 or   NAME  like '%opened cursors cumulative%')
 and  se.SID = ss.SID
 and  ss.USERNAME is not null
 group  by nvl(ss.USERNAME,'ORACLE PROC')||'('||se.SID||') '
)
orasnap_user_cursors
order  by USER_PROCESS,"Recursive Calls";