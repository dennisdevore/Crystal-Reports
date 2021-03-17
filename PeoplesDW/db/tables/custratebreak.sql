--
-- $Id
--
drop table custratebreak;
create table custratebreak(
    custid      varchar2(10) not null,
    rategroup   varchar2(10) not null,
    effdate     date not null,
    activity    varchar2(4) not null,
    billmethod  varchar2(4) not null,
    quantity    number(12,2) not null,
    rate        number(12,6),
    lastuser    varchar2(12),
    lastupdate  date
);

create unique index custratebreak_idx on 
    custratebreak(custid, rategroup, effdate,activity, billmethod,quantity);

-- exit;
