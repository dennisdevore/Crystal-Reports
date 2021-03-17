--
-- $Id$
--
-- Query For Open Cursors By User

select  nvl(USERNAME,'ORACLE PROC')||'('||s.SID||')' "User ID",
        SQL_TEXT "SQL Text"
from    v$open_cursor oc,
        v$session s
where   s.SADDR = oc.SADDR
order   by 1;
