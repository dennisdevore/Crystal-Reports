--
-- $Id$
--
drop  table XchngOut;

create table XchngOut(
    type            varchar2(2) not null,
    transmission    number(9)   not null,
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create unique index XchngOut_tran_idx 
    on XchngOut(transmission, type);

create index XchngOut_proc_idx 
    on XchngOut(processed, create_date, transmission);


exit;
