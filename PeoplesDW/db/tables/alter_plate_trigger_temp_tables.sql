drop table plateinvstatuschange;

create global temporary table plateinvstatuschange(
    lpid        varchar2(15),
    newstatus   varchar2(2),
    adjreason   varchar2(2),
    tasktype    varchar2(2),
    lastuser    varchar2(12)
)
on commit delete rows;

drop table dynamicpf_temp;

create global temporary table dynamicpf_temp
(
   facility    varchar2(3),
   custid      varchar2(10),
   item 	   varchar2(50),
   locid       varchar2(20)
)
on commit delete rows;

drop table locinvstatuschange;

create global temporary table locinvstatuschange(
    lpid          varchar2(15),
    custid        varchar2(10),
    item 		  varchar2(50),
    lotnumber     varchar2(30),
    baseuom       varchar2(4),
    qty           number(7),
    weight        number(17,8),
    facility      varchar2(3),
    invstatus     varchar2(2),
    adjreason     varchar2(2),
    tasktype      varchar2(2),
    businessevent varchar2(4),
    lastuser      varchar2(12)
)
on commit delete rows;

drop trigger plate_bu_all;

exit;
