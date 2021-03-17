--
-- $Id$
--
drop table bill_lot_renewal;

create table Bill_lot_renewal (
    facility    varchar2(3)     not null,
    custid      varchar2(10)    not null,
    item varchar2(50)    not null,
    lotnumber   varchar2(30),
    receiptdate date            not null,
    quantity    number(12,2),
    uom         varchar2(4),
    weight      number(13,4),
    renewalrate number(12,6),
    lastuser    varchar2(12),
    lastupdate  date);

create unique index bill_lot_renewal_idx 
    on bill_lot_renewal(facility, custid, item, lotnumber);

