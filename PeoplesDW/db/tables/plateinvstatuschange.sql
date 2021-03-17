--
-- $Id$
--
drop table plateinvstatuschange;

create global temporary table plateinvstatuschange(
    lpid        varchar2(15),
    newstatus   varchar2(2),
    adjreason   varchar2(2),
    tasktype    varchar2(2),
    lastuser    varchar2(12)
)
on commit delete rows;

exit;
