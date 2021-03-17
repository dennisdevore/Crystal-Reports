--
-- $Id: locinvstatuschange.sql 50 2005-07-29 12:53:44Z ed $
--

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

exit;
