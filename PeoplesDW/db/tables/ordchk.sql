--
-- $Id$
--
create table ordchk (
    over_under   varchar2(1),
    fac          varchar2(3),
    loc          varchar2(10),
    orderid      number(7),
    lpid         varchar2(15),
    item varchar2(50),
    qty          number(7),
    uom          varchar2(4),
    shipid       number(2)
);

exit;
