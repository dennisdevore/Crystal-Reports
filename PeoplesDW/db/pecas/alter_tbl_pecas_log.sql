--
-- $Id$
--
drop table pecas_log;
create table pecas_log
(
    created date,
    seq     number,
    source  varchar2(10),
    message varchar2(250)
);

create index pecas_log_order_idx on pecas_log(created, seq);

exit;
