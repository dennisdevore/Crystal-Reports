--
-- $Id$
--
drop table load_flag_dtl_wk;
create table load_flag_dtl_wk(
    lpid    varchar2(15),
    orderid number(9),
    shipid  number(2),
    item    varchar2(20),
    pieces  number(10),
    quantity number(5),
    weight  number(16,4)
);

create unique index load_flag_dtl_wk_lpid_idx 
        on load_flag_dtl_wk(lpid, orderid, shipid, item, pieces);

drop public synonym load_flag_dtl_wk;

create public synonym load_flag_dtl_wk for pecas.load_flag_dtl_wk;


exit;
