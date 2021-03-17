--
-- $Id$
--
drop  table XchngExShipHdr;

create table XchngExShipHdr(
    transmission    number(9)   not null,
    id              varchar2(3),
    status          char(1),
    customer        varchar2(8),
    plant           number(4),
    sales_order_no  varchar2(10),
    pecas_ref       varchar2(30),
    po              varchar2(20),
    shiptoname      varchar2(40),
    shiptocontact   varchar2(40),
    shiptoaddr1     varchar2(40),
    shiptoaddr2     varchar2(40),
    shiptocity      varchar2(30),
    shiptostate     varchar2(2),
    shiptopostalcode varchar2(12),
    shiptocountrycode varchar2(3),
    ship_date       date,
    delivery_date   date,
    ship_terms      varchar2(3),
    ship_type       char(1),
    carrier         varchar2(10),
    passthru06      varchar2(60),
    passthru07      varchar2(60),
    passthru08      varchar2(60),
    passthru09      varchar2(60),
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index Xchng_ExShip_Hdr_tran_idx 
    on XchngExShipHdr(transmission);

create index Xchng_ExShip_Hdr_proc_idx 
    on XchngExShipHdr(processed, create_date, transmission);

drop  table XchngExShipNotes;

create table XchngExShipNotes(
    transmission    number(9)   not null,
    id              varchar2(3),
    qualifier       varchar2(3),
    note            varchar2(80),
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index Xchng_ExShip_Notes_tran_idx 
    on XchngExShipNotes(transmission);


drop  table XchngExShipDetail;

create table XchngExShipDetail(
    transmission    number(9)   not null,
    id              varchar2(3),
    item            varchar2(20),
    qty             number(8),
    customer_item   varchar2(20),
    create_date     date        not null,
    processed       char(1)     not null,
    processed_date  date
);

create index Xchng_ExShip_Detail_tran_idx 
    on xchngExShipDetail(transmission);



exit;
