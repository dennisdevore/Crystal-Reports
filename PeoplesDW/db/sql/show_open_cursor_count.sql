--
-- $Id$
--
col username format a20
select  user_process username,
 "Opened Cursors",
 "Current Cursors"
from  (
 select  nvl(ss.USERNAME,'ORACLE PROC')||'('||se.sid||','||ss.serial#||') ' user_process,
   sum(decode(NAME,'opened cursors cumulative',value)) "Opened Cursors",
   sum(decode(NAME,'opened cursors current',value)) "Current Cursors"
 from  v$session ss,
  v$sesstat se,
  v$statname sn
 where  se.STATISTIC# = sn.STATISTIC#
 and  (NAME  like '%opened cursors current%'
  or   NAME  like '%opened cursors cumulative%')
 and  se.SID = ss.SID
 and  ss.USERNAME is not null
 group  by nvl(ss.USERNAME,'ORACLE PROC')||'('||se.sid||','||ss.serial#||') '
)
orasnap_user_cursors
order  by USER_PROCESS;