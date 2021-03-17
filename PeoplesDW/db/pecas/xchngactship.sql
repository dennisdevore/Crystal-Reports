--
-- $Id$
--
drop  table XchngActShip;

create table XchngActShip(
    transmission    number(9)   not null,
    plant           number(4),
    pecas_ref       varchar2(30),
    customer        varchar2(8),
    item            varchar2(20),
    qty_shipped     number(8),
    ship_date       date,
    bol             varchar2(40),
    weight          number(12,3),
    ship_type       char(1),
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index XchngActShip_tran_idx 
    on XchngActShip(transmission);

exit;
