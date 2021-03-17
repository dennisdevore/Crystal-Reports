--
-- $Id
--
create table custratecarrierdiscount(
    custid      varchar2(10) not null,
    rategroup   varchar2(10) not null,
    effdate     date not null,
    activity    varchar2(4) not null,
    billmethod  varchar2(4) not null,
	carrier     varchar2(4) not null,
    discount    number(12,6),
    lastuser    varchar2(12),
    lastupdate  date
);

create unique index custratecarrierdiscount_idx on 
    custratecarrierdiscount(custid, rategroup, effdate,activity,billmethod,carrier);

exit;

