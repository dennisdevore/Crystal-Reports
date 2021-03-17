--
-- $Id$
--
drop table print_set_hdr;
create table print_set_hdr(
    printno     number(9),
    descr       varchar2(30),
    custid      varchar2(10),
    jobno       varchar2(10),
    item        varchar2(20),
    carrier     varchar2(4),
    printtype   varchar2(15),
    shiptype    varchar2(15),
    status      varchar2(10),   -- NEW, PRINTED
    created     date
);

create unique index print_set_hdr_idx on print_set_hdr(printno);

drop public synonym print_set_hdr;

create public synonym print_set_hdr for pecas.print_set_hdr;

grant select,insert,update on pecas.print_set_hdr to alps;

exit;
