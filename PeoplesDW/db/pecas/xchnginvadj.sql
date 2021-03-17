--
-- $Id$
--
drop  table XchngInvAdj;

create table XchngInvAdj(
    transmission    number(9)   not null,
    plant           number(4),
    customer        varchar2(8),
    jobno           varchar2(10),
    item            varchar2(20),
    qty_changed     number(8),
    adj_date        date,
    reason          varchar2(2),
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index XchngInvAdj_tran_idx 
    on XchngInvAdj(transmission);

exit;
