--
-- $Id$
--
drop  table XchngExRcpt;

create table XchngExRcpt(
    transmission    number(9)   not null,
    status          char(1),
    customer        varchar2(8),
    plant           number(4),
    jobno           varchar2(10),
    item            varchar2(20),
    expected_qty    number(8),
    descr           varchar2(40),
    pcs_per_carton  number(8),
    ctn_per_pallet  number(6),
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index XchngExRcpt_tran_idx 
    on XchngExRcpt(transmission);

create index XchngExRcpt_proc_idx 
    on XchngExRcpt(processed,create_date, transmission);

exit;
