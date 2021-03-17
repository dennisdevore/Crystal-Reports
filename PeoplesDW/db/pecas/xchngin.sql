--
-- $Id$
--
drop  table XchngIn;

create table XchngIn(
    type            varchar2(2) not null,
    transmission    number(9)   not null,
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create unique index XchngIn_tran_idx 
    on XchngIn(transmission, type);

create index XchngIn_proc_idx 
    on XchngIn(processed, create_date, transmission);

exit;
