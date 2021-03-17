--
-- $Id$
--
drop table load_flag_ctn;
create table load_flag_ctn(
    lpid    varchar2(15),
    orderid number(9),
    shipid  number(2),
    item    varchar2(20),
    pieces  number(10),
    cartonid varchar2(15),
    weight  number(16,4)
);

create unique index load_flag_ctn_lpid_idx 
        on load_flag_ctn(lpid, orderid, shipid, item, pieces, cartonid);

create unique index load_flag_ctn_ctnid_idx 
        on load_flag_ctn(cartonid);

drop public synonym load_flag_ctn;

create public synonym load_flag_ctn for pecas.load_flag_ctn;

grant select, insert,update on pecas.load_flag_ctn to alps;

exit;
