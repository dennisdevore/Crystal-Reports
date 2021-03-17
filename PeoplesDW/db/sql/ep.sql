--
-- $Id$
--
truncate table plan_table;
EXPLAIN PLAN
    SET STATEMENT_ID = 'Open Wave Select'
    INTO plan_table
    FOR
select wave,qtycommit
from openwavesview
where facility = 'HPL';

SELECT LPAD(' ',2*(LEVEL-1))||operation operation, options,
object_name, position
    FROM plan_table
    START WITH id = 0 AND statement_id = 'Open Wave Select'
    CONNECT BY PRIOR id = parent_id AND
    statement_id = 'Open Wave Select';
--exit;
