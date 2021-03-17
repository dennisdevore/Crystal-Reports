--
-- $Id$
--
-- Query For Running Cursors By User

select  nvl(USERNAME,'ORACLE PROC')||'('||s.SID||')' "User ID",
        SQL_TEXT "SQL Text"
from    v$open_cursor oc, v$session s
where   s.SQL_ADDRESS = oc.ADDRESS
and     s.SQL_HASH_VALUE = oc.HASH_VALUE
order   by 1;
