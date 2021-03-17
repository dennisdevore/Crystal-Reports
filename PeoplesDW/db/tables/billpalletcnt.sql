--
-- $Id$
--
drop table billpalletcnt;

create table billpalletcnt
(
    facility       varchar2(3)  not null,
    custid         varchar2(10) not null,
    effdate        date         not null,
    item varchar2(50) not null,
    uom            varchar2(4)  not null,
    lotnumber      varchar2(30),
    pltqty         number(20),
    uomqty         number(10),
    lastuser       varchar2(12),
    lastupdate     date
);

exit;
