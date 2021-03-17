--
-- $Id$
--
create table splitshipmentdtl (
    orderid     number(7) not null,
    shipid      number(2) not null,
    item varchar2(50) not null,
    lotnumber   varchar2(30),
    uom         varchar2(4),
    qtyorder    number(10),
    qtytosplit  number(10)
);

create unique index splitshipmentdtl_ix on splitshipmentdtl(
    orderid, shipid, item, lotnumber);

exit;
