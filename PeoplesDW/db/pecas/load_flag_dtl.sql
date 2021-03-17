--
-- $Id$
--
drop table load_flag_dtl;
create table load_flag_dtl(
    lpid    varchar2(15),
    orderid number(9),
    shipid  number(2),
    item    varchar2(20),
    pieces  number(10),
    quantity number(5),
    weight  number(16,4)
);

create unique index load_flag_dtl_lpid_idx 
        on load_flag_dtl(lpid, orderid, shipid, item, pieces);

drop public synonym load_flag_dtl;

create public synonym load_flag_dtl for pecas.load_flag_dtl;

grant insert,update,delete on pecas.load_flag_dtl to alps;
grant select on pecas.load_flag_dtl to alps with grant option;

exit;
