--
-- $Id$
--
drop table print_set_dtl;
create table print_set_dtl(
    printno     number(9),
    lpid        varchar2(15)
);

create unique index print_set_dtl_idx on print_set_dtl(printno, lpid);

drop public synonym print_set_dtl;

create public synonym print_set_dtl for pecas.print_set_dtl;

grant select,insert,update on pecas.print_set_dtl to alps with grant option;

exit;
