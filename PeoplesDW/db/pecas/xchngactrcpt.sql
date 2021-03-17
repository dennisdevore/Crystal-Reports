--
-- $Id$
--
drop  table XchngActRcpt;

create table XchngActRcpt(
    transmission    number(9)   not null,
    customer        varchar2(8),
    plant           number(4),
    jobno           varchar2(10),
    item            varchar2(20),
    qty_received    number(8),
    receipt_date    date,
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index XchngActRcpt_tran_idx 
    on XchngActRcpt(transmission);

exit;
